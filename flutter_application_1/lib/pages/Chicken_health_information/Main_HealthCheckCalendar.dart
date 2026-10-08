import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/backend_config.dart';
import '../../widgets/ez_header.dart';
import '../../widgets/ez_top_banner.dart';
import '../calendar.dart';
import '../bottombar.dart';
import '../main_dash.dart';
import '../Data_AdoptChicken/Main_DataChicken_2.dart';
import '../Data_Food/Main_DataFood_ShowDataFood1.dart';
import '../Main_SenSor/Main_DeviceSummary.dart';
import '../Show_chart.dart';

/// ปฏิทินนัดตรวจสุขภาพของคอกนี้โดยเฉพาะ - นัดคำนวณอัตโนมัติจากวันครบกำหนดวัคซีน
/// (ตรวจก่อนให้วัคซีน 1 วันเสมอ) แตะวันที่มีนัดเพื่อบันทึกผลตรวจ:
/// - วันที่ยังไม่ถึง: กดไม่ได้ (แค่ดูว่ามีนัด)
/// - วันนี้/เลยกำหนดแล้ว: กดเพื่อกรอกผลตรวจได้ (สุขภาพดี/ป่วยกี่ตัว)
/// - วันที่ตรวจแล้ว: กดดูผลตรวจที่บันทึกไว้ (อ่านอย่างเดียว)
///
/// เปิดหน้านี้ได้จาก 3 ที่ (ทุกที่ต้องส่ง coopId/coopName ของคอกที่จะดูมาด้วย):
/// - ปุ่ม "นัดตรวจสุขภาพ" ในหน้ารายละเอียดคอก (Main_CoopDetail.dart)
/// - รายการนัดตรวจสุขภาพรวมทุกคอก (Main_HealthAppointments.dart)
/// - แตะการแจ้งเตือนเรื่องนัดตรวจในหน้าแจ้งเตือน (Notifications_.dart)
///
/// ดึงข้อมูลจาก backend 3 endpoint พร้อมกันทุกครั้งที่เปิด/รีเฟรชหน้า (ดูรายละเอียด
/// เต็ม ๆ ที่คอมเมนต์เหนือ _fetchData() ด้านล่าง): GET /api/vaccines/alerts (คำนวณ
/// วันนัด), GET /api/healths (ผลตรวจที่เคยบันทึก), GET /api/coops (จำนวนไก่ทั้งหมด
/// ของคอกนี้ เอาไว้เช็กยอดตอนกรอกฟอร์ม) และบันทึกผลตรวจใหม่ผ่าน POST /api/healths
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

/// โมเดลข้อมูล "นัดตรวจสุขภาพ" 1 วัน - ไม่ได้มาจาก API ตรงๆ แต่คำนวณเอาเองใน
/// _fetchData() จากวันครบกำหนดวัคซีน (ลบ 1 วัน) ใช้แค่ในไฟล์นี้ไฟล์เดียว
/// (ไม่ export) เพื่อเก็บพักข้อมูลไว้ก่อนจะเอาไปสร้าง marker บนปฏิทิน
class _AppointmentInfo {
  final DateTime date; // วันที่ต้องตรวจ (= vaccineDate - 1 วัน)
  final String vaccineName; // ชื่อวัคซีนที่จะให้หลังตรวจผ่าน เอาไว้โชว์ในป็อบอัพ
  final DateTime vaccineDate; // วันที่ครบกำหนดให้วัคซีนจริง (วันถัดจาก date)

  _AppointmentInfo({
    required this.date,
    required this.vaccineName,
    required this.vaccineDate,
  });
}

/// โมเดลข้อมูล "ผลตรวจสุขภาพที่บันทึกไว้แล้ว" 1 วัน - แปลงมาจาก 1 แถวของ
/// GET /api/healths ใช้โชว์ในป็อบอัพแบบอ่านอย่างเดียว (_showReadOnlyPopup)
class _HealthRecordInfo {
  final int healthy; // จำนวนไก่สุขภาพดีที่บันทึกไว้
  final int poor; // จำนวนไก่ป่วยที่บันทึกไว้
  final String note; // หมายเหตุที่กรอกตอนบันทึก (ถ้ามี)

  _HealthRecordInfo({
    required this.healthy,
    required this.poor,
    required this.note,
  });
}

const Color kUpcomingAmber = Color(0xFFFFA726);

class _MainHealthCheckCalendarState extends State<MainHealthCheckCalendar> {
  int? selectedIndex; // ไม่ใช่หน้าในแถบเมนูล่าง จึงไม่ไฮไลต์เมนูไหน
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

  /// ฟังก์ชันหลักที่โหลดข้อมูลทั้งหมดของหน้านี้ ถูกเรียก 2 จุด:
  /// 1) initState() ตอนเปิดหน้าครั้งแรก
  /// 2) _submitHealthRecord() หลังบันทึกผลตรวจสำเร็จ (โหลดใหม่ให้ปฏิทินอัปเดต)
  ///
  /// ดึงข้อมูล 3 endpoint พร้อมกัน (Future.wait เพื่อความเร็ว ไม่ต้องรอทีละตัว):
  /// - GET /api/vaccines/alerts  → ตารางแจ้งเตือนวัคซีนทั้งฟาร์ม (ทุกคอก) เอามากรอง
  ///   เฉพาะ coop_id ตรงกับหน้านี้ แล้ว "คำนวณ" วันนัดตรวจ = วันครบกำหนดวัคซีน - 1 วัน
  ///   (ไฟล์นี้ไม่มี endpoint "นัดตรวจ" ของตัวเอง เกาะไปกับกำหนดวัคซีนแทน)
  /// - GET /api/healths          → ประวัติผลตรวจสุขภาพที่เคยบันทึกไว้จริงทุกคอก
  ///   กรองเฉพาะ coop_id ตรงกับหน้านี้เหมือนกัน
  /// - GET /api/coops            → ใช้แค่หาจำนวนไก่ทั้งหมด (amount) ของคอกนี้คอกเดียว
  ///   เพื่อเอาไปเช็กตอนกรอกฟอร์ม (สุขภาพดี + ป่วย ต้องรวมได้เท่าจำนวนไก่จริง)
  ///
  /// จากนั้นรวมผลทั้งสามเป็น _dayMarkers (Map<วันที่, สีจุด+รายละเอียด>) ที่
  /// CustomCalendar เอาไปวาดจุดสีบนปฏิทินโดยตรงในเมธอด build()
  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiClient.get(Uri.parse('$backendBaseUrl/api/vaccines/alerts')),
        ApiClient.get(Uri.parse('$backendBaseUrl/api/healths')),
        ApiClient.get(Uri.parse('$backendBaseUrl/api/coops')),
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
                text: 'ตรวจแล้ว: สุขภาพดี ${r.healthy} / ป่วย ${r.poor} ตัว',
                category: CalendarItemCategory.health,
                status: CalendarItemStatus.done,
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
                  ? 'นัดตรวจ (เตรียมให้${appt.vaccineName} วันที่ ${appt.vaccineDate.day}/${appt.vaccineDate.month})'
                  : 'ถึงกำหนดตรวจแล้ว (เตรียมให้${appt.vaccineName} วันที่ ${appt.vaccineDate.day}/${appt.vaccineDate.month})',
              category: CalendarItemCategory.health,
              status: isFuture
                  ? CalendarItemStatus.upcoming
                  : CalendarItemStatus.overdue,
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

  /// บันทึกผลตรวจสุขภาพ 1 วันลง backend - ถูกเรียกจากปุ่ม "บันทึกผล" ในป็อบอัพ
  /// _showRecordFormPopup() เท่านั้น
  ///
  /// ยิง POST /api/healths ด้วย coop_id ของคอกนี้ + วันที่ + จำนวนไก่สุขภาพดี/ป่วย
  /// + หมายเหตุ สำเร็จแล้วจะปิดป็อบอัพ โชว์แบนเนอร์เขียว แล้วเรียก _fetchData()
  /// ซ้ำเพื่อให้ปฏิทินอัปเดตจุดสีทันที (จากสีส้ม/แดง "มีนัด" กลายเป็นสีเขียว "ตรวจแล้ว")
  Future<void> _submitHealthRecord(
    DateTime date,
    int healthy,
    int poor,
    String note,
  ) async {
    try {
      final response = await ApiClient.post(
        Uri.parse('$backendBaseUrl/api/healths'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'coop_id': int.tryParse(widget.coopId) ?? 0,
          'record_date': '${date.toIso8601String().split('T').first}T00:00:00Z',
          'healthy': healthy,
          'poor_health': poor,
          'note': note,
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context);
        showEzTopBanner(
          context,
          'บันทึกผลตรวจสุขภาพแล้ว',
          type: EzBannerType.success,
        );
        _fetchData();
      } else if (response.statusCode == 409) {
        // ปกติ UI หน้านี้กันไว้แล้วตั้งแต่ _onDayTap (วันที่มีผลตรวจแล้วจะเปิดแค่
        // ป็อบอัพอ่านอย่างเดียว กดบันทึกซ้ำไม่ได้) แต่เผื่อกรณีชนกัน เช่น เปิดค้าง
        // ไว้ 2 ที่พร้อมกันแล้วกดบันทึกพร้อมกัน - backend กันซ้ำด้วย unique
        // constraint แล้วส่ง 409 กลับมา บอกตรงๆ แทนข้อความกลางๆ
        showEzTopBanner(
          context,
          'มีผลตรวจของวันนี้อยู่แล้ว กรุณารีเฟรชหน้านี้แล้วลองใหม่',
          type: EzBannerType.error,
        );
      } else {
        showEzTopBanner(
          context,
          'บันทึกไม่สำเร็จ กรุณาลองใหม่อีกครั้ง',
          type: EzBannerType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showEzTopBanner(
        context,
        'เชื่อมต่อ backend ไม่สำเร็จ',
        type: EzBannerType.error,
      );
    }
  }

  /// Callback ที่ CustomCalendar เรียกทุกครั้งที่แตะวันในปฏิทิน (ผูกไว้ที่
  /// onDateSelected ในเมธอด build()) ตัดสินใจว่าจะเปิดป็อบอัพแบบไหนตามสถานะวันนั้น:
  /// - ไม่มีนัด/ไม่มีบันทึกเลย (ไม่มีใน _dayMarkers) → ไม่ทำอะไร
  /// - มีบันทึกผลตรวจแล้ว (อยู่ใน _records) → เปิดแบบอ่านอย่างเดียว
  /// - มีนัดแต่ยังไม่ถึงวัน (อยู่ใน _appointments, อนาคต) → เปิดป็อบอัพแจ้งว่ายังตรวจไม่ได้
  /// - มีนัดและถึง/เลยกำหนดแล้ว → เปิดฟอร์มให้กรอกผลตรวจ
  void _onDayTap(DateTime day) {
    if (!_dayMarkers.containsKey(day))
      return; // ไม่มีนัด/ไม่มีบันทึก ไม่ต้องเปิดป็อบอัพ

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

  /// ป็อบอัพ "ดูผลตรวจที่บันทึกไว้แล้ว" (แค่แสดงผล กดอะไรแก้ไขไม่ได้) เปิดจาก
  /// _onDayTap() เมื่อแตะวันที่มีข้อมูลใน _records อยู่แล้ว ข้อมูลที่โชว์มาจาก
  /// _HealthRecordInfo ที่แปลงไว้แล้วตอน _fetchData() ไม่ได้ยิง API ซ้ำตรงนี้
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

  /// วิดเจ็ตช่วยย่อย ๆ - การ์ดตัวเลขสถิติ 1 กล่อง (ใช้ซ้ำ 2 ที่ใน _showReadOnlyPopup
  /// คือกล่อง "สุขภาพดี" กับกล่อง "ป่วย") ไม่ได้ดึงข้อมูลเอง รับค่ามาแสดงอย่างเดียว
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

  /// ป็อบอัพ "ยังไม่ถึงวันนัด" เปิดจาก _onDayTap() เมื่อแตะวันในอนาคตที่มีนัดรออยู่
  /// (ยังตรวจไม่ได้) มีแค่ปุ่มปิด ไม่มีฟอร์มให้กรอก เอาไว้กันคนกดบันทึกผลตรวจ
  /// ล่วงหน้าก่อนถึงวันจริง
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

  /// ป็อบอัพฟอร์มกรอกผลตรวจสุขภาพ เปิดจาก _onDayTap() เมื่อแตะวันที่ถึง/เลย
  /// กำหนดนัดแล้ว ให้กรอกจำนวนไก่สุขภาพดี/ป่วย + หมายเหตุ มีเช็กก่อนบันทึก 2 ชั้น:
  /// 1) ต้องกรอกทั้งสองช่องเป็นตัวเลข ไม่ติดลบ
  /// 2) ถ้ารู้จำนวนไก่ทั้งหมดของคอกนี้ (_totalChickens จาก /api/coops) สุขภาพดี+ป่วย
  ///    ต้องรวมได้พอดีเท่านั้น ไม่งั้น error กันกรอกเลขมั่ว
  /// ผ่านแล้วค่อยเรียก _submitHealthRecord() เพื่อยิง API จริง
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
                          labelStyle: GoogleFonts.kanit(
                            color: ez.textSecondary,
                          ),
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
                          labelStyle: GoogleFonts.kanit(
                            color: ez.textSecondary,
                          ),
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
                          labelStyle: GoogleFonts.kanit(
                            color: ez.textSecondary,
                          ),
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
                                          healthy + poor != _totalChickens) {
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

  /// วิดเจ็ตช่วยย่อย ๆ - จุดสีกลม + ข้อความคำอธิบาย 1 อัน ใช้วาดแถบ "คำอธิบายสี"
  /// ใต้ปฏิทินในเมธอด build() (เขียว/ส้ม/แดง) ไม่ได้ดึงข้อมูลอะไร แค่รับสี+ข้อความมาวาด
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

  /// Callback ของแถบเมนูล่าง (CustomBottomBar) ผูกไว้ใน build() - หน้านี้ไม่ได้อยู่
  /// ในแถบเมนูหลัก (selectedIndex เริ่มเป็น null ไม่ไฮไลต์ปุ่มไหน) แต่ยังกดสลับไป
  /// หน้าอื่นจากตรงนี้ได้ตามปกติ: 0=หน้าแรก(MainScreen), 1=อุปกรณ์เซนเซอร์
  /// (MainDeviceSummary), 2=กราฟสถิติ(ShowChart), 3=ข้อมูลไก่(Mainchicken),
  /// 4=คลังอาหาร(MainShowDataFood)
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
              child: EzHeader(pageTitle: 'นัดตรวจสุขภาพ - ${widget.coopName}'),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    const SizedBox(height: 100),
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
