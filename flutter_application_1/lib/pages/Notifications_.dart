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

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  int selectedIndex = 0;
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
    
    String timeNow = "${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}";
    String dateNow = "${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year + 543}";

    // ---------------------------------------------------------
    // 1. แจ้งเตือนปริมาณอาหาร (ใกล้หมด / หมดแล้ว)
    // ---------------------------------------------------------
    try {
      final response = await http.get(Uri.parse('$backendBaseUrl/api/foods?id=1'));
      
      if (response.statusCode == 200 && response.body.isNotEmpty && response.body != 'null') {
        final decoded = jsonDecode(response.body);
        
        if (decoded != null && decoded is Map<String, dynamic>) {
          double currentQuantity = (decoded['quantity_current'] as num?)?.toDouble() ?? 0.0;
          double minQuantity = (decoded['min_quantity'] as num?)?.toDouble() ?? 0.0;
          int foodId = decoded['id'] ?? 1; // ดึง ID อาหาร
          
          if (currentQuantity <= 0.0) {
            newNotifications.add({
              "id": foodId,
              "type": "food",
              "title": "🚨 อาหารหมดแล้ว! กรุณาเติมอาหารด่วน",
              "time": timeNow,
              "date": dateNow,
            });
          } 
          else if (currentQuantity <= minQuantity) {
            newNotifications.add({
              "id": foodId,
              "type": "food",
              "title": "⚠️ อาหารใกล้หมด! (เหลือ ${currentQuantity.toStringAsFixed(2)} กก.)",
              "time": timeNow,
              "date": dateNow,
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching food notifications: $e");
    }

    // ---------------------------------------------------------
    // 2. แจ้งเตือนวัคซีน 
    // ---------------------------------------------------------
    try {
      final responseVaccine = await http.get(Uri.parse('$backendBaseUrl/api/notifications/vaccines'));
      
      if (responseVaccine.statusCode == 200 && responseVaccine.body.isNotEmpty && responseVaccine.body != 'null') {
        final decoded = jsonDecode(responseVaccine.body);
        
        if (decoded is List) {
          for (var v in decoded) {
            if (v is Map<String, dynamic>) {
              // 🌟 สำคัญ: ดึง ID ของวัคซีนมาด้วย เพื่อใช้ตอนอัปเดตสถานะ
              int id = v['id'] ?? v['vaccine_id'] ?? 0; 
              String vaccineName = v['name'] ?? 'วัคซีน';
              String coopName = v['coop_name'] ?? 'ไม่ระบุคอก';
              bool isToday = v['is_today'] ?? false; 

              String notiTitle = isToday 
                  ? "‼️ วันนี้ถึงกำหนดให้ $vaccineName ที่ $coopName"
                  : "💉 พรุ่งนี้มีคิวให้ $vaccineName ที่ $coopName";

              newNotifications.add({
                "id": id,
                "type": "vaccine", // ระบุประเภท
                "title": notiTitle,
                "time": timeNow, 
                "date": dateNow,
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching vaccine notifications: $e");
    }

    // ---------------------------------------------------------
    // 3. แจ้งเตือนตรวจสุขภาพ 
    // ---------------------------------------------------------
    try {
      final responseHealth = await http.get(Uri.parse('$backendBaseUrl/api/notifications/health_checks'));
      
      if (responseHealth.statusCode == 200 && responseHealth.body.isNotEmpty && responseHealth.body != 'null') {
        final decoded = jsonDecode(responseHealth.body);
        
        if (decoded is List) {
          for (var h in decoded) {
            if (h is Map<String, dynamic>) {
              int id = h['id'] ?? h['check_id'] ?? 0;
              String coopName = h['coop_name'] ?? 'ไม่ระบุคอก';
              bool isToday = h['is_today'] ?? false; 

              String notiTitle = isToday 
                  ? "🩺 วันนี้คอกไก่ที่ $coopName ต้องตรวจสุขภาพ"
                  : "🩺 พรุ่งนี้ถึงคอกไก่ที่ $coopName ต้องตรวจสุขภาพแล้ว";

              newNotifications.add({
                "id": id,
                "type": "health", // ระบุประเภท
                "title": notiTitle,
                "time": timeNow, 
                "date": dateNow,
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching health check notifications: $e");
    }

    setState(() {
      notificationsList = newNotifications;
      isLoading = false;
    });
  }

  // 🌟 2. ฟังก์ชันจัดการเมื่อกดปุ่ม "เสร็จสิ้น" หรือ "ลบ"
  Future<void> _handleNotificationAction(int index, Map<String, dynamic> data) async {
    String type = data['type'];
    int id = data['id'];

    if (type == 'vaccine') {
      // 💡 ส่งข้อมูลไปบอก Backend ว่าทำรายการนี้เสร็จแล้ว (ปรับ URL ให้ตรงกับ Backend ของคุณ)
      try {
        await http.put(Uri.parse('$backendBaseUrl/api/vaccines/complete/$id'));
      } catch (e) {
        debugPrint("Error updating vaccine status: $e");
      }
    } else if (type == 'health') {
      // 💡 ส่งข้อมูลไปบอก Backend ว่าตรวจสุขภาพเสร็จแล้ว (ปรับ URL ให้ตรงกับ Backend ของคุณ)
      try {
        await http.put(Uri.parse('$backendBaseUrl/api/health_checks/complete/$id'));
      } catch (e) {
        debugPrint("Error updating health check status: $e");
      }
    }

    // ลบออกจากหน้าจอ
    setState(() {
      notificationsList.removeAt(index);
    });
  }

  void onTabSelected(int index) {
    if(index == 0){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
    } else if(index == 1){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CloseOpenDoor()));
    } else if(index == 3){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Mainchicken()));
    } else if (index == 4) {
       Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainShowDataFood()));
    }
    setState(() {
      selectedIndex = index;
    });
  }

  // 🌟 3. ปรับ UI ของการ์ดให้รับ Parameter แบบ Map
  Widget _buildNotificationCard(Map<String, dynamic> data, int index) {
    String title = data["title"];
    String time = data["time"];
    String date = data["date"];
    String type = data["type"];
    
    bool isUrgent = title.contains("อาหารหมดแล้ว");

    // กำหนดข้อความและสีของปุ่มตามประเภท
    String buttonText = type == "food" ? "รับทราบ" : "เสร็จสิ้น";
    Color buttonColor = type == "food" ? Colors.blueAccent : const Color(0xFF4CAF50); // สีเขียวสำหรับปุ่มเสร็จสิ้น

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUrgent ? const Color(0xFF3A2020) : ezCardColor,
        borderRadius: BorderRadius.circular(20),
        border: isUrgent ? Border.all(color: Colors.redAccent.withOpacity(0.5), width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.kanit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isUrgent ? const Color(0xFFFF8A80) : Colors.white,
                  ),
                ),
              ),
              Text(
                time,
                style: GoogleFonts.kanit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: GoogleFonts.kanit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              GestureDetector(
                onTap: () => _handleNotificationAction(index, data),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
            ],
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
      backgroundColor: ezBackgroundColor,
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
                      ? const Center(child: CircularProgressIndicator())
                      : notificationsList.isEmpty 
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 30),
                              child: Text(
                                "ไม่มีการแจ้งเตือน",
                                style: GoogleFonts.kanit(fontSize: 16, color: Colors.grey),
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              ...notificationsList.asMap().entries.map((entry) {
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