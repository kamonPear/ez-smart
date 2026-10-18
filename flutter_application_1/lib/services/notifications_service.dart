import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/thai_date.dart';
import 'api_client.dart';
import 'backend_config.dart';

/// โหลดรายการแจ้งเตือนทั้งหมดของฟาร์ม (อาหารใกล้หมด/หมด, ใกล้ถึงกำหนดให้วัคซีน,
/// ใกล้ถึงกำหนดตรวจสุขภาพก่อนให้วัคซีน) ใช้ร่วมกันทั้งหน้า [Notifications] เอง
/// และแถบเมนู (hamburger drawer) ที่ต้องรู้แค่ "จำนวน" ไว้ขึ้นตัวเลขแจ้งเตือน
///
/// เตือนล่วงหน้า 2 วันก่อนถึงกำหนด (ทั้งวัคซีนและตรวจสุขภาพ) ไปจนถึงเลยกำหนดแล้ว
const int kNotificationAdvanceDays = 2;

String _motionAckKey(String coopId) => 'motion_ack_$coopId';

/// จำว่าผู้ใช้กด "รับทราบ" แจ้งเตือนความเคลื่อนไหวของคอกนี้แล้ว ถึงเวลา [upTo]
/// - ครั้งถัดไปจะแจ้งเตือนอีกก็ต่อเมื่อมีการตรวจจับใหม่หลังเวลานี้เท่านั้น
Future<void> acknowledgeMotionAlert(String coopId, DateTime upTo) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_motionAckKey(coopId), upTo.toUtc().toIso8601String());
}

/// เตือนล่วงหน้า/ค้างหลังไก่ถึงช่วงอายุที่ต้องเปลี่ยนประเภทอาหารกี่วัน
const int kFoodSwitchWindowDays = 3;

const String _foodSwitchAckKey = 'food_switch_ack';

/// จำว่าผู้ใช้กด "รับทราบ" แจ้งเตือนเปลี่ยนประเภทอาหารตามอายุ [id] แล้ว
/// (id ผูกกับคอก+ประเภทอาหารใหม่ ไม่ขึ้นซ้ำ แต่ช่วงอายุถัดไปจะขึ้นเป็นแจ้งเตือนใหม่)
Future<void> acknowledgeFoodSwitchAlert(String id) async {
  final prefs = await SharedPreferences.getInstance();
  final acks = prefs.getStringList(_foodSwitchAckKey) ?? <String>[];
  if (!acks.contains(id)) {
    acks.add(id);
    await prefs.setStringList(_foodSwitchAckKey, acks);
  }
}

const String _offlineAckKey = 'offline_ack';

/// จำว่าผู้ใช้กด "รับทราบ" แจ้งเตือนเซนเซอร์/พัดลมไม่ทำงานของอุปกรณ์ [id] แล้ว
/// - id ผูกกับอุปกรณ์อย่างเดียว (ห้ามใส่ last_update: พัดลมส่งสถานะทุก 2 วินาที ค่านี้
///   เปลี่ยนตลอด ทำให้กดรับทราบแล้วแจ้งเตือนกลับมาเอง) การรับทราบจะถูกล้างเองเมื่อ
///   อุปกรณ์กลับมาปกติ ถ้าเสียรอบใหม่จึงแจ้งเตือนใหม่
Future<void> acknowledgeOfflineAlert(String id) async {
  final prefs = await SharedPreferences.getInstance();
  final acks = prefs.getStringList(_offlineAckKey) ?? <String>[];
  if (!acks.contains(id)) {
    acks.add(id);
    await prefs.setStringList(_offlineAckKey, acks);
  }
}

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
    final response = await ApiClient.get(
      Uri.parse('$backendBaseUrl/api/foods'),
    );

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
        } else if (minQuantity > 0 && currentQuantity <= minQuantity) {
          newNotifications.add({
            "id": foodId,
            "type": "food",
            "title":
                "⚠️ อาหาร$foodTypeใกล้หมดแล้ว (เหลือ ${currentQuantity.toStringAsFixed(1)} กก.)",
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
  // 1b. แจ้งเตือนไก่เปลี่ยนช่วงอายุ -> ต้องเปลี่ยนประเภทอาหาร (ตามตารางอาหารตามอายุที่
  //     เจ้าของตั้งไว้) หาขอบช่วงที่ประเภทอาหารต่างจากช่วงก่อนหน้า แล้วเตือนล่วงหน้า/ค้าง
  //     หลังถึงวันนั้น kFoodSwitchWindowDays วัน (วันถึงขอบช่วง = วันเกิด + min_weeks x 7)
  // ---------------------------------------------------------
  try {
    final results = await Future.wait([
      ApiClient.get(Uri.parse('$backendBaseUrl/api/coops')),
      ApiClient.get(Uri.parse('$backendBaseUrl/api/food-age-rules')),
    ]);
    if (results[0].statusCode == 200 && results[1].statusCode == 200) {
      final coops = jsonDecode(results[0].body);
      final rawRules = results[1].body.isNotEmpty && results[1].body != 'null'
          ? jsonDecode(results[1].body)
          : [];
      final rules = <Map<String, dynamic>>[
        if (rawRules is List)
          for (final r in rawRules)
            if (r is Map<String, dynamic> &&
                (r['food_type']?.toString() ?? '').isNotEmpty)
              {
                'type': r['food_type'].toString(),
                'min': (r['min_weeks'] as num?)?.toInt() ?? 0,
                'max': (r['max_weeks'] as num?)?.toInt() ?? 0,
              },
      ];
      Map<String, dynamic>? ruleAt(int ageWeeks) {
        for (final r in rules) {
          if (ageWeeks >= (r['min'] as int) &&
              ((r['max'] as int) == 0 || ageWeeks < (r['max'] as int))) {
            return r;
          }
        }
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      final acks = (prefs.getStringList(_foodSwitchAckKey) ?? <String>[]).toSet();

      for (final c in (coops is List ? coops : const [])) {
        if (c is! Map<String, dynamic>) continue;
        final birthday = DateTime.tryParse(c['birthday']?.toString() ?? '')?.toLocal();
        if (birthday == null) continue;
        final coopId = (c['coop_id'] ?? c['id']).toString();
        final coopName = c['name_coop']?.toString().trim().isNotEmpty == true
            ? c['name_coop'].toString()
            : 'คอก $coopId';
        final birthOnly = DateTime(birthday.year, birthday.month, birthday.day);

        Map<String, dynamic>? best;
        for (final r in rules) {
          final min = r['min'] as int;
          if (min <= 0) continue;
          final prev = ruleAt(min - 1);
          if (prev == null || prev['type'] == r['type']) continue;
          final boundary = DateTime(
            birthOnly.year,
            birthOnly.month,
            birthOnly.day + min * 7,
          );
          final days = boundary.difference(todayOnly).inDays;
          if (days > kFoodSwitchWindowDays || days < -kFoodSwitchWindowDays) {
            continue;
          }
          if (best == null || days.abs() < (best['days'] as int).abs()) {
            best = {'days': days, 'from': prev['type'], 'to': r['type']};
          }
        }
        if (best == null) continue;

        final id = 'foodswitch_${coopId}_${best['to']}';
        if (acks.contains(id)) continue;

        final days = best['days'] as int;
        final from = best['from'];
        final to = best['to'];
        String title;
        if (days < 0) {
          title =
              "🌾 $coopNameถึงช่วงเปลี่ยนเป็นอาหาร$toมา ${-days} วันแล้ว (จากเดิมอาหาร$from) กรุณาเปลี่ยนอาหาร";
        } else if (days == 0) {
          title = "🌾 วันนี้$coopNameต้องเปลี่ยนจากอาหาร$fromเป็นอาหาร$to";
        } else if (days == 1) {
          title = "🌾 พรุ่งนี้$coopNameต้องเปลี่ยนจากอาหาร$fromเป็นอาหาร$to";
        } else {
          title = "🌾 อีก $days วัน$coopNameต้องเปลี่ยนจากอาหาร$fromเป็นอาหาร$to";
        }
        newNotifications.add({
          "id": id,
          "type": "food",
          "title": title,
          "time": timeNow,
          "date": dateNow,
          "urgent": days <= 0,
          "daysUntil": days,
          "coopId": coopId,
          "coopName": coopName,
        });
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
      final prefs = await SharedPreferences.getInstance();
      final Map<String, Map<String, dynamic>> byCoop = {};
      for (final row in rows) {
        if (row is! Map<String, dynamic>) continue;
        final coopId = row['coop_id']?.toString();
        final ts = DateTime.tryParse(
          row['timestamp']?.toString() ?? '',
        )?.toLocal();
        if (coopId == null || ts == null) continue;
        // ข้ามการตรวจจับที่ผู้ใช้กดรับทราบไปแล้ว
        final ack = DateTime.tryParse(
          prefs.getString(_motionAckKey(coopId)) ?? '',
        );
        if (ack != null && !ts.isAfter(ack)) continue;
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
          // แสดงเวลาที่ตรวจจับจริง ไม่ใช่เวลาปัจจุบัน (ไม่งั้นเวลาจะขยับตามทุกครั้งที่
          // โหลดหน้า ดูเหมือนแจ้งเตือนใหม่ตลอด)
          "time": timeLabel,
          "date": thaiDate(lastAt),
          "lastAt": lastAt,
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

  // ---------------------------------------------------------
  // 5. แจ้งเตือนเซนเซอร์ไม่ทำงาน (Offline) และพัดลมที่ควรทำงานแต่ไม่ทำงาน (อุณหภูมิ/
  //    แอมโมเนียถึงเกณฑ์ฟาร์มแล้ว) - ข้อมูลมาจาก /api/offline-alerts ซึ่ง backend คัดมาให้
  //    แล้ว (เฉพาะคอกที่กำลังส่งข้อมูลจากบอร์ดอยู่) 1 แจ้งเตือนต่ออุปกรณ์
  // ---------------------------------------------------------
  try {
    final response = await ApiClient.get(
      Uri.parse('$backendBaseUrl/api/offline-alerts'),
    );
    if (response.statusCode == 200) {
      final decoded = response.body.isNotEmpty && response.body != 'null'
          ? jsonDecode(response.body)
          : [];
      final List<dynamic> rows = decoded is List ? decoded : [];
      final prefs = await SharedPreferences.getInstance();
      final acks = prefs.getStringList(_offlineAckKey) ?? <String>[];
      final currentIds = <String>{};
      for (final row in rows) {
        if (row is! Map<String, dynamic>) continue;
        final id = 'offline_${row['device_id']}';
        currentIds.add(id);
        if (acks.contains(id)) continue;

        final coopId = row['coop_id']?.toString() ?? '';
        var coopName = row['coop_name']?.toString().trim().isNotEmpty == true
            ? row['coop_name'].toString().trim()
            : 'คอก $coopId';
        final isFan = row['kind'] == 'fan';
        String title;
        if (isFan) {
          if (!coopName.startsWith('คอก')) coopName = 'คอก $coopName';
          title = '‼️ $coopName พัดลมไม่ทำงาน กรุณาตรวจสอบ';
        } else {
          final sensorName = row['device_name']?.toString().trim().isNotEmpty == true
              ? row['device_name'].toString().trim()
              : 'ช่อง ${row['slot_index'] ?? '-'}';
          final last = DateTime.tryParse(
            row['last_update']?.toString() ?? '',
          )?.toLocal();
          final since = last == null
              ? ''
              : ' (ข้อมูลล่าสุด ${last.day}/${last.month} ${last.hour.toString().padLeft(2, '0')}:${last.minute.toString().padLeft(2, '0')})';
          title = '📡 เซนเซอร์ $sensorName ที่$coopName ไม่ทำงาน$since กรุณาตรวจสอบ';
        }
        newNotifications.add({
          "id": id,
          "type": "offline",
          "title": title,
          "time": timeNow,
          "date": dateNow,
          "urgent": true,
          "daysUntil": -500,
          "coopId": coopId,
          "coopName": coopName,
        });
      }
      // ล้างการรับทราบของอุปกรณ์ที่กลับมาปกติแล้ว (ทำเฉพาะเมื่อโหลดสำเร็จ ไม่งั้น
      // "โหลดไม่ได้" จะถูกมองเป็น "ปกติทุกตัว" แล้วล้างทิ้งหมด)
      final kept = acks.where(currentIds.contains).toList();
      if (kept.length != acks.length) {
        await prefs.setStringList(_offlineAckKey, kept);
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
