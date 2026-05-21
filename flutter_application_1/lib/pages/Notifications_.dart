import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'bottombar.dart'; 

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  int selectedIndex = 0;

  void onTabSelected(int index) {

    if(index == 0){
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else if(index == 1){
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CloseOpenDoor()),
      );
    } else if(index == 3){
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

  // ฟังก์ชันสำหรับสร้างการ์ดแจ้งเตือนแต่ละอัน
  Widget _buildNotificationCard(String title, String time, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15), 
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0), 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // บรรทัดบน: ข้อความแจ้งเตือน + เวลา
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
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                time,
                style: GoogleFonts.kanit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20), // เว้นระยะห่างกลางกล่อง
          
          // บรรทัดล่าง: วันที่ + ปุ่มลบ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: GoogleFonts.kanit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              // ปุ่มลบ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF5350), // สีแดงอมชมพู
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  'ลบ',
                  style: GoogleFonts.kanit(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
      backgroundColor: Colors.white, // เผื่อเลื่อนจนสุดรูปจะได้เห็นพื้นหลังสีขาว

      // 1. ครอบเนื้อหาทั้งหมดด้วย SingleChildScrollView
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // บังคับให้เลื่อนได้เสมอ
        child: Container(
          // 2. ล็อคความสูงขั้นต่ำให้เท่ากับหน้าจอ และย้ายรูปมาไว้ตรงนี้
          constraints: BoxConstraints(minHeight: screenHeight),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/back1.png'),
              fit: BoxFit.fitWidth, // ให้ภาพขยายพอดีความกว้าง
              alignment: Alignment.topCenter,
            ),
          ),
          child: Stack(
            children: [
              // --- ส่วนที่ 2: เนื้อหา (รายการแจ้งเตือน) ---
              // เปลี่ยนจาก Positioned + ListView เป็น Column ธรรมดา
              Column(
                children: [
                  // ดันเนื้อหาลงมาให้อยู่ใต้ Header พอดี (ปรับเป็น 240 เพื่อหลบส่วนโค้ง)
                  const SizedBox(height: 270), 

                  // หัวข้อ "การแจ้งเตือน" ตรงกลาง
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300], 
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))
                      ]
                    ),
                    child: Text(
                      "การแจ้งเตือน",
                      style: GoogleFonts.kanit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[400], 
                      ),
                    ),
                  ),

                  // รายการ List แจ้งเตือน
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildNotificationCard("อาหารในคลังใกล้หมดแล้ว", "15:35", "28/06/68"),
                        _buildNotificationCard("มีการเคลื่อนไหวอยู่หน้าคอกไก ที่ 1", "18:44", "30/06/68"),
                        _buildNotificationCard("ประตูปิดไม่สนิท", "19:15", "30/06/68"),
                        _buildNotificationCard("ใกล้ค่ำแล้วถึงเวลาปิดไฟ", "17:30", "31/06/68"),
                        
                        // เว้นระยะด้านล่างสุดไม่ให้ BottomBar ทับเนื้อหา
                        const SizedBox(height: 100), 
                      ],
                    ),
                  ),
                ],
              ),

              // --- ส่วนที่ 3: Header (Logo + ข้อความ) ---
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    height: 160,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 120,
                            height: 120,
                          ),
                        ),
                        // 👇 ปรับข้อความและขนาดฟอนต์ให้เหมือนในรูป
                        Positioned(
                          left: 135,
                          top: 25,
                          child: Text(
                            'EZ -\nSMART\nFARM',
                            style: GoogleFonts.kanit(
                              fontSize: 28,
                              height: 1.1,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 252, 250, 250),
                            ),
                          ),
                        ),
                        // 👇 ปรับไอคอนกระดิ่งเป็นสีดำและนำไอคอนขีดๆ ออก
                        Positioned(
                          right: 0,
                          bottom: 20,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const Notifications()),
                              );
                            },
                            child: const Icon(
                              Icons.notifications_active,
                              color: Colors.black87,
                              size: 32,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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