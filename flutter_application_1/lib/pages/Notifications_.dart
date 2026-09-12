import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Chicken_health_information/Main_HealthCheckCalendar.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Main_SenSor/Main_DeviceSummary.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bottombar.dart';
import '../../services/backend_config.dart';
import '../../services/notifications_service.dart';
import '../widgets/ez_header.dart';
import 'package:skeletonizer/skeletonizer.dart';

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

    final newNotifications = await loadNotifications();

    setState(() {
      notificationsList = newNotifications;
      isLoading = false;
    });
  }

  // 🌟 2. ฟังก์ชันจัดการเมื่อกดปุ่ม "เสร็จสิ้น" / "รับทราบ" / "ไปตรวจสุขภาพ"
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
    } else if (type == 'health') {
      // ไปหน้าปฏิทินตรวจสุขภาพของคอกนั้นให้กรอกผลตรวจจริง แล้วรีเฟรชรายการทั้งหมด
      // (ไม่ตัดออกจากรายการทันที เผื่อผู้ใช้กดแล้วไม่ได้กรอกจริง)
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MainHealthCheckCalendar(
            coopId: data['coopId']?.toString() ?? '',
            coopName: data['coopName']?.toString() ?? '-',
          ),
        ),
      );
      _fetchAndCheckNotifications();
      return;
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
        MaterialPageRoute(builder: (context) => const MainDeviceSummary()),
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
        : (type == 'health'
              ? Icons.medical_information_outlined
              : Icons.grass_rounded);
    final Color statusColor = isUrgent
        ? ez.danger
        : (type == 'vaccine' || type == 'health'
              ? const Color(0xFFFFA726)
              : ez.gold);

    String buttonText = type == "food"
        ? "รับทราบ"
        : (type == "health" ? "ไปตรวจสุขภาพ" : "เสร็จสิ้น");
    Color buttonColor = type == "food"
        ? Colors.blueAccent
        : (type == "health" ? const Color(0xFFFFA726) : ez.accentGreen);

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
    final mediaQuery = MediaQuery.of(context);
    double minContentHeight =
        mediaQuery.size.height - mediaQuery.viewInsets.bottom;

    return Scaffold(
      extendBody: true,
      backgroundColor: ezBackgroundColor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(minHeight: minContentHeight),
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
