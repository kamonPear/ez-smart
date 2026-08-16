import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bottombar.dart';
import '../widgets/ez_header.dart';

class CloseOpenDoor extends StatefulWidget {
  const CloseOpenDoor({super.key});

  @override
  State<CloseOpenDoor> createState() => _CloseOpenDoorState();
}

class _CloseOpenDoorState extends State<CloseOpenDoor> {
  int selectedIndex = 1;

  // 1. List of Maps เพื่อจำ ID ของประตู และสถานะ
  List<Map<String, dynamic>> doors = List.generate(5, (index) => {
    "id": index + 1,
    "isOn": false,
    "selected": false,
  });
  
  int nextDoorId = 6; 
  bool isDeleteMode = false; 

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
    } else if(index == 2){
       Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ShowChart()),
      );
    } else {
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
    print("เพิ่มประตูคอกไก่ที่ ${nextDoorId - 1}");
  }

  // ฟังก์ชันลบประตู หรือจัดการโหมดลบ
  void _handleDelete() {
    setState(() {
      if (!isDeleteMode) {
        // เปิดโหมดลบ
        isDeleteMode = true;
      } else {
        // ถ้าอยู่ในโหมดลบ ตรวจสอบว่ามีการเลือกประตูหรือไม่
        bool hasSelection = doors.any((door) => door["selected"] == true);
        if (hasSelection) {
          doors.removeWhere((door) => door["selected"] == true);
          isDeleteMode = false; // ลบเสร็จออกจากโหมดลบ
        } else {
          // ถ้าไม่ได้เลือกอะไรเลย ให้ยกเลิกโหมดลบ
          isDeleteMode = false;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: ezBackgroundColor,

      body: Stack(
        children: [
          // --- Layer: เนื้อหา ( SafeArea + Column ) ---
          SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: EzHeader(pageTitle: 'ประตูเล้าไก่'),
                ),
                const SizedBox(height: 20),

                // Header Icons (ลบซ้าย - เพิ่มขวา)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: _handleDelete,
                        child: Icon(
                          isDeleteMode ? Icons.delete : Icons.delete_outline,
                          color: Colors.red,
                          size: 30,
                        ),
                      ),
                      GestureDetector(
                        onTap: _addNewDoor,
                        child: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),

                // รายการประตู
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          for (int i = 0; i < doors.length; i++)
                            _buildDoorControlTile(doors[i], i),
                          
                          const SizedBox(height: 100), // ระยะห่างเผื่อ BottomBar
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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

  // ฟังก์ชันสร้าง UI สำหรับแต่ละประตู
  Widget _buildDoorControlTile(Map<String, dynamic> door, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text("OFF ", style: GoogleFonts.kanit(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                  Text("ON", style: GoogleFonts.kanit(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 30,
                child: Transform.scale(
                  scale: 0.9,
                  child: Switch(
                    value: door["isOn"],
                    activeColor: Colors.white,
                    activeTrackColor: Colors.black,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.black,
                    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                    onChanged: (bool value) {
                      setState(() {
                        door["isOn"] = value;
                        print("ประตูที่ ${door["id"]} สถานะ: ${value ? 'เปิด' : 'ปิด'}");
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}