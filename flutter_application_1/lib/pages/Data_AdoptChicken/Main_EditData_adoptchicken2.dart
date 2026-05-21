import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bottombar.dart';

class EditDataAdoptchicken extends StatefulWidget {
  // 🌟 1. สร้างตัวแปรรับข้อมูลเดิมที่ถูกส่งมาจากหน้าหลัก
  final Map<String, String> initialData;

  const EditDataAdoptchicken({super.key, required this.initialData});

  @override
  State<EditDataAdoptchicken> createState() => _EditDataAdoptchickenState();
}

class _EditDataAdoptchickenState extends State<EditDataAdoptchicken> {
  int selectedIndex = 0;

  // 🌟 2. สร้าง Controller สำหรับช่องกรอกข้อมูล
  late TextEditingController idController;
  late TextEditingController importDateController;
  late TextEditingController countController;
  late TextEditingController birthDateController;
  late TextEditingController noteController;

  @override
  void initState() {
    super.initState();
    // 🌟 3. นำข้อมูลเดิมที่รับมา ยัดใส่ช่องกรอกข้อมูลตั้งแต่เปิดหน้า
    idController = TextEditingController(text: widget.initialData['id']);
    importDateController = TextEditingController(text: widget.initialData['importDate']);
    
    // ตัดคำว่า " ตัว" ออกตอนแสดงในช่องกรอก เพื่อให้แก้แค่ตัวเลขได้ง่ายๆ
    String countText = widget.initialData['count']?.replaceAll(' ตัว', '') ?? '';
    countController = TextEditingController(text: countText);
    
    birthDateController = TextEditingController(text: widget.initialData['birthDate']);
    noteController = TextEditingController(text: widget.initialData['note']);
  }

  @override
  void dispose() {
    idController.dispose();
    importDateController.dispose();
    countController.dispose();
    birthDateController.dispose();
    noteController.dispose();
    super.dispose();
  }

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

  // --- Helper: ปรับให้ใช้ controller แทน initialValue ---
  Widget _buildTextFieldRow(String label, {String? suffixText, required TextEditingController controller}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
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
            child: Row(
              children: [
                Expanded(
                  flex: suffixText != null ? 3 : 5, 
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(20), 
                    ),
                    child: TextFormField(
                      controller: controller, // 🌟 ผูก controller ตรงนี้
                      textAlign: TextAlign.center, 
                      style: GoogleFonts.kanit(
                        fontSize: 15, 
                        fontWeight: FontWeight.w900, 
                        color: Colors.black,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        isDense: true, 
                      ),
                    ),
                  ),
                ),
                if (suffixText != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1, 
                    child: Text(
                      suffixText,
                      style: GoogleFonts.kanit(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper: ปุ่มกด ---
  Widget _buildActionButton(String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 45,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
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
            text,
            style: GoogleFonts.kanit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
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
          // พื้นหลัง
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

          // เนื้อหาฟอร์มแก้ไข
          Positioned(
            top: 270, 
            left: 0,
            right: 0,
            bottom: 80, 
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20), 
              child: Column(
                children: [
                  const SizedBox(height: 20), 
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBDDDE9), 
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "แก้ไขข้อมูลการรับไก่เข้าเลี้ยง",
                          style: GoogleFonts.kanit(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 25),

                        // 🌟 โยน controller เข้าไปในช่องกรอกแต่ละช่อง
                        _buildTextFieldRow("รหัสคอกไก่ :", controller: idController),
                        _buildTextFieldRow("วันที่นำเข้าเลี้ยง :", controller: importDateController),
                        _buildTextFieldRow("จำนวนไก่ :", suffixText: "ตัว", controller: countController),
                        _buildTextFieldRow("วันเกิดไก่ลอตนั้น :", controller: birthDateController),
                        _buildTextFieldRow("หมายเหตุ :", controller: noteController),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton("บันทึก", const Color(0xFF66E675), () {
                        // 🌟 4. ดึงข้อมูลที่แก้เสร็จแล้ว แพ็คส่งกลับไปหน้าหลัก
                        Map<String, String> updatedData = {
                          "id": idController.text,
                          "importDate": importDateController.text,
                          "count": countController.text.isNotEmpty ? "${countController.text} ตัว" : "0 ตัว",
                          "birthDate": birthDateController.text,
                          "note": noteController.text.isNotEmpty ? noteController.text : "-",
                        };
                        Navigator.pop(context, updatedData);
                      }),
                      _buildActionButton("ยกเลิก", const Color(0xFFEB856D), () {
                        Navigator.pop(context); // กดยกเลิก ไม่ส่งค่าอะไรกลับไป
                      }),
                    ],
                  ),
                  
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),

          // --- Header (EZ Smart Farm) ---
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