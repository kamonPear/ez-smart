import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../../services/backend_config.dart';
import '../../widgets/ez_header.dart';
import '../../widgets/ez_top_banner.dart';
import '../calendar.dart';

/// ปฏิทินนัดตรวจสุขภาพของคอกนี้โดยเฉพาะ - นัดคำนวณอัตโนมัติจากวันครบกำหนดวัคซีน
/// (ตรวจก่อนให้วัคซีน 1 วันเสมอ) แตะวันที่มีนัดเพื่อบันทึกผลตรวจ:
/// - วันที่ยังไม่ถึง: กดไม่ได้ (แค่ดูว่ามีนัด)
/// - วันนี้/เลยกำหนดแล้ว: กดเพื่อกรอกผลตรวจได้ (สุขภาพดี/ป่วยกี่ตัว)
/// - วันที่ตรวจแล้ว: กดดูผลตรวจที่บันทึกไว้ (อ่านอย่างเดียว)
class MainHealthCheckCalendar extends StatefulWidget {
  final String coopId;
  final String coopName;

  const MainHealthCheckCalendar({
    super.key,
    required this.coopId,
    required this.coopName,
  });

  @override
  State<MainHealthCheckCalendar> createState() =>
      _MainHealthCheckCalendarState();
}

class _AppointmentInfo {
  final DateTime date;
  final String vaccineName;
  final DateTime vaccineDate;

  _AppointmentInfo({
    required this.date,
    required this.vaccineName,
    required this.vaccineDate,
  });
}

class _HealthRecordInfo {
  final int healthy;
  final int poor;
  final String note;

  _HealthRecordInfo({
    required this.healthy,
    required this.poor,
    required this.note,
  });
}

const Color kUpcomingAmber = Color(0xFFFFA726);

class _MainHealthCheckCalendarState extends State<MainHealthCheckCalendar> {
  bool _isLoading = true;
  DateTime _calendarKeyDate = DateTime.now();
  Map<DateTime, DayMarkerInfo> _dayMarkers = {};
  Map<DateTime, _AppointmentInfo> _appointments = {};
  Map<DateTime, _HealthRecordInfo> _records = {};
  // จำนวนไก่ทั้งหมดของคอกนี้ (จาก /api/coops) ใช้โชว์อ้างอิง + ตรวจสอบยอดตอนบันทึกผลตรวจ
  int? _totalChickens;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse('$backendBaseUrl/api/vaccines/alerts')),
        http.get(Uri.parse('$backendBaseUrl/api/healths')),
        http.get(Uri.parse('$backendBaseUrl/api/coops')),
      ]);

      int? totalChickens;
      if (results[2].statusCode == 200) {
        final List<dynamic> coops = json.decode(results[2].body);
        for (final c in coops) {
          if ((c['coop_id'] ?? c['id'])?.toString() == widget.coopId) {
            totalChickens = int.tryParse(c['amount']?.toString() ?? '');
            break;
          }
        }
      }

      final Map<DateTime, _AppointmentInfo> appointments = {};
      if (results[0].statusCode == 200) {
        final List<dynamic> alerts = json.decode(results[0].body);
        for (final a in alerts) {
          if (a['coop_id']?.toString() != widget.coopId) continue;
          if (a['date'] == null) continue;
          try {
            final vaccineDate = DateTime.parse(a['date']).toLocal();
            final vaccineDateOnly = DateTime(
              vaccineDate.year,
              vaccineDate.month,
              vaccineDate.day,
            );
            final apptDate = vaccineDateOnly.subtract(const Duration(days: 1));
            appointments[apptDate] = _AppointmentInfo(
              date: apptDate,
              vaccineName: a['vaccine_name']?.toString() ?? 'วัคซีน',
              vaccineDate: vaccineDateOnly,
            );
          } catch (e) {
            debugPrint('Error computing appointment date: $e');
          }
        }
      }

      final Map<DateTime, _HealthRecordInfo> records = {};
      if (results[1].statusCode == 200) {
        final List<dynamic> healths = json.decode(results[1].body);
        for (final h in healths) {
          if (h['coop_id']?.toString() != widget.coopId) continue;
          if (h['record_date'] == null) continue;
          try {
            final d = DateTime.parse(h['record_date']).toLocal();
            final dateOnly = DateTime(d.year, d.month, d.day);
            records[dateOnly] = _HealthRecordInfo(
              healthy: int.tryParse(h['healthy']?.toString() ?? '') ?? 0,
              poor: int.tryParse(h['poor_health']?.toString() ?? '') ?? 0,
              note: h['note']?.toString() ?? '',
            );
          } catch (e) {
            debugPrint('Error parsing health record date: $e');
          }
        }
      }

      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      final Map<DateTime, DayMarkerInfo> markers = {};
      final allDates = <DateTime>{...appointments.keys, ...records.keys};

      for (final date in allDates) {
        if (records.containsKey(date)) {
          final r = records[date]!;
          markers[date] = DayMarkerInfo(
            color: kCalendarGreen,
            details: [
              DayDetailItem(
                text: '🩺 ตรวจแล้ว: สุขภาพดี ${r.healthy} / ป่วย ${r.poor} ตัว',
              ),
            ],
          );
          continue;
        }
        final appt = appointments[date];
        if (appt == null) continue;
        final isFuture = date.isAfter(todayOnly);
        markers[date] = DayMarkerInfo(
          color: isFuture ? kUpcomingAmber : kCalendarRed,
          details: [
            DayDetailItem(
              text: isFuture
                  ? '🩺 นัดตรวจ (เตรียมให้${appt.vaccineName} วันที่ ${appt.vaccineDate.day}/${appt.vaccineDate.month})'
                  : '🩺 ถึงกำหนดตรวจแล้ว (เตรียมให้${appt.vaccineName} วันที่ ${appt.vaccineDate.day}/${appt.vaccineDate.month})',
              isPending: !isFuture,
            ),
          ],
        );
      }

      if (!mounted) return;
      setState(() {
        _appointments = appointments;
        _records = records;
        _dayMarkers = markers;
        _totalChickens = totalChickens;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ โหลดข้อมูลนัดตรวจสุขภาพไม่สำเร็จ: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitHealthRecord(
    DateTime date,
    int healthy,
    int poor,
    String note,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$backendBaseUrl/api/healths'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'coop_id': int.tryParse(widget.coopId) ?? 0,
          'record_date':
              '${date.toIso8601String().split('T').first}T00:00:00Z',
          'healthy': healthy,
          'poor_health': poor,
          'note': note,
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context);
        showEzTopBanner(context, 'บันทึกผลตรวจสุขภาพแล้ว', type: EzBannerType.success);
        _fetchData();
      } else {
        showEzTopBanner(
          context,
          'บันทึกไม่สำเร็จ กรุณาลองใหม่อีกครั้ง',
          type: EzBannerType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showEzTopBanner(context, 'เชื่อมต่อ backend ไม่สำเร็จ', type: EzBannerType.error);
    }
  }

  void _onDayTap(DateTime day) {
    if (!_dayMarkers.containsKey(day)) return; // ไม่มีนัด/ไม่มีบันทึก ไม่ต้องเปิดป็อบอัพ

    if (_records.containsKey(day)) {
      _showReadOnlyPopup(day, _records[day]!);
      return;
    }

    final appt = _appointments[day];
    if (appt == null) return;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    if (day.isAfter(todayOnly)) {
      _showNotYetDuePopup(day, appt);
    } else {
      _showRecordFormPopup(day, appt);
    }
  }

  void _showReadOnlyPopup(DateTime day, _HealthRecordInfo record) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final ez = ezColors(dialogContext);
        return Dialog(
          backgroundColor: ezCardColor(dialogContext),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kCalendarGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: kCalendarGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ตรวจแล้ว วันที่ ${day.day}/${day.month}/${day.year}',
                        style: GoogleFonts.kanit(
                          color: ez.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _statTile(
                        ez,
                        '😊 สุขภาพดี',
                        '${record.healthy}',
                        kCalendarGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statTile(
                        ez,
                        '☹️ ป่วย',
                        '${record.poor}',
                        kCalendarRed,
                      ),
                    ),
                  ],
                ),
                if (record.note.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'หมายเหตุ: ${record.note}',
                    style: GoogleFonts.kanit(
                      color: ez.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: ez.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      'ปิด',
                      style: GoogleFonts.kanit(
                        color: ez.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statTile(dynamic ez, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.kanit(color: ez.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '$value ตัว',
            style: GoogleFonts.kanit(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showNotYetDuePopup(DateTime day, _AppointmentInfo appt) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final ez = ezColors(dialogContext);
        return Dialog(
          backgroundColor: ezCardColor(dialogContext),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kUpcomingAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.schedule_rounded,
                        color: kUpcomingAmber,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'นัดตรวจ วันที่ ${day.day}/${day.month}/${day.year}',
                        style: GoogleFonts.kanit(
                          color: ez.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'ยังไม่ถึงวันนัด - เตรียมให้${appt.vaccineName}วันที่ '
                  '${appt.vaccineDate.day}/${appt.vaccineDate.month}/${appt.vaccineDate.year} '
                  '(ตรวจสุขภาพก่อน 1 วันเสมอ)',
                  style: GoogleFonts.kanit(
                    color: ez.textSecondary,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: ez.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      'ปิด',
                      style: GoogleFonts.kanit(
                        color: ez.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRecordFormPopup(DateTime day, _AppointmentInfo appt) {
    final healthyController = TextEditingController();
    final poorController = TextEditingController();
    final noteController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        final ez = ezColors(dialogContext);
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
              backgroundColor: ezCardColor(dialogContext),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: kCalendarRed.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.medical_information_outlined,
                              color: kCalendarRed,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'บันทึกผลตรวจ วันที่ ${day.day}/${day.month}/${day.year}',
                              style: GoogleFonts.kanit(
                                color: ez.textPrimary,
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'เตรียมให้${appt.vaccineName}วันที่ ${appt.vaccineDate.day}/${appt.vaccineDate.month}/${appt.vaccineDate.year}',
                        style: GoogleFonts.kanit(
                          color: ez.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                      if (_totalChickens != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: ez.gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 15,
                                color: ez.gold,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'คอกนี้มีไก่ทั้งหมด $_totalChickens ตัว (สุขภาพดี + ป่วย ต้องรวมได้เท่านี้)',
                                  style: GoogleFonts.kanit(
                                    color: ez.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      TextField(
                        controller: healthyController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.kanit(color: ez.textPrimary),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: ez.inputFill,
                          labelText: 'จำนวนไก่สุขภาพดี *',
                          labelStyle: GoogleFonts.kanit(color: ez.textSecondary),
                          suffixText: 'ตัว',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: poorController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.kanit(color: ez.textPrimary),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: ez.inputFill,
                          labelText: 'จำนวนไก่ป่วย *',
                          labelStyle: GoogleFonts.kanit(color: ez.textSecondary),
                          suffixText: 'ตัว',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: noteController,
                        style: GoogleFonts.kanit(color: ez.textPrimary),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: ez.inputFill,
                          labelText: 'หมายเหตุ (ถ้ามี)',
                          labelStyle: GoogleFonts.kanit(color: ez.textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                side: BorderSide(color: ez.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Text(
                                'ยกเลิก',
                                style: GoogleFonts.kanit(
                                  color: ez.textSecondary,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ez.accentGreen,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: isSaving
                                  ? null
                                  : () {
                                      final healthy = int.tryParse(
                                        healthyController.text.trim(),
                                      );
                                      final poor = int.tryParse(
                                        poorController.text.trim(),
                                      );
                                      if (healthy == null ||
                                          poor == null ||
                                          healthy < 0 ||
                                          poor < 0) {
                                        showEzTopBanner(
                                          dialogContext,
                                          'กรุณากรอกจำนวนไก่ให้ครบถ้วน',
                                          type: EzBannerType.warning,
                                        );
                                        return;
                                      }
                                      // ✅ กันกรอกจำนวนไก่ผิด: สุขภาพดี + ป่วย
                                      // ต้องรวมได้เท่ากับจำนวนไก่ทั้งหมดของคอกนี้
                                      if (_totalChickens != null &&
                                          healthy + poor !=
                                              _totalChickens) {
                                        showEzTopBanner(
                                          dialogContext,
                                          'จำนวนไก่ไม่ตรงกับที่มีจริง (คอกนี้มี $_totalChickens ตัว '
                                          'แต่กรอกรวม ${healthy + poor} ตัว) กรุณาตรวจสอบก่อนบันทึก',
                                          type: EzBannerType.error,
                                        );
                                        return;
                                      }
                                      setDialogState(() => isSaving = true);
                                      _submitHealthRecord(
                                        day,
                                        healthy,
                                        poor,
                                        noteController.text.trim(),
                                      );
                                    },
                              child: Text(
                                isSaving ? 'กำลังบันทึก...' : 'บันทึกผล',
                                style: GoogleFonts.kanit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _legendDot(Color color, String label) {
    final ez = ezColors(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.kanit(color: ez.textSecondary, fontSize: 11),
        ),
      ],
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
              child: EzHeader(pageTitle: 'นัดตรวจสุขภาพ - ${widget.coopName}'),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    if (_isLoading)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: CircularProgressIndicator(color: ez.gold),
                      )
                    else ...[
                      CustomCalendar(
                        key: ValueKey(_dayMarkers.length),
                        initialDate: _calendarKeyDate,
                        dayMarkers: _dayMarkers,
                        onDateSelected: (day) {
                          _calendarKeyDate = day;
                          _onDayTap(day);
                        },
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 14,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _legendDot(kCalendarGreen, 'ตรวจแล้ว'),
                          _legendDot(kUpcomingAmber, 'มีนัด (ยังไม่ถึง)'),
                          _legendDot(kCalendarRed, 'ถึงกำหนด/เลยกำหนด'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'แตะวันที่มีมาร์คสีเพื่อดู/บันทึกผลตรวจ',
                        style: GoogleFonts.kanit(
                          color: ez.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
