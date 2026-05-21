import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_Datadopt_chicken_2.dart';
import 'package:flutter_application_1/pages/Main_SenSor/Data_Sensor.dart';
import 'package:flutter_application_1/pages/Main_SenSor/Data_System.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/Vaccine/Main_Vaccine.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Chicken_health_information/Show_Chicken_health.dart';
import '../bottombar.dart';
import '../main_dash.dart'; 
import '../number_for_Egg/Main_Data_numegg_3.dart'; 



class Mainchicken extends StatefulWidget {
  const Mainchicken({super.key});

  @override
  State<Mainchicken> createState() => _MainchickenState();
}

class _MainchickenState extends State<Mainchicken> {
  // ควบคุมว่าตอนนี้อยู่แท็บไหน (สมมติให้หน้านี้คือหน้าหลักที่ไม่ได้ผูกกับ index หรือเป็นหน้าย่อย)
  int selectedIndex = 0; 

  void onTabSelected(int index) {
    if (index == 0) {
      // Logic: กลับหน้า Home (MainScreen)
      // ใช้ pushReplacement เพื่อไม่ให้หน้าซ้อนกัน
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else if (index == 4) {
      // Logic: ไปหน้า Main_DataFood_chicken1 (แท็บอาหาร)
      // ใช้ pushReplacement แทน push ปกติ 
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainShowDataFood()),
      );
    } else if(index == 1){
      // Logic: ไปหน้า CloseOpenDoor (แท็บประตู)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CloseOpenDoor()),
      );
    }else if(index == 2){
       Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ShowChart()),
      );
    }
     else {
      setState(() {
        selectedIndex = index;
      });
    }
  }

  // --- ฟังก์ชันสร้างปุ่มเมนู ---
  Widget _buildMenuItem(String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F0F0),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.kanit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.black,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // --- ส่วนที่ 1: ภาพพื้นหลัง ---
          Container(
            height: screenHeight,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/back1.png'),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),

          // --- ส่วนที่ 2: เนื้อหา ---
          Positioned(
            top: 280,
            left: 0,
            right: 0,
            bottom: 80,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // 2.1 Search Bar
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAE5E5),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: "SEARCH",
                        hintStyle: GoogleFonts.kanit(
                          color: const Color(0xFF8A7E7E),
                          fontWeight: FontWeight.bold,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                        suffixIcon: const Icon(Icons.search, color: Colors.black87, size: 28),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),


                  _buildMenuItem("แฟ้มข้อมูลคอก", () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Adoptchicken()),
                    );
                  }),

                  // 2.2 รายการปุ่มเมนู
                  _buildMenuItem("แฟ้มข้อมูลการเก็บไข่", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Datanumegg()),
                    );
                  }),

                  _buildMenuItem("แฟ้มข้อมูลการบันทึกสุขภาพ", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Chickenhealth()),
                    );
                  }),

                  _buildMenuItem("แฟ้มข้อมูลการบันทึกอุปกรณ์", () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DataSystem()),
                    );
                  }),

                   _buildMenuItem("แฟ้มข้อมูลเซนเซอร์", () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Datasensor()),
                    );
                  }),

                  _buildMenuItem("แฟ้มข้อมูลการให้วัคซีน", () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MainVaccine()),
                    );
                  }),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),

          // --- ส่วนที่ 3: Header ---
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

      bottomNavigationBar: CustomBottomBar(
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected,
      ),
    );
  }
}