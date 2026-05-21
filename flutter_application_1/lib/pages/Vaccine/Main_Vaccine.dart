import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/Vaccine/Show_Datavaccine.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bottombar.dart';
import '../main_dash.dart'; 

// Import หน้า datavaccine เข้ามาด้วยเพื่อให้ Navigator รู้จัก
// สมมติว่าไฟล์ datavaccine.dart อยู่ที่เดียวกัน ถ้าคนละโฟลเดอร์ให้เปลี่ยน path ให้ถูกนะครับ

class MainVaccine extends StatefulWidget {
  const MainVaccine({super.key});

  @override
  State<MainVaccine> createState() => _MainVaccineState();
}

class _MainVaccineState extends State<MainVaccine> {
  int selectedIndex = 0; 

  void onTabSelected(int index) {
   if (index == 0) {
     Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else if(index == 3){
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Mainchicken()),
      );
    } else if(index == 4){
       Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainShowDataFood()),
      );
    } else if(index == 1){

      Navigator.pushReplacement(
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

  Widget _buildVaccineMethod({
    required IconData icon, 
    required String label, 
    required VoidCallback onTap,
    double iconSize = 38,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF9C6C7), 
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, size: iconSize, color: Colors.black),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 110, 
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
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
      backgroundColor: Colors.white, 
      body: Stack(
        children: [
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

          Positioned(
            top: 240, 
            left: 0,
            right: 0,
            bottom: 80,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCC850), 
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      "การให้วัคซีน",
                      style: GoogleFonts.kanit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 50), 

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVaccineMethod(
                        icon: Icons.vaccines, 
                        label: "แทงปีก", 
                        onTap: () {
                          // ตัวอย่างการส่งค่าไป
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const datavaccine(vaccineTypeFilter: "แทงปีก")),
                          );
                        }
                      ),
                      _buildVaccineMethod(
                        icon: Icons.medication, 
                        label: "ละลายน้ำกิน", 
                        onTap: () {
                          // *** ส่วนสำคัญ: ส่งพารามิเตอร์ 'ละลายน้ำดื่ม' ไปให้หน้า datavaccine ***
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const datavaccine(vaccineTypeFilter: "ละลายน้ำดื่ม")),
                          );
                        }
                      ),
                      _buildVaccineMethod(
                        icon: Icons.sanitizer, 
                        label: "พ่นละออง", 
                        onTap: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const datavaccine(vaccineTypeFilter: "พ่นละออง")),
                          );
                        }
                      ),
                    ],
                  ),

                  const SizedBox(height: 40), 

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVaccineMethod(
                        icon: Icons.water_drop, 
                        label: "หยอดตา/จมูก/ปาก", 
                        onTap: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const datavaccine(vaccineTypeFilter: "หยอดตา/จมูก/ปาก")),
                          );
                        }
                      ),
                      _buildVaccineMethod(
                        icon: Icons.biotech, 
                        label: "ฉีดเข้ากล้ามเนื้อ\n(อก/ขา)", 
                        onTap: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const datavaccine(vaccineTypeFilter: "ฉีดเข้ากล้ามเนื้อ")),
                          );
                        }
                      ),
                    ],
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),

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