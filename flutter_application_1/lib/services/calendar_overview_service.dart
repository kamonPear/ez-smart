import 'dart:convert';
import 'api_client.dart';
import 'backend_config.dart';
import '../pages/calendar.dart';

/// ดึงปฏิทินรวม (วัคซีน/ตรวจสุขภาพ/วันเกิดไก่-วันรับเข้าเลี้ยง/นัดตรวจสุขภาพกำหนดเอง)
/// จาก backend endpoint เดียว (`/api/calendar/markers`) ซึ่งเป็น single source of
/// truth ที่คำนวณ+รวมข้อมูลให้แล้วฝั่ง server (เดิมหน้านี้ต้องยิง 3 คำขอแยก
/// แล้วมารวม/คำนวณสถานะเองฝั่ง client) - ใช้กับทั้งหน้า "ปฏิทินรวม" ของทั้งฟาร์ม
/// (ไม่ส่ง coopId) และปฏิทินเฉพาะคอก (ส่ง coopId) ในอนาคต
///
/// ใส่ [coopId] เพื่อขอเฉพาะคอกนั้น ไม่ใส่ (null) เพื่อขอทั้งฟาร์ม
Future<Map<DateTime, DayMarkerInfo>> loadCalendarOverviewMarkers({
  String? coopId,
}) async {
  final query = (coopId != null && coopId.isNotEmpty) ? '?coop_id=$coopId' : '';
  final response = await ApiClient.get(
    Uri.parse('$backendBaseUrl/api/calendar/markers$query'),
  );

  if (response.statusCode != 200) {
    return {};
  }

  final Map<String, dynamic> raw = jsonDecode(response.body);

  CalendarItemCategory parseCategory(dynamic value) {
    return switch (value?.toString()) {
      'vaccine' => CalendarItemCategory.vaccine,
      'health' => CalendarItemCategory.health,
      'birthday' => CalendarItemCategory.birthday,
      'adopt' => CalendarItemCategory.adopt,
      'appointment' => CalendarItemCategory.appointment,
      // ไม่รู้จักหมวดนี้ (เช่น backend เพิ่มหมวดใหม่ในอนาคต) - fallback ไปใช้
      // "ตรวจสุขภาพ" เพื่อไม่ให้แอปพัง
      _ => CalendarItemCategory.health,
    };
  }

  CalendarItemStatus parseStatus(dynamic value) {
    return switch (value?.toString()) {
      'done' => CalendarItemStatus.done,
      'upcoming' => CalendarItemStatus.upcoming,
      'overdue' => CalendarItemStatus.overdue,
      'info' => CalendarItemStatus.info,
      // สถานะที่ไม่รู้จัก - fallback เป็น "info" (เขียว/แจ้งให้ทราบ) ซึ่งปลอดภัย
      // ที่สุด แทนที่จะโยน error หรือเดาว่าเกินกำหนด
      _ => CalendarItemStatus.info,
    };
  }

  DateTime? dateKeyToDate(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  final Map<DateTime, DayMarkerInfo> markers = {};

  for (final entry in raw.entries) {
    final date = dateKeyToDate(entry.key);
    if (date == null) continue;

    final Map<String, dynamic> dayData =
        (entry.value as Map<String, dynamic>?) ?? {};
    final List<dynamic> rawDetails = dayData['details'] ?? [];

    final details = <DayDetailItem>[
      for (final d in rawDetails)
        DayDetailItem(
          text: d['text']?.toString() ?? '',
          category: parseCategory(d['category']),
          status: parseStatus(d['status']),
          coopId: d['coop_id']?.toString(),
        ),
    ];

    markers[date] = DayMarkerInfo(
      color: DayMarkerInfo.colorForDetails(details),
      details: details,
    );
  }

  return markers;
}
