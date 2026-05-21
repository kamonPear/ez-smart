import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bottombar.dart';

class EditNumbereggchicken extends StatefulWidget {
  final Map<String, String> initialData;

  const EditNumbereggchicken({super.key, required this.initialData});

  @override
  State<EditNumbereggchicken> createState() => _EditNumbereggchickenState();
}

class _EditNumbereggchickenState extends State<EditNumbereggchicken> {
  int selectedIndex = 0;

  // 🌟 1. สร้าง Controller สำหรับช่องกรอกข้อมูล
  late TextEditingController _eggIdController;
  late TextEditingController _dateController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    // 🌟 2. นำข้อมูลเดิมที่รับมา ยัดใส่ช่องกรอกข้อมูลตั้งแต่เปิดหน้า
    _eggIdController = TextEditingController(text: widget.initialData['id']);
    _dateController = TextEditingController(text: widget.initialData['date']);
    
    // ตัดคำว่า " ฟอง" ออกตอนแสดงผล เพื่อให้แก้แค่ตัวเลขได้ง่ายๆ
    String countText = widget.initialData['count']?.replaceAll(' ฟอง', '') ?? '';
    _amountController = TextEditingController(text: countText);
    
    _noteController = TextEditingController(text: widget.initialData['note']);
  }

  @override
  void dispose() {
    // อย่าลืมเคลียร์ Controller เพื่อคืนหน่วยความจำ
    _eggIdController.dispose();
    _dateController.dispose();
    _amountController.dispose();
    _noteController.dispose();
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

  // --- Helper: ปรับฟังก์ชันให้รับ Controller แทน initialValue ---
  Widget _buildTextFieldRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.kanit(
                fontSize: 16,
                fontWeight: FontWeight.w900, 
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              height: 40, 
              decoration: BoxDecoration(
                color: const Color(0xFFF5F0F0), 
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextFormField(
                controller: controller, // 🌟 ใช้ controller ผูกกับช่องกรอก
                textAlign: TextAlign.center, // จัดข้อความให้อยู่กึ่งกลาง
                style: GoogleFonts.kanit(
                  fontSize: 16, 
                  fontWeight: FontWeight.w900, 
                  color: Colors.black,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  isDense: true, 
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper: สร้างปุ่มกด (บันทึก/ยกเลิก) ---
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
            top: 270, 
            left: 0,
            right: 0,
            bottom: 80, 
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 20), 
                  
                  // กล่องสีฟ้า (Form)
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
                          "แก้ไขข้อมูลการเก็บไข่", 
                          style: GoogleFonts.kanit(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 25),

                        // 🌟 โยน controller เข้าไปในช่องกรอกแต่ละช่อง
                        _buildTextFieldRow("รหัสการเก็บไข่ :", _eggIdController),
                        _buildTextFieldRow("วันที่เก็บ :", _dateController),
                        _buildTextFieldRow("จำนวนไข่ :", _amountController),
                        _buildTextFieldRow("หมายเหตุ :", _noteController),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ปุ่มกดด้านล่าง
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton("บันทึก", const Color(0xFF66E675), () {
                        // 🌟 3. ดึงข้อมูลที่แก้เสร็จแล้ว แพ็คส่งกลับไปหน้าหลัก
                        String countValue = _amountController.text;
                        // เช็คว่ามีคำว่า ฟอง หรือยัง ถ้ายังให้เติมไป
                        if (countValue.isNotEmpty && !countValue.contains("ฟอง")) {
                          countValue = "$countValue ฟอง";
                        }

                        Map<String, String> updatedData = {
                          "id": _eggIdController.text,
                          "date": _dateController.text,
                          "count": countValue.isNotEmpty ? countValue : "0 ฟอง",
                          "note": _noteController.text.isNotEmpty ? _noteController.text : "-",
                        };
                        
                        Navigator.pop(context, updatedData);
                      }),
                      _buildActionButton("ยกเลิก", const Color(0xFFEB856D), () {
                        // ไม่ส่งค่าอะไรกลับไป
                        Navigator.pop(context);
                      }),
                    ],
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