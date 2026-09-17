import 'dart:convert';
import 'package:http/http.dart' as http;
import 'backend_config.dart';
import '../pages/calendar.dart';

/// ดึงข้อมูลวันเกิดไก่/วันรับเข้าเลี้ยง (จากคอก), ตรวจสุขภาพ, และวัคซีน
/// มาผสานเป็นมาร์กปฏิทินรวมจุดเดียว ใช้กับหน้า "ปฏิทินรวม"
Future<Map<DateTime, DayMarkerInfo>> loadCalendarOverviewMarkers() async {
  final results = await Future.wait([
    http.get(Uri.parse('$backendBaseUrl/api/coops')),
    http.get(Uri.parse('$backendBaseUrl/api/healths')),
    http.get(Uri.parse('$backendBaseUrl/api/vaccines/alerts')),
  ]);

  final coopsResp = results[0];
  final healthResp = results[1];
  final alertsResp = results[2];

  final List<dynamic> coops = coopsResp.statusCode == 200
      ? jsonDecode(coopsResp.body)
      : [];
  final List<dynamic> healths = healthResp.statusCode == 200
      ? jsonDecode(healthResp.body)
      : [];
  final List<dynamic> alerts = alertsResp.statusCode == 200
      ? jsonDecode(alertsResp.body)
      : [];

  final Map<String, String> coopNames = {
    for (final c in coops)
      (c['coop_id'] ?? c['id'])
          .toString(): (c['name_coop']?.toString().trim().isNotEmpty == true)
          ? c['name_coop'].toString()
          : (c['coop_id'] ?? c['id']).toString(),
  };

  final Map<DateTime, List<DayDetailItem>> detailsByDate = {};

  DateTime? dateOnly(dynamic raw) {
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return null;
    final local = parsed.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  void addDetail(
    DateTime? date,
    String text, {
    required CalendarItemCategory category,
    required CalendarItemStatus status,
    String? coopId,
  }) {
    if (date == null) return;
    detailsByDate
        .putIfAbsent(date, () => [])
        .add(
          DayDetailItem(
            text: text,
            category: category,
            status: status,
            coopId: coopId,
          ),
        );
  }

  for (final coop in coops) {
    final coopId = (coop['coop_id'] ?? coop['id']).toString();
    final name = coopNames[coopId] ?? coopId;

    final birthday = dateOnly(coop['birthday'] ?? coop['Birthday']);
    addDetail(
      birthday,
      'วันเกิดไก่ – คอก$name',
      category: CalendarItemCategory.birthday,
      status: CalendarItemStatus.info,
      coopId: coopId,
    );

    final adoptDate = dateOnly(coop['date_adopt_animals']);
    addDetail(
      adoptDate,
      'วันที่รับเข้าเลี้ยง – คอก$name',
      category: CalendarItemCategory.adopt,
      status: CalendarItemStatus.info,
      coopId: coopId,
    );
  }

  for (final h in healths) {
    final coopId = (h['coop_id'])?.toString() ?? '-';
    final name = coopNames[coopId] ?? coopId;
    final date = dateOnly(h['record_date']);
    final healthy = h['healthy']?.toString() ?? '0';
    final poor = h['poor_health']?.toString() ?? '0';
    addDetail(
      date,
      'ตรวจสุขภาพ – คอก$name (สุขภาพดี $healthy / ป่วย $poor)',
      category: CalendarItemCategory.health,
      status: CalendarItemStatus.info,
      coopId: coopId,
    );
  }

  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);

  for (final a in alerts) {
    final coopId = (a['coop_id'])?.toString() ?? '-';
    final name = coopNames[coopId] ?? coopId;
    final date = dateOnly(a['date']);
    final vaccineName = a['vaccine_name']?.toString() ?? 'วัคซีน';
    final isCompleted = a['is_completed'] == true;

    // ตัดสินสถานะจากวันที่จริงเทียบกับวันนี้ แทนการเชื่อ flag is_overdue
    // จาก backend อย่างเดียว เพื่อไม่ให้วันที่ยังมาไม่ถึงถูกมาร์คว่า "ถึงกำหนด"
    // (สีแดง/ต้องทำ) ทั้งที่จริงๆ ยังเป็นแค่นัดล่วงหน้า
    final CalendarItemStatus status;
    if (isCompleted) {
      status = CalendarItemStatus.done;
    } else if (date != null && !date.isAfter(todayOnly)) {
      status = CalendarItemStatus.overdue;
    } else {
      status = CalendarItemStatus.upcoming;
    }

    addDetail(
      date,
      '$vaccineName – คอก$name',
      category: CalendarItemCategory.vaccine,
      status: status,
      coopId: coopId,
    );
  }

  return {
    for (final entry in detailsByDate.entries)
      entry.key: DayMarkerInfo(
        color: DayMarkerInfo.colorForDetails(entry.value),
        details: entry.value,
      ),
  };
}
