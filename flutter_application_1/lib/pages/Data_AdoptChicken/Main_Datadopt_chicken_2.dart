import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bottombar.dart'; 
import 'Main_Dataadd_adopt2.dart';
import 'Main_EditData_adoptchicken2.dart'; 

class Adoptchicken extends StatefulWidget {
  const Adoptchicken({super.key});

  @override
  State<Adoptchicken> createState() => _AdoptchickenState();
}

class _AdoptchickenState extends State<Adoptchicken> {
  int selectedIndex = 0;

  // 🌟 เพิ่ม List เก็บข้อมูลคอกไก่
  List<Map<String, String>> coopDataList = [
    {
      "id": "KC001",
      "importDate": "25 / 07 / 2568",
      "count": "100 ตัว",
      "birthDate": "01 / 07 / 2568",
      "note": "-",
    },
    {
      "id": "KC002",
      "importDate": "25 / 07 / 2568",
      "count": "100 ตัว",
      "birthDate": "01 / 07 / 2568",
      "note": "-",
    }
  ];

  void onTabSelected(int index) {
     if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else if(index == 4){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainShowDataFood()),
      );
    } else if(index == 3){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Mainchicken()),
      );
    } else if(index == 1){
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

  // 🌟 Helper: สร้างแถวแสดงข้อมูล
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: GoogleFonts.kanit(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: GoogleFonts.kanit(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 Helper: สร้างปุ่ม Action (แก้ไข/ลบ)
  Widget _buildActionButton(String text, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.kanit(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  // ปรับแต่ง UI ของ Card (เพิ่ม index เพื่อให้รู้ว่ากำลังจัดการการ์ดใบไหน)
  Widget _buildCoopCard({
    required int index, // 🌟 เพิ่มพารามิเตอร์ index
    required String title,
    required String id,
    required String importDate, 
    required String count,
    required String birthDate, 
    required String note, 
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF90B8D4),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black54, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.kanit(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 15),
          
          _buildInfoRow("รหัสคอกไก่ :", id),
          _buildInfoRow("วันที่นำเข้าเลี้ยง :", importDate),
          _buildInfoRow("จำนวนไก่ :", count),
          _buildInfoRow("วันเกิดไก่ลอตนั้น :", birthDate),
          _buildInfoRow("หมายเหตุ :", note),
          
          const SizedBox(height: 10),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // ปุ่มแก้ไขข้อมูล
              GestureDetector(
                onTap: () async {
                  // 🌟 ส่งข้อมูลเดิมไปให้หน้า แก้ไข
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditDataAdoptchicken(
                        initialData: {
                          "id": id,
                          "importDate": importDate,
                          "count": count,
                          "birthDate": birthDate,
                          "note": note,
                        },
                      ),
                    ),
                  );

                  // 🌟 ถ้ารับค่ากลับมาแล้ว ให้อัปเดตข้อมูลตำแหน่งเดิม
                  if (result != null && result is Map<String, String>) {
                    setState(() {
                      coopDataList[index] = result;
                    });
                  }
                },
                child: _buildActionButton("แก้ไขข้อมูล", const Color(0xFFF1C40F)), 
              ),
              
              const SizedBox(width: 10),
              
              // ปุ่มลบข้อมูล
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('ยืนยันการลบ', style: GoogleFonts.kanit()),
                        content: Text('คุณต้องการลบข้อมูลคอกนี้ใช่หรือไม่?', style: GoogleFonts.kanit()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('ยกเลิก', style: GoogleFonts.kanit()),
                          ),
                          TextButton(
                            onPressed: () {
                              // 🌟 กดลบแล้ว ให้เอาข้อมูลออกจาก List ตาม index
                              setState(() {
                                coopDataList.removeAt(index);
                              });
                              Navigator.of(context).pop();
                            },
                            child: Text('ลบ', style: GoogleFonts.kanit(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: _buildActionButton("ลบข้อมูล", const Color(0xFFFF0000)), 
              ),
            ],
          )
        ],
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
            top: 245, 
            left: 0,
            right: 0,
            bottom: 80,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  const SizedBox(height: 60), 

                  // 🌟 ลูปสร้างการ์ดจากข้อมูลใน List พร้อมส่ง index ไปด้วย
                  ...coopDataList.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, String> data = entry.value;
                    return _buildCoopCard(
                      index: index, // 🌟 ส่ง index ไป
                      title: "ข้อมูลไก่คอก ที่ ${index + 1}",
                      id: data['id']!,
                      importDate: data['importDate']!,
                      count: data['count']!,
                      birthDate: data['birthDate']!,
                      note: data['note']!,
                    );
                  }).toList(),

                  const SizedBox(height: 20),

                  // ปุ่มเพิ่มข้อมูล
                  GestureDetector( 
                    onTap: () async {
                      // รอรับค่าที่ส่งกลับมาจากหน้า AddDataadopt
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddDataadopt()), 
                      );
                      
                      // ถ้ารับค่ามาแล้วมีข้อมูล ให้เพิ่มเข้า List และอัปเดตหน้าจอ
                      if (result != null && result is Map<String, String>) {
                        setState(() {
                          coopDataList.add(result);
                        });
                      }
                    },
                    child: Container(
                      width: 200,
                      height: 55,
                      decoration: BoxDecoration(
                        color: const Color(0xFF98E688),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "เพิ่มข้อมูล",
                          style: GoogleFonts.kanit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              const Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black26),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
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