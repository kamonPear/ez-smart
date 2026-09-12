import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../services/backend_config.dart';
import '../../widgets/ez_header.dart';
import 'Main_HealthCheckCalendar.dart';

/// หน้า "นัดตรวจสุขภาพ" รวมทั้งฟาร์ม - คำนวณอัตโนมัติว่าคอกไหนควรตรวจสุขภาพวันไหน
/// โดยใช้กฎ: ตรวจสุขภาพก่อนให้วัคซีน 1 วันเสมอ (เพราะจะฉีดวัคซีนแค่ไก่ที่แข็งแรง)
/// จึงคำนวณจากวันครบกำหนดวัคซีนของแต่ละคอก (ที่ยังไม่ให้) ลบ 1 วัน
class MainHealthAppointments extends StatefulWidget {
  const MainHealthAppointments({super.key});

  @override
  State<MainHealthAppointments> createState() =>
      _MainHealthAppointmentsState();
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

class _MainHealthAppointmentsState extends State<MainHealthAppointments> {
  bool _isLoading = true;
  List<_Appointment> _appointments = [];

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse('$backendBaseUrl/api/coops')),
        http.get(Uri.parse('$backendBaseUrl/api/vaccines/alerts')),
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

      final List<_Appointment> appointments = [];
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
            appointments.add(
              _Appointment(
                coopId: coopId,
                coopName: coopNames[coopId] ?? 'คอก $coopId',
                appointmentDate: appointmentDate,
                vaccineName: a['vaccine_name']?.toString() ?? 'วัคซีน',
                vaccineDate: vaccineDateOnly,
              ),
            );
          } catch (e) {
            debugPrint('Error computing appointment date: $e');
          }
        }
      }

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
            builder: (context) => MainHealthCheckCalendar(
              coopId: a.coopId,
              coopName: a.coopName,
            ),
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
            Icon(
              Icons.chevron_right,
              color: ez.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ez = ezColors(context);
    return Scaffold(
      backgroundColor: ezBackgroundColor(context),
      body: SafeArea(
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
                physics: const BouncingScrollPhysics(),
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
    );
  }
}
