import 'dart:convert';
import '../utils/thai_date.dart';
import 'api_client.dart';
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
    final response = await ApiClient.get(Uri.parse('$backendBaseUrl/api/foods'));

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
      ApiClient.get(Uri.parse('$backendBaseUrl/api/coops')),
      ApiClient.get(Uri.parse('$backendBaseUrl/api/vaccines/alerts')),
      ApiClient.get(Uri.parse('$backendBaseUrl/api/healths')),
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

      // กลุ่มตาม (coopId, วันควรตรวจ) ก่อน - ถ้าวัคซีนหลายชนิดของคอกเดียวกันครบ
      // กำหนดวันเดียวกันพอดี (เลยต้องตรวจสุขภาพวันเดียวกันด้วย) จะได้แจ้งเตือนครั้ง
      // เดียวรวมชื่อวัคซีนทุกชนิด ไม่ใช่ขึ้นซ้ำทีละชนิด เพราะตรวจครั้งเดียวเอาผลไป
      // ใช้กับวัคซีนทุกชนิดที่ตรงวันนั้นได้เลย
      final Map<String, List<String>> healthGroupNames = {};
      final Map<String, Map<String, dynamic>> healthGroupMeta = {};

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

        // --- แจ้งเตือนตรวจสุขภาพ (1 วันก่อนวันให้วัคซีนเสมอ) - เก็บเข้ากลุ่มไว้
        // ก่อน ยังไม่สร้างแจ้งเตือนตรงนี้ (ดูการสร้างแบบรวมหลัง loop) ---
        final healthCheckDate = dueOnly.subtract(const Duration(days: 1));
        final daysUntilHealthCheck = healthCheckDate
            .difference(todayOnly)
            .inDays;
        final alreadyChecked = checkedHealthDates.contains(
          '${coopId}_${dateKey(healthCheckDate)}',
        );
        if (!alreadyChecked &&
            daysUntilHealthCheck <= kNotificationAdvanceDays) {
          final groupKey = '${coopId}_${dateKey(healthCheckDate)}';
          healthGroupNames.putIfAbsent(groupKey, () => []).add(vaccineName);
          healthGroupMeta[groupKey] = {
            "healthCheckDate": healthCheckDate,
            "daysUntilHealthCheck": daysUntilHealthCheck,
            "coopId": coopId,
            "coopName": coopName,
          };
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
          notiTitle =
              "💉 อีก $daysUntilVaccine วันถึงกำหนดให้ $vaccineName ที่ $coopName";
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
          "coopId": coopId,
          "coopName": coopName,
        });
      }

      // สร้างแจ้งเตือนตรวจสุขภาพแบบรวม (1 รายการต่อกลุ่ม coop+วัน) จากที่เก็บไว้
      healthGroupNames.forEach((groupKey, names) {
        final meta = healthGroupMeta[groupKey]!;
        final healthCheckDate = meta["healthCheckDate"] as DateTime;
        final daysUntilHealthCheck = meta["daysUntilHealthCheck"] as int;
        final coopId = meta["coopId"] as String;
        final coopName = meta["coopName"] as String;
        final namesText = names.join('และ');

        String healthTitle;
        if (daysUntilHealthCheck < 0) {
          healthTitle =
              "‼️ เลยกำหนดตรวจสุขภาพที่ $coopName ก่อนให้ $namesText มา ${-daysUntilHealthCheck} วันแล้ว";
        } else if (daysUntilHealthCheck == 0) {
          healthTitle =
              "‼️ วันนี้ถึงกำหนดตรวจสุขภาพที่ $coopName ก่อนให้ $namesText";
        } else if (daysUntilHealthCheck == 1) {
          healthTitle =
              "🩺 พรุ่งนี้ถึงกำหนดตรวจสุขภาพที่ $coopName ก่อนให้ $namesText";
        } else {
          healthTitle =
              "🩺 อีก $daysUntilHealthCheck วันถึงกำหนดตรวจสุขภาพที่ $coopName ก่อนให้ $namesText";
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
      });
    }
  } catch (e) {
    // ข้อมูลเสริม ดึงไม่ได้ก็ยังแสดงแจ้งเตือนอื่นได้ตามปกติ
  }

  // ---------------------------------------------------------
  // 4. แจ้งเตือนตรวจจับความเคลื่อนไหว (เซนเซอร์ PIR ที่วงกบประตู) - รวมเป็น
  //    1 แจ้งเตือนต่อคอก (ไม่ใช่ 1 อันต่อครั้งตรวจจับ เพราะอาจมีหลายสิบครั้ง/วัน)
  //    โชว์จำนวนครั้งรวมกับเวลาที่ตรวจจับล่าสุด ข้อมูลดิบมาจาก /api/motion-alerts
  //    (backend เรียงล่าสุดมาก่อนให้แล้ว)
  // ---------------------------------------------------------
  try {
    final response = await ApiClient.get(
      Uri.parse('$backendBaseUrl/api/motion-alerts'),
    );
    if (response.statusCode == 200 &&
        response.body.isNotEmpty &&
        response.body != 'null') {
      final List<dynamic> rows = jsonDecode(response.body);
      final Map<String, Map<String, dynamic>> byCoop = {};
      for (final row in rows) {
        if (row is! Map<String, dynamic>) continue;
        final coopId = row['coop_id']?.toString();
        final ts = DateTime.tryParse(row['timestamp']?.toString() ?? '')
            ?.toLocal();
        if (coopId == null || ts == null) continue;
        final coopName = row['coop_name']?.toString().trim().isNotEmpty == true
            ? row['coop_name'].toString()
            : 'คอก $coopId';
        final existing = byCoop[coopId];
        if (existing == null) {
          byCoop[coopId] = {'coopName': coopName, 'count': 1, 'lastAt': ts};
        } else {
          existing['count'] = (existing['count'] as int) + 1;
          if (ts.isAfter(existing['lastAt'] as DateTime)) {
            existing['lastAt'] = ts;
          }
        }
      }
      byCoop.forEach((coopId, info) {
        final lastAt = info['lastAt'] as DateTime;
        final timeLabel =
            '${lastAt.hour.toString().padLeft(2, '0')}:${lastAt.minute.toString().padLeft(2, '0')}';
        newNotifications.add({
          "id": "motion_$coopId",
          "type": "motion",
          "title":
              "🚶 ตรวจพบความเคลื่อนไหวที่${info['coopName']} (${info['count']} ครั้ง ล่าสุด $timeLabel)",
          "time": timeNow,
          "date": dateNow,
          "urgent": false,
          "daysUntil": -1,
          "coopId": coopId,
          "coopName": info['coopName'],
        });
      });
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
