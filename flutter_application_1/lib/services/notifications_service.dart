import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/thai_date.dart';
import 'backend_config.dart';

/// โหลดรายการแจ้งเตือนทั้งหมดของฟาร์ม (อาหารใกล้หมด/หมด, ใกล้ถึงกำหนดให้วัคซีน,
/// ใกล้ถึงกำหนดตรวจสุขภาพก่อนให้วัคซีน) ใช้ร่วมกันทั้งหน้า [Notifications] เอง
/// และแถบเมนู (hamburger drawer) ที่ต้องรู้แค่ "จำนวน" ไว้ขึ้นตัวเลขแจ้งเตือน
///
/// เตือนล่วงหน้า 2 วันก่อนถึงกำหนด (ทั้งวัคซีนและตรวจสุขภาพ) ไปจนถึงเลยกำหนดแล้ว
const int kNotificationAdvanceDays = 2;

Future<List<Map<String, dynamic>>> loadNotifications() async {
  List<Map<String, dynamic>> newNotifications = [];
  DateTime today = DateTime.now();
  DateTime todayOnly = DateTime(today.year, today.month, today.day);

  String timeNow =
      "${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}";
  String dateNow = thaiDate(today);

  String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------
  // 1. แจ้งเตือนปริมาณอาหาร (ใกล้หมด / หมดแล้ว) - เช็คทุกประเภทอาหาร
  // ---------------------------------------------------------
  try {
    final response = await http.get(Uri.parse('$backendBaseUrl/api/foods'));

    if (response.statusCode == 200 &&
        response.body.isNotEmpty &&
        response.body != 'null') {
      final decoded = jsonDecode(response.body);
      final List<dynamic> rows = decoded is List ? decoded : [];

      for (final row in rows) {
        if (row is! Map<String, dynamic>) continue;
        double currentQuantity =
            (row['quantity_current'] as num?)?.toDouble() ?? 0.0;
        double minQuantity = (row['min_quantity'] as num?)?.toDouble() ?? 0.0;
        String foodType = row['food_type']?.toString() ?? 'อาหาร';
        int foodId = row['id'] ?? 0;

        if (currentQuantity <= 0.0) {
          newNotifications.add({
            "id": foodId,
            "type": "food",
            "title": "🚨 อาหาร$foodTypeหมดแล้ว! กรุณาเติมอาหารด่วน",
            "time": timeNow,
            "date": dateNow,
            "urgent": true,
            "daysUntil": -999,
          });
        } else if (currentQuantity <= minQuantity) {
          newNotifications.add({
            "id": foodId,
            "type": "food",
            "title":
                "⚠️ อาหาร$foodTypeใกล้หมด (เหลือ ${currentQuantity.toStringAsFixed(1)} กก.)",
            "time": timeNow,
            "date": dateNow,
            "urgent": false,
            "daysUntil": -999,
          });
        }
      }
    }
  } catch (e) {
    // ข้อมูลเสริม ดึงไม่ได้ก็ยังแสดงแจ้งเตือนอื่นได้ตามปกติ
  }

  // ---------------------------------------------------------
  // 2 + 3. แจ้งเตือนวัคซีน และแจ้งเตือนตรวจสุขภาพ (ก่อนให้วัคซีน 1 วันเสมอ)
  //   ทั้งคู่เริ่มเตือนล่วงหน้า kNotificationAdvanceDays วัน จนถึงเลยกำหนดแล้ว
  //   ซ่อนไปเลยถ้าทำแล้ว (ให้วัคซีนแล้ว / มีผลตรวจสุขภาพของวันนั้นแล้ว)
  // ---------------------------------------------------------
  try {
    final results = await Future.wait([
      http.get(Uri.parse('$backendBaseUrl/api/coops')),
      http.get(Uri.parse('$backendBaseUrl/api/vaccines/alerts')),
      http.get(Uri.parse('$backendBaseUrl/api/healths')),
    ]);
    final coopResp = results[0];
    final alertResp = results[1];
    final healthResp = results[2];

    Map<String, String> coopNames = {};
    if (coopResp.statusCode == 200) {
      final List<dynamic> coops = jsonDecode(coopResp.body);
      coopNames = {
        for (final c in coops)
          (c['coop_id'] ?? c['id']).toString():
              (c['name_coop']?.toString().trim().isNotEmpty == true)
              ? c['name_coop'].toString()
              : (c['coop_id'] ?? c['id']).toString(),
      };
    }

    // key = "coopId_yyyy-MM-dd" ของวันที่มีผลตรวจสุขภาพบันทึกไว้แล้ว
    final Set<String> checkedHealthDates = {};
    if (healthResp.statusCode == 200) {
      final List<dynamic> healths = jsonDecode(healthResp.body);
      for (final h in healths) {
        if (h is! Map<String, dynamic>) continue;
        final coopId = h['coop_id']?.toString();
        final recordDate = DateTime.tryParse(
          h['record_date']?.toString() ?? '',
        )?.toLocal();
        if (coopId == null || recordDate == null) continue;
        checkedHealthDates.add('${coopId}_${dateKey(recordDate)}');
      }
    }

    if (alertResp.statusCode == 200) {
      final List<dynamic> alerts = jsonDecode(alertResp.body);

      for (final a in alerts) {
        if (a is! Map<String, dynamic>) continue;
        if (a['is_completed'] == true) continue; // ทำแล้ว ไม่ต้องเตือนอีก

        final dueDate = DateTime.tryParse(
          a['date']?.toString() ?? '',
        )?.toLocal();
        if (dueDate == null) continue;
        final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);

        final coopId = a['coop_id']?.toString() ?? '-';
        final coopName = coopNames[coopId] ?? 'คอก $coopId';
        final vaccineName = a['vaccine_name']?.toString() ?? 'วัคซีน';

        // --- แจ้งเตือนตรวจสุขภาพ (1 วันก่อนวันให้วัคซีนเสมอ) ---
        final healthCheckDate = dueOnly.subtract(const Duration(days: 1));
        final daysUntilHealthCheck = healthCheckDate
            .difference(todayOnly)
            .inDays;
        final alreadyChecked = checkedHealthDates.contains(
          '${coopId}_${dateKey(healthCheckDate)}',
        );
        if (!alreadyChecked && daysUntilHealthCheck <= kNotificationAdvanceDays) {
          String healthTitle;
          if (daysUntilHealthCheck < 0) {
            healthTitle =
                "‼️ เลยกำหนดตรวจสุขภาพที่ $coopName ก่อนให้ $vaccineName มา ${-daysUntilHealthCheck} วันแล้ว";
          } else if (daysUntilHealthCheck == 0) {
            healthTitle = "‼️ วันนี้ถึงกำหนดตรวจสุขภาพที่ $coopName ก่อนให้ $vaccineName";
          } else if (daysUntilHealthCheck == 1) {
            healthTitle = "🩺 พรุ่งนี้ถึงกำหนดตรวจสุขภาพที่ $coopName ก่อนให้ $vaccineName";
          } else {
            healthTitle =
                "🩺 อีก $daysUntilHealthCheck วันถึงกำหนดตรวจสุขภาพที่ $coopName ก่อนให้ $vaccineName";
          }

          newNotifications.add({
            "id": "health_${coopId}_${dateKey(healthCheckDate)}",
            "type": "health",
            "title": healthTitle,
            "time": timeNow,
            "date": dateNow,
            "urgent": daysUntilHealthCheck <= 0,
            "daysUntil": daysUntilHealthCheck,
            "coopId": coopId,
            "coopName": coopName,
          });
        }

        // --- แจ้งเตือนให้วัคซีน ---
        final daysUntilVaccine = dueOnly.difference(todayOnly).inDays;
        if (daysUntilVaccine > kNotificationAdvanceDays) continue;

        String notiTitle;
        if (daysUntilVaccine < 0) {
          notiTitle =
              "‼️ เลยกำหนดให้ $vaccineName ที่ $coopName มา ${-daysUntilVaccine} วันแล้ว";
        } else if (daysUntilVaccine == 0) {
          notiTitle = "‼️ วันนี้ถึงกำหนดให้ $vaccineName ที่ $coopName";
        } else if (daysUntilVaccine == 1) {
          notiTitle = "💉 พรุ่งนี้ถึงกำหนดให้ $vaccineName ที่ $coopName";
        } else {
          notiTitle = "💉 อีก $daysUntilVaccine วันถึงกำหนดให้ $vaccineName ที่ $coopName";
        }

        newNotifications.add({
          "id": a['id'],
          "type": "vaccine",
          "title": notiTitle,
          "time": timeNow,
          "date": dateNow,
          "urgent": daysUntilVaccine <= 0,
          "daysUntil": daysUntilVaccine,
          "method": a['injection_type'] ?? '-',
          "chickenAge": a['chicken_age'] ?? 0,
          "note": a['description'] ?? '',
        });
      }
    }
  } catch (e) {
    // ข้อมูลเสริม ดึงไม่ได้ก็ยังแสดงแจ้งเตือนอื่นได้ตามปกติ
  }

  // เรียงลำดับ: เลยกำหนด/วันนี้ก่อน แล้วไล่ตามความเร่งด่วน
  newNotifications.sort((x, y) {
    final dx = x['daysUntil'] as int? ?? 999;
    final dy = y['daysUntil'] as int? ?? 999;
    return dx.compareTo(dy);
  });

  return newNotifications;
}
