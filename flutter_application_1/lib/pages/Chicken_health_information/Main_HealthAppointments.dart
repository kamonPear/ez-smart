import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../services/backend_config.dart';
import '../../widgets/ez_header.dart';
import 'Main_HealthCheckCalendar.dart';
import '../bottombar.dart';
import '../main_dash.dart';
import '../Data_AdoptChicken/Main_DataChicken_2.dart';
import '../Data_Food/Main_DataFood_ShowDataFood1.dart';
import '../Main_SenSor/Main_DeviceSummary.dart';
import '../Show_chart.dart';

/// หน้า "นัดตรวจสุขภาพ" รวมทั้งฟาร์ม - คำนวณอัตโนมัติว่าคอกไหนควรตรวจสุขภาพวันไหน
/// โดยใช้กฎ: ตรวจสุขภาพก่อนให้วัคซีน 1 วันเสมอ (เพราะจะฉีดวัคซีนแค่ไก่ที่แข็งแรง)
/// จึงคำนวณจากวันครบกำหนดวัคซีนของแต่ละคอก (ที่ยังไม่ให้) ลบ 1 วัน
class MainHealthAppointments extends StatefulWidget {
  const MainHealthAppointments({super.key});

  @override
  State<MainHealthAppointments> createState() => _MainHealthAppointmentsState();
}

class _Appointment {
  final String coopId;
  final String coopName;
  final DateTime appointmentDate;
  final String vaccineName;
  final DateTime vaccineDate;

  _Appointment({
    required this.coopId,
    required this.coopName,
    required this.appointmentDate,
    required this.vaccineName,
    required this.vaccineDate,
  });

  int daysUntil(DateTime todayOnly) =>
      appointmentDate.difference(todayOnly).inDays;
}

/// วัคซีนที่ให้ไปแล้วแต่ไม่พบประวัติตรวจสุขภาพในวันที่ควรตรวจ (1 วันก่อนให้วัคซีน)
/// หรือวันเดียวกับที่ให้วัคซีนเลยก็ได้ (ไม่เคร่งเกินไป เผื่อตรวจเช้าให้บ่ายวันเดียวกัน)
class _MissedCheck {
  final String coopId;
  final String coopName;
  final String vaccineName;
  final DateTime expectedCheckDate;

  _MissedCheck({
    required this.coopId,
    required this.coopName,
    required this.vaccineName,
    required this.expectedCheckDate,
  });
}

class _MainHealthAppointmentsState extends State<MainHealthAppointments> {
  int? selectedIndex; // ไม่ใช่หน้าในแถบเมนูล่าง จึงไม่ไฮไลต์เมนูไหน
  bool _isLoading = true;
  List<_Appointment> _appointments = [];

  // ประวัติที่ "ขาดการตรวจ" - กดปุ่มเปิดดูได้ (โหลดครั้งแรกตอนกดเปิดเท่านั้น ไม่ต้อง
  // ยิง API เพิ่มถ้าไม่มีใครสนใจดู)
  bool _showMissedChecks = false;
  bool _isLoadingMissed = false;
  bool _missedChecksLoaded = false;
  List<_MissedCheck> _missedChecks = [];

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiClient.get(Uri.parse('$backendBaseUrl/api/coops')),
        ApiClient.get(Uri.parse('$backendBaseUrl/api/vaccines/alerts')),
      ]);

      final Map<String, String> coopNames = {};
      if (results[0].statusCode == 200) {
        final List<dynamic> coops = json.decode(results[0].body);
        for (final c in coops) {
          final id = (c['coop_id'] ?? c['id']).toString();
          final name = (c['name_coop']?.toString().trim().isNotEmpty == true)
              ? c['name_coop'].toString()
              : id;
          coopNames[id] = name;
        }
      }

      // กลุ่มตาม (coopId, วันนัดตรวจ) ก่อนสร้าง _Appointment - ถ้าวัคซีนหลายชนิด
      // ของคอกเดียวกันครบกำหนดวันเดียวกันพอดี (เลยต้องตรวจสุขภาพวันเดียวกันด้วย)
      // จะได้รวมเป็นนัดเดียว ไม่ใช่ขึ้นซ้ำทีละชนิด เพราะตรวจครั้งเดียวเอาผลไปใช้กับ
      // วัคซีนทุกชนิดที่ตรงวันนั้นได้เลย ไม่ต้องตรวจแยกกัน
      final Map<String, List<String>> groupedVaccineNames = {};
      final Map<String, _Appointment> groupedMeta = {};

      if (results[1].statusCode == 200) {
        final List<dynamic> alerts = json.decode(results[1].body);
        for (final a in alerts) {
          if (a['is_completed'] == true) continue;
          if (a['date'] == null) continue;
          try {
            final vaccineDate = DateTime.parse(a['date']).toLocal();
            final vaccineDateOnly = DateTime(
              vaccineDate.year,
              vaccineDate.month,
              vaccineDate.day,
            );
            final appointmentDate = vaccineDateOnly.subtract(
              const Duration(days: 1),
            );
            final coopId = a['coop_id']?.toString() ?? '-';
            final groupKey =
                '${coopId}_${appointmentDate.year}-${appointmentDate.month}-${appointmentDate.day}';
            groupedVaccineNames
                .putIfAbsent(groupKey, () => [])
                .add(a['vaccine_name']?.toString() ?? 'วัคซีน');
            groupedMeta.putIfAbsent(
              groupKey,
              () => _Appointment(
                coopId: coopId,
                coopName: coopNames[coopId] ?? 'คอก $coopId',
                appointmentDate: appointmentDate,
                vaccineName: '',
                vaccineDate: vaccineDateOnly,
              ),
            );
          } catch (e) {
            debugPrint('Error computing appointment date: $e');
          }
        }
      }

      final appointments = groupedMeta.entries.map((entry) {
        final meta = entry.value;
        final names = groupedVaccineNames[entry.key] ?? const <String>[];
        return _Appointment(
          coopId: meta.coopId,
          coopName: meta.coopName,
          appointmentDate: meta.appointmentDate,
          vaccineName: names.join('และ'),
          vaccineDate: meta.vaccineDate,
        );
      }).toList();

      appointments.sort(
        (x, y) => x.appointmentDate.compareTo(y.appointmentDate),
      );

      if (!mounted) return;
      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ โหลดข้อมูลนัดตรวจไม่สำเร็จ: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // หาวัคซีนที่ให้ไปแล้ว (ประวัติจริง) แต่ไม่พบประวัติตรวจสุขภาพในวันที่ควรตรวจ
  // (1 วันก่อนให้วัคซีน) หรือวันเดียวกับที่ให้วัคซีนเลยก็ได้ - ตอบคำถาม "คอกไหน
  // ขาดการตรวจบ้าง" ย้อนหลัง เพราะพอให้วัคซีนไปแล้ว นัดตรวจของวัคซีนตัวนั้นจะหาย
  // ไปจาก _fetchAppointments ทันที (กรอง is_completed ออก) โดยไม่บอกว่าจริงๆ
  // แล้วมีการตรวจสุขภาพก่อนให้หรือเปล่า
  Future<void> _fetchMissedChecks() async {
    setState(() => _isLoadingMissed = true);
    try {
      final results = await Future.wait([
        ApiClient.get(Uri.parse('$backendBaseUrl/api/coops')),
        ApiClient.get(Uri.parse('$backendBaseUrl/api/vaccines')),
        ApiClient.get(Uri.parse('$backendBaseUrl/api/healths')),
      ]);

      final Map<String, String> coopNames = {};
      if (results[0].statusCode == 200) {
        final List<dynamic> coops = json.decode(results[0].body);
        for (final c in coops) {
          final id = (c['coop_id'] ?? c['id']).toString();
          final name = (c['name_coop']?.toString().trim().isNotEmpty == true)
              ? c['name_coop'].toString()
              : id;
          coopNames[id] = name;
        }
      }

      String dayKey(String coopId, DateTime d) =>
          '${coopId}_${d.year}-${d.month}-${d.day}';

      final Set<String> checkedDays = {};
      if (results[2].statusCode == 200) {
        final List<dynamic> healths = json.decode(results[2].body);
        for (final h in healths) {
          final coopId = h['coop_id']?.toString();
          final d = DateTime.tryParse(
            h['record_date']?.toString() ?? '',
          )?.toLocal();
          if (coopId == null || d == null) continue;
          checkedDays.add(dayKey(coopId, d));
        }
      }

      final List<_MissedCheck> missed = [];
      if (results[1].statusCode == 200) {
        final List<dynamic> history = json.decode(results[1].body);
        for (final v in history) {
          final coopId = v['coop_id']?.toString();
          final recordDate = DateTime.tryParse(
            v['record_date']?.toString() ?? '',
          )?.toLocal();
          if (coopId == null || recordDate == null) continue;
          final recordDay = DateTime(
            recordDate.year,
            recordDate.month,
            recordDate.day,
          );
          final expected = recordDay.subtract(const Duration(days: 1));
          if (checkedDays.contains(dayKey(coopId, expected)) ||
              checkedDays.contains(dayKey(coopId, recordDay))) {
            continue;
          }
          missed.add(
            _MissedCheck(
              coopId: coopId,
              coopName: coopNames[coopId] ?? 'คอก $coopId',
              vaccineName: v['name']?.toString() ?? 'วัคซีน',
              expectedCheckDate: expected,
            ),
          );
        }
      }

      missed.sort((a, b) => b.expectedCheckDate.compareTo(a.expectedCheckDate));

      if (!mounted) return;
      setState(() {
        _missedChecks = missed;
        _isLoadingMissed = false;
        _missedChecksLoaded = true;
      });
    } catch (e) {
      debugPrint('❌ โหลดประวัติที่ยังไม่ตรวจไม่สำเร็จ: $e');
      if (mounted) setState(() => _isLoadingMissed = false);
    }
  }

  void _toggleMissedChecks() {
    setState(() => _showMissedChecks = !_showMissedChecks);
    if (_showMissedChecks && !_missedChecksLoaded) {
      _fetchMissedChecks();
    }
  }

  Widget _buildMissedCheckRow(_MissedCheck m) {
    final ez = ezColors(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MainHealthCheckCalendar(coopId: m.coopId, coopName: m.coopName),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: ezCardDecoration(context, radius: 14),
        child: Row(
          children: [
            Icon(Icons.event_busy_rounded, color: ez.danger, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'คอก${m.coopName} – ขาดตรวจก่อนให้${m.vaccineName}',
                    style: GoogleFonts.kanit(
                      color: ez.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'ควรตรวจวันที่ ${m.expectedCheckDate.day}/${m.expectedCheckDate.month}/${m.expectedCheckDate.year}',
                    style: GoogleFonts.kanit(
                      color: ez.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: ez.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(_Appointment a) {
    final ez = ezColors(context);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final daysUntil = a.daysUntil(todayOnly);

    late final Color statusColor;
    late final String statusLabel;
    late final IconData statusIcon;
    if (daysUntil < 0) {
      statusColor = ez.danger;
      statusLabel = 'เลยกำหนดมา ${-daysUntil} วัน';
      statusIcon = Icons.warning_amber_rounded;
    } else if (daysUntil == 0) {
      statusColor = ez.danger;
      statusLabel = 'นัดวันนี้';
      statusIcon = Icons.today_rounded;
    } else if (daysUntil == 1) {
      statusColor = const Color(0xFFFFA726);
      statusLabel = 'นัดพรุ่งนี้';
      statusIcon = Icons.schedule_rounded;
    } else {
      statusColor = ez.accentGreen;
      statusLabel = 'อีก $daysUntil วัน';
      statusIcon = Icons.schedule_rounded;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MainHealthCheckCalendar(coopId: a.coopId, coopName: a.coopName),
          ),
        );
        _fetchAppointments();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: ezCardDecoration(context, radius: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(statusIcon, color: statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'นัดตรวจ – คอก${a.coopName}',
                    style: GoogleFonts.kanit(
                      color: ez.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'วันที่ ${a.appointmentDate.day}/${a.appointmentDate.month}/${a.appointmentDate.year}',
                    style: GoogleFonts.kanit(
                      color: ez.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'เตรียมให้${a.vaccineName} วันที่ ${a.vaccineDate.day}/${a.vaccineDate.month}/${a.vaccineDate.year}',
                    style: GoogleFonts.kanit(
                      color: ez.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: GoogleFonts.kanit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: ez.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  void onTabSelected(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainDeviceSummary()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ShowChart()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Mainchicken()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainShowDataFood()),
      );
    } else {
      setState(() {
        selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ez = ezColors(context);
    return Scaffold(
      extendBody: true,
      backgroundColor: ezBackgroundColor(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: EzHeader(pageTitle: 'นัดตรวจสุขภาพ'),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'นัดคำนวณอัตโนมัติจากวันครบกำหนดให้วัคซีนของแต่ละคอก '
                      '(ตรวจก่อนให้วัคซีน 1 วันเสมอ เพื่อคัดเฉพาะไก่แข็งแรง)',
                      style: GoogleFonts.kanit(
                        color: ez.textSecondary,
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _toggleMissedChecks,
                      icon: Icon(
                        _showMissedChecks
                            ? Icons.expand_less_rounded
                            : Icons.history_toggle_off_rounded,
                        size: 18,
                        color: ez.danger,
                      ),
                      label: Text(
                        _showMissedChecks
                            ? 'ซ่อนประวัติที่ยังไม่ตรวจ'
                            : 'ดูประวัติที่ยังไม่ตรวจ',
                        style: GoogleFonts.kanit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ez.danger,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: ez.danger.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    if (_showMissedChecks) ...[
                      const SizedBox(height: 12),
                      if (_isLoadingMissed)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_missedChecks.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'ไม่พบคอกที่ขาดการตรวจสุขภาพ',
                            style: GoogleFonts.kanit(
                              color: ez.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        )
                      else
                        ..._missedChecks.map(_buildMissedCheckRow),
                    ],
                    const SizedBox(height: 16),
                    if (_isLoading)
                      Skeletonizer(
                        enabled: true,
                        child: Column(
                          children: List.generate(
                            3,
                            (_) => _buildAppointmentCard(
                              _Appointment(
                                coopId: '1',
                                coopName: 'ตัวอย่าง',
                                appointmentDate: DateTime.now(),
                                vaccineName: 'วัคซีนตัวอย่าง',
                                vaccineDate: DateTime.now(),
                              ),
                            ),
                          ),
                        ),
                      )
                    else if (_appointments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'ไม่มีนัดตรวจสุขภาพในตอนนี้',
                            style: GoogleFonts.kanit(
                              color: ez.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._appointments.map(_buildAppointmentCard),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected,
      ),
    );
  }
}
