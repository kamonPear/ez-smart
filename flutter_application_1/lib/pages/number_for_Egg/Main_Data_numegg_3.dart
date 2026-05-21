import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart'; 
import '../bottombar.dart'; 
import 'Edit_NumberEggchicken_3.dart';
import 'Add_NumberEggchicken_3.dart';

class Datanumegg extends StatefulWidget {
  const Datanumegg({super.key});

  @override
  State<Datanumegg> createState() => _DatanumeggState();
}

class _DatanumeggState extends State<Datanumegg> {
  int selectedIndex = 0;

  // 🌟 1. เพิ่ม List เก็บข้อมูลไข่ไก่
  List<Map<String, String>> eggDataList = [
    {
      "id": "EG-001",
      "date": "25 / 06 / 2568",
      "count": "78 ฟอง",
      "note": "-",
    },
    {
      "id": "EG-002",
      "date": "25 / 06 / 2568",
      "count": "78 ฟอง",
      "note": "แตก 2 ฟอง",
    },
    {
      "id": "EG-003",
      "date": "26 / 06 / 2568",
      "count": "80 ฟอง",
      "note": "ปกติ",
    }
  ];

  void onTabSelected(int index) {
    if(index == 0){
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }else if(index == 4){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainShowDataFood()),
      );
    }else if(index == 1){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CloseOpenDoor()),
      );
    }else if(index == 3){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Mainchicken()),
      );
    }else if(index == 2){
       Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ShowChart()),
      );
    }
    else{
      setState(() {
        selectedIndex = index;
      });
    }
  }

  // --- Helper 1: สร้างปุ่มเล็ก ---
  Widget _buildSmallButton(String text, Color bgColor, Color textColor, {double fontSize = 12, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap, 
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.kanit(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  // --- Helper 2: สร้างแถวแสดงข้อมูล ---
  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: GoogleFonts.kanit(
                fontSize: 15,
                fontWeight: FontWeight.w800, 
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F0F0), 
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                value,
                style: GoogleFonts.kanit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper 3: สร้างการ์ดข้อมูลไข่ไก่ ---
  Widget _buildEggCard({
    required int index, // 🌟 รับ index มาเพื่อใช้จัดการการลบและแก้ไข
    required String title,
    required String id,
    required String date,
    required String count,
    required String note, 
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFB4D3E5), 
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.kanit(
                  fontSize: 20,
                  fontWeight: FontWeight.w900, 
                ),
              ),
              _buildSmallButton(
                "ดูกราฟการเก็บไข่", 
                const Color(0xFFD33636), 
                Colors.white, 
                fontSize: 14,
                onTap: () {
                  // 🌟 เพิ่มคำสั่งเปลี่ยนหน้าไปที่ ShowChart ตรงนี้
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ShowChart()),
                  );
                },
              ), 
            ],
          ),
          const SizedBox(height: 15),
          
          _buildDataRow("รหัสการเก็บไข่ :", id),
          _buildDataRow("วันที่เก็บ :", date),
          _buildDataRow("จำนวนไข่ :", count),
          _buildDataRow("หมายเหตุ :", note),
          
          const SizedBox(height: 5),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildSmallButton(
                "แก้ไขข้อมูล", 
                const Color(0xFFEEDD44), 
                Colors.white,
                onTap: () async {
                  // 🌟 2. ส่งข้อมูลเดิมไปที่หน้า แก้ไข
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditNumbereggchicken(
                        initialData: {
                          "id": id,
                          "date": date,
                          "count": count,
                          "note": note,
                        },
                      ),
                    ),
                  );

                  // ถ้ารับข้อมูลที่แก้เสร็จกลับมาแล้ว ให้อัปเดต
                  if (result != null && result is Map<String, String>) {
                    setState(() {
                      eggDataList[index] = result;
                    });
                  }
                },
              ), 
              const SizedBox(width: 8),
              _buildSmallButton(
                "ลบข้อมูล", 
                const Color(0xFFFF0000), 
                Colors.white,
                onTap: () {
                  // 🌟 3. ระบบยืนยันการลบ
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('ยืนยันการลบ', style: GoogleFonts.kanit()),
                        content: Text('คุณต้องการลบข้อมูลการเก็บไข่รายการนี้ใช่หรือไม่?', style: GoogleFonts.kanit()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('ยกเลิก', style: GoogleFonts.kanit()),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                eggDataList.removeAt(index);
                              });
                              Navigator.of(context).pop();
                            },
                            child: Text('ลบ', style: GoogleFonts.kanit(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );
                }
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
      backgroundColor: const Color(0xFFE8F2F8),
      body: Scrollbar(
        thumbVisibility: true,
        thickness: 6.0,
        radius: const Radius.circular(10),
        child: SingleChildScrollView(
          child: Stack(
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
              
              SafeArea(
                child: Column(
                  children: [
                    // --- Header ---
                   // --- ส่วน Header (Logo & Text) ---
Container(
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
            Icons.notifications_active, // ไอคอนกระดิ่งสีดำทึบ
            color: Colors.black87,
            size: 32,
          ),
        ),
      ),
    ],
  ),
),
                    
                    // --- การ์ดเนื้อหา ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 20), 

                          // 🌟 4. ลูปข้อมูลจาก List ออกมาสร้าง Card
                          ...eggDataList.asMap().entries.map((entry) {
                            int index = entry.key;
                            Map<String, String> data = entry.value;
                            return _buildEggCard(
                              index: index,
                              title: "ข้อมูลการเก็บไข่ ที่ ${index + 1}",
                              id: data['id']!,
                              date: data['date']!,
                              count: data['count']!,
                              note: data['note']!,
                            );
                          }).toList(),
                          
                          const SizedBox(height: 10),

                          // ปุ่ม "เพิ่มข้อมูล" 
                          GestureDetector(
                            onTap: () async {
                              // 🌟 5. รอรับค่าจากการเพิ่มข้อมูล
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddNumbereggchicken(),
                                ),
                              );

                              if (result != null && result is Map<String, String>) {
                                setState(() {
                                  eggDataList.add(result);
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
                          
                          const SizedBox(height: 100), 
                        ],
                      ),
                    ),
                  ],
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