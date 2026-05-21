import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bottombar.dart'; 

class CloseOpenDoor extends StatefulWidget {
  const CloseOpenDoor({super.key});

  @override
  State<CloseOpenDoor> createState() => _CloseOpenDoorState();
}

class _CloseOpenDoorState extends State<CloseOpenDoor> {
  int selectedIndex = 1;

  // 1. เปลี่ยนมาใช้ List of Maps เพื่อให้จำ ID ของประตูได้ และมีสถานะติ๊กเลือก (selected)
  List<Map<String, dynamic>> doors = List.generate(5, (index) => {
    "id": index + 1,
    "isOn": false,
    "selected": false,
  });
  
  int nextDoorId = 6; // ตัวแปรจำหมายเลขประตูบานถัดไปที่จะเพิ่ม
  bool isDeleteMode = false; // สถานะเช็คว่ากำลังอยู่ในโหมดลบหรือไม่

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

  // ฟังก์ชันเพิ่มประตูใหม่
  void _addNewDoor() {
    setState(() {
      doors.add({
        "id": nextDoorId++,
        "isOn": false,
        "selected": false,
      });
    });
  }

  // 2. ฟังก์ชันลบประตูที่ถูกติ๊กเลือก
  void _deleteSelectedDoors() {
    setState(() {
      // ลบข้อมูลที่ selected == true ออกจาก List
      doors.removeWhere((door) => door["selected"] == true);
      isDeleteMode = false; // ปิดโหมดลบเมื่อทำเสร็จ
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      
      body: SingleChildScrollView(
        child: Stack(
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

            // --- ส่วนที่ 2: เนื้อหา (Header + Search + รายการ) ---
            Column(
              children: [
                const SizedBox(height: 270), 

                // 2.2: ช่อง Search และปุ่มโหมดลบ
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10),
                  child: Row(
                    children: [
                      // ช่อง Search
                      Expanded(
                        child: Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: TextField(
                            style: GoogleFonts.kanit(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'SEARCH',
                              hintStyle: GoogleFonts.kanit(color: Colors.grey[600]),
                              prefixIcon: const Icon(Icons.search, color: Colors.black54),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      
                      // 3. ปุ่มเปิด-ปิด โหมดลบ
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isDeleteMode = !isDeleteMode;
                            // ถ้าออกจากโหมดลบ ให้เคลียร์การติ๊กเลือกทั้งหมด
                            if (!isDeleteMode) {
                              for (var door in doors) {
                                door["selected"] = false;
                              }
                            }
                          });
                        },
                        child: Container(
                          height: 45,
                          width: 45,
                          decoration: BoxDecoration(
                            color: isDeleteMode ? Colors.grey : const Color.fromARGB(255, 172, 24, 24),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Icon(
                            isDeleteMode ? Icons.close : Icons.delete_outline,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2.3: รายการสวิตช์
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // วนลูปสร้างรายการประตูจาก List of Maps
                      for (int i = 0; i < doors.length; i++)
                        _buildDoorControlTile(doors[i], i),
                      
                      const SizedBox(height: 100), 
                    ],
                  ),
                ),
              ],
            ),

            // --- ส่วนที่ 3: Header (Logo & Text) ---
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

      // 4. สลับปุ่ม FAB ตามโหมดที่กำลังใช้งาน (โหมดปกติ = เพิ่มประตู / โหมดลบ = ยืนยันลบ)
      floatingActionButton: isDeleteMode
          ? FloatingActionButton.extended(
              onPressed: _deleteSelectedDoors,
              backgroundColor: Colors.red,
              icon: const Icon(Icons.delete, color: Colors.white),
              label: Text(
                "ลบที่เลือก",
                style: GoogleFonts.kanit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : FloatingActionButton(
              onPressed: () {
                _addNewDoor();
                print("กดปุ่มเพิ่มประตู: จำนวนปัจจุบัน ${doors.length}");
              },
              backgroundColor: const Color.fromARGB(255, 172, 24, 24), 
              elevation: 4,
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: CustomBottomBar(
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected,
      ),
    );
  }

  // ฟังก์ชันสร้าง UI สำหรับแต่ละประตู
  Widget _buildDoorControlTile(Map<String, dynamic> door, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6E6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // 5. แสดง Checkbox เมื่ออยู่ในโหมดลบ
              if (isDeleteMode)
                Checkbox(
                  value: door["selected"],
                  activeColor: Colors.red,
                  onChanged: (bool? value) {
                    setState(() {
                      door["selected"] = value ?? false;
                    });
                  },
                ),
              Text(
                'ประตูคอกไก่ที่ ${door["id"]}',
                style: GoogleFonts.kanit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Row(
                children: [
                  Text("OFF ", style: GoogleFonts.kanit(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                  Text("ON", style: GoogleFonts.kanit(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 30,
                child: Switch(
                  value: door["isOn"],
                  activeColor: Colors.white,
                  activeTrackColor: Colors.black,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.black,
                  trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
                  onChanged: (bool value) {
                    setState(() {
                      door["isOn"] = value;
                      print("ประตูที่ ${door["id"]} สถานะ: ${value ? 'เปิด' : 'ปิด'}");
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}