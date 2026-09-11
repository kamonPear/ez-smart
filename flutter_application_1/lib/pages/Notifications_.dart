import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bottombar.dart';
import '../../services/backend_config.dart';
import '../widgets/ez_header.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../utils/thai_date.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  int? selectedIndex; // ไม่ใช่หน้าในแถบเมนูล่าง จึงไม่ไฮไลต์เมนูไหน
  bool isLoading = true;

  // 🌟 1. เปลี่ยนเป็น Map<String, dynamic> เพื่อให้เก็บ ID (int) และแยกประเภทได้
  List<Map<String, dynamic>> notificationsList = [];

  @override
  void initState() {
    super.initState();
    _fetchAndCheckNotifications();
  }

  Future<void> _fetchAndCheckNotifications() async {
    setState(() {
      isLoading = true;
    });

    List<Map<String, dynamic>> newNotifications = [];
    DateTime today = DateTime.now();
    DateTime todayOnly = DateTime(today.year, today.month, today.day);

    String timeNow =
        "${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}";
    String dateNow = thaiDate(today);

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
      debugPrint("Error fetching food notifications: $e");
    }

    // ---------------------------------------------------------
    // 2. แจ้งเตือนวัคซีน - เริ่มเตือนก่อนถึงกำหนด 3 วัน จนถึงวันที่ต้องทำ
    //    (รวมถึงเลยกำหนดแล้วด้วย) และซ่อนไปเลยถ้าให้วัคซีนไปแล้ว
    // ---------------------------------------------------------
    try {
      final coopResp = await http.get(Uri.parse('$backendBaseUrl/api/coops'));
      final alertResp = await http.get(
        Uri.parse('$backendBaseUrl/api/vaccines/alerts'),
      );

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

      if (alertResp.statusCode == 200) {
        final List<dynamic> alerts = jsonDecode(alertResp.body);

        for (final a in alerts) {
          if (a is! Map<String, dynamic>) continue;
          if (a['is_completed'] == true) continue; // ทำแล้ว ไม่ต้องเตือนอีก

          final dueDate = DateTime.tryParse(a['date']?.toString() ?? '');
          if (dueDate == null) continue;
          final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
          final daysUntil = dueOnly.difference(todayOnly).inDays;
          if (daysUntil > 3) continue; // ยังไม่เข้าเขตเตือนล่วงหน้า 3 วัน

          final coopId = a['coop_id']?.toString() ?? '-';
          final coopName = coopNames[coopId] ?? 'คอก $coopId';
          final vaccineName = a['vaccine_name']?.toString() ?? 'วัคซีน';

          String notiTitle;
          if (daysUntil < 0) {
            notiTitle =
                "‼️ เลยกำหนดให้ $vaccineName ที่ $coopName มา ${-daysUntil} วันแล้ว";
          } else if (daysUntil == 0) {
            notiTitle = "‼️ วันนี้ถึงกำหนดให้ $vaccineName ที่ $coopName";
          } else if (daysUntil == 1) {
            notiTitle = "💉 พรุ่งนี้ถึงกำหนดให้ $vaccineName ที่ $coopName";
          } else {
            notiTitle = "💉 อีก $daysUntil วันถึงกำหนดให้ $vaccineName ที่ $coopName";
          }

          newNotifications.add({
            "id": a['id'],
            "type": "vaccine",
            "title": notiTitle,
            "time": timeNow,
            "date": dateNow,
            "urgent": daysUntil <= 0,
            "daysUntil": daysUntil,
            "method": a['injection_type'] ?? '-',
            "chickenAge": a['chicken_age'] ?? 0,
            "note": a['description'] ?? '',
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching vaccine notifications: $e");
    }

    // เรียงลำดับ: เลยกำหนด/วันนี้ก่อน แล้วไล่ตามความเร่งด่วน
    newNotifications.sort((x, y) {
      final dx = x['daysUntil'] as int? ?? 999;
      final dy = y['daysUntil'] as int? ?? 999;
      return dx.compareTo(dy);
    });

    setState(() {
      notificationsList = newNotifications;
      isLoading = false;
    });
  }

  // 🌟 2. ฟังก์ชันจัดการเมื่อกดปุ่ม "เสร็จสิ้น" หรือ "รับทราบ"
  Future<void> _handleNotificationAction(
    int index,
    Map<String, dynamic> data,
  ) async {
    String type = data['type'];

    if (type == 'vaccine') {
      String id = data['id'].toString();
      try {
        await http.put(
          Uri.parse('$backendBaseUrl/api/vaccines/alerts?id=$id'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "is_completed": true,
            "method": data['method'] ?? '-',
            "chicken_age": data['chickenAge'] ?? 0,
            "note": data['note'] ?? '',
          }),
        );
      } catch (e) {
        debugPrint("Error updating vaccine status: $e");
      }
    }
    // type == 'food': ไม่มี endpoint สำหรับ "รับทราบ" การแจ้งเตือนสต็อก
    // แค่ปิดออกจากหน้าจอตอนนี้เท่านั้น (จะกลับมาเตือนใหม่ถ้ายังใกล้หมดอยู่ตอนโหลดหน้าใหม่)

    // ลบออกจากหน้าจอ
    setState(() {
      notificationsList.removeAt(index);
    });
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
        MaterialPageRoute(builder: (context) => const CloseOpenDoor()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Mainchicken()),
      );
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainShowDataFood()),
      );
    }
    setState(() {
      selectedIndex = index;
    });
  }

  // 🌟 3. UI การ์ดแจ้งเตือนแบบใหม่ - ไอคอนตามประเภท + ป้ายความเร่งด่วน
  Widget _buildNotificationCard(Map<String, dynamic> data, int index) {
    final ez = ezColors(context);
    String title = data["title"];
    String time = data["time"];
    String date = data["date"];
    String type = data["type"];
    bool isUrgent = data["urgent"] == true;

    final IconData icon = type == 'vaccine'
        ? Icons.vaccines_rounded
        : Icons.grass_rounded;
    final Color statusColor = isUrgent
        ? ez.danger
        : (type == 'vaccine' ? const Color(0xFFFFA726) : ez.gold);

    String buttonText = type == "food" ? "รับทราบ" : "เสร็จสิ้น";
    Color buttonColor = type == "food" ? Colors.blueAccent : ez.accentGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ezCardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: isUrgent
            ? Border.all(color: ez.danger.withValues(alpha: 0.5), width: 1.4)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.kanit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ez.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$date · $time',
                  style: GoogleFonts.kanit(
                    fontSize: 12,
                    color: ez.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => _handleNotificationAction(index, data),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: buttonColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        buttonText,
                        style: GoogleFonts.kanit(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBody: true,
      backgroundColor: ezBackgroundColor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(minHeight: screenHeight),
            child: Stack(
              children: [
                Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: EzHeader(pageTitle: 'การแจ้งเตือน'),
                    ),
                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: isLoading
                          ? Skeletonizer(
                              enabled: true,
                              child: Column(
                                children: List.generate(
                                  4,
                                  (i) => _buildNotificationCard({
                                    "title": "แจ้งเตือนตัวอย่าง",
                                    "time": "00:00",
                                    "date": "01/01/2026",
                                    "type": "task",
                                  }, i),
                                ),
                              ),
                            )
                          : notificationsList.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 30),
                                child: Text(
                                  "ไม่มีการแจ้งเตือน",
                                  style: GoogleFonts.kanit(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                ...notificationsList.asMap().entries.map((
                                  entry,
                                ) {
                                  int idx = entry.key;
                                  Map<String, dynamic> data = entry.value;
                                  return _buildNotificationCard(data, idx);
                                }),
                                const SizedBox(height: 100),
                              ],
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected,
      ),
    );
  }
}
