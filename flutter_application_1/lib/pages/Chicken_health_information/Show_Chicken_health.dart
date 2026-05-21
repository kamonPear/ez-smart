import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart'; 
import '../bottombar.dart'; 
import 'Edit_Datachicken_health.dart'; // ตรวจสอบชื่อไฟล์ import ให้ตรงกับของคุณ
import 'Add_Datachicken_health.dart';

class Chickenhealth extends StatefulWidget {
  const Chickenhealth({super.key});

  @override
  State<Chickenhealth> createState() => _ChickenhealthState();
}

class _ChickenhealthState extends State<Chickenhealth> {
  int selectedIndex = 0; // สมมติว่าหน้านี้คือ index 0 หรือปรับตามที่คุณตั้งไว้

  // 🌟 1. สร้าง List เก็บข้อมูลการตรวจสุขภาพ
  List<Map<String, String>> healthDataList = [
    {
      "recordId": "REC001",
      "healthyCount": "98",
      "sickCount": "2",
      "inspectionDate": "27 / 04 / 2569",
    },
    {
      "recordId": "REC002",
      "healthyCount": "95",
      "sickCount": "5",
      "inspectionDate": "27 / 04 / 2569",
    }
  ];

  void onTabSelected(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else if(index == 1){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CloseOpenDoor()),
      );
    } else if(index == 3){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Mainchicken()),
      );
    } else if(index == 4){
      Navigator.push(
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

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBody: true, 
      backgroundColor: Colors.white, 

      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), 
        child: Container(
          constraints: BoxConstraints(minHeight: screenHeight),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/back1.png'),
              fit: BoxFit.fitWidth, 
              alignment: Alignment.topCenter,
            ),
          ),
          child: Stack(
            children: [
              // --- ส่วนที่ 2: เนื้อหาหลัก (Column) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 270), 
                    
                    // 🌟 2. ใช้ .map() ดึงข้อมูลจาก List มาสร้างการ์ด
                    ...healthDataList.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, String> data = entry.value;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: CoopDataCard(
                          recordNumber: '${index + 1}',
                          recordId: data['recordId']!,
                          healthyCount: data['healthyCount']!,
                          sickCount: data['sickCount']!,
                          inspectionDate: data['inspectionDate']!,
                          // ฟังก์ชันเมื่อกดแก้ไข
                          onEdit: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Editckickenhealth(
                                  initialData: data, // ส่งข้อมูลเดิมไป
                                ),
                              ),
                            );

                            // ถ้ารับค่าใหม่กลับมา ให้แทนที่ข้อมูลเดิม
                            if (result != null && result is Map<String, String>) {
                              setState(() {
                                healthDataList[index] = result;
                              });
                            }
                          },
                          // ฟังก์ชันเมื่อกดลบ
                          onDelete: () {
                            setState(() {
                              healthDataList.removeAt(index);
                            });
                          },
                        ),
                      );
                    }).toList(),
                    
                    const SizedBox(height: 15), 

                    // 👇 ปุ่ม "เพิ่มข้อมูล"
                    GestureDetector(
                      onTap: () async {
                        // 🌟 3. รอรับค่าจากหน้า Add
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddDatachickenHealth()), 
                        );

                        // ถ้ามีข้อมูลส่งกลับมา ให้เพิ่มลง List
                        if (result != null && result is Map<String, String>) {
                          setState(() {
                            healthDataList.add(result);
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 40),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9DE088), 
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          'เพิ่มข้อมูล',
                          style: GoogleFonts.kanit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 120), // เผื่อระยะด้านล่างไม่ให้ปุ่มบัง BottomBar
                  ],
                ),
              ),

              // --- ส่วนที่ 3: Header (Logo + Icons) ---
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

// --- การ์ดข้อมูลคอกไก่ ---
class CoopDataCard extends StatelessWidget {
  final String recordNumber;
  final String recordId;
  final String healthyCount;
  final String sickCount;
  final String inspectionDate;
  final VoidCallback onEdit; // 🌟 เพิ่ม Callback สำหรับแก้ไข
  final VoidCallback onDelete; // 🌟 เพิ่ม Callback สำหรับลบ

  const CoopDataCard({
    super.key,
    required this.recordNumber,
    required this.recordId,
    required this.healthyCount,
    required this.sickCount,
    required this.inspectionDate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFC0D6E4), 
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ข้อมูลการตรวจสุขภาพ ที่ $recordNumber',
            style: GoogleFonts.kanit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          _buildInfoRow('รหัสบันทึก :', recordId),
          _buildInfoRow('ไก่ที่สุขภาพดี :', healthyCount, suffixText: 'ตัว'),
          _buildInfoRow('ไก่ที่สุขภาพไม่ดี :', sickCount, suffixText: 'ตัว'),
          _buildInfoRow('วันที่ตรวจไก่ :', inspectionDate),

          const SizedBox(height: 10),

          // ปุ่ม Action ด้านล่างขวา
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionButton(
                title: 'แก้ไขข้อมูล', 
                bgColor: const Color(0xFFF1C40F),
                onTap: onEdit, // 🌟 เรียก Callback onEdit
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                title: 'ลบข้อมูล', 
                bgColor: const Color(0xFFFF0000),
                onTap: () {
                  // 🌟 เพิ่ม Popup ยืนยันการลบ
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('ยืนยันการลบ', style: GoogleFonts.kanit()),
                        content: Text('คุณต้องการลบข้อมูลนี้ใช่หรือไม่?', style: GoogleFonts.kanit()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('ยกเลิก', style: GoogleFonts.kanit()),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onDelete(); // เรียก Callback onDelete หลังจากกดยืนยัน
                            },
                            child: Text('ลบ', style: GoogleFonts.kanit(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),    
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {String? suffixText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.kanit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: GoogleFonts.kanit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          if (suffixText != null) ...[
            const SizedBox(width: 8),
            Text(
              suffixText,
              style: GoogleFonts.kanit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title, 
    required Color bgColor, 
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: GoogleFonts.kanit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}