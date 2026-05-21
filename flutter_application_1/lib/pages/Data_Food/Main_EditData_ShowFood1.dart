import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bottombar.dart';
import '../close_open_Door.dart';       

class MainEditdataShowfood1 extends StatefulWidget {
  // 🌟 รับค่าข้อมูลเดิมเข้ามาเพื่อทำการแก้ไข
  final Map<String, String> initialData;

  const MainEditdataShowfood1({super.key, required this.initialData});

  @override
  State<MainEditdataShowfood1> createState() => _MainEditdataShowfood1State();
}

class _MainEditdataShowfood1State extends State<MainEditdataShowfood1> {
  // ตั้งค่าเป็น 4 เพื่อให้ Bar ไฮไลท์ที่รูป "อาหาร" (เพราะหน้านี้เกี่ยวกับอาหาร)
  int selectedIndex = 4;

  // 🌟 1. สร้าง Controller สำหรับช่องกรอกข้อมูล
  late TextEditingController _dateReceivedController;
  late TextEditingController _amountController;
  late TextEditingController _expireDateController;
  late TextEditingController _thresholdController;

  @override
  void initState() {
    super.initState();
    // 🌟 2. นำข้อมูลเดิมที่รับมา ยัดใส่ Controller เพื่อแสดงในช่องกรอก
    _dateReceivedController = TextEditingController(text: widget.initialData['receiveDate']);
    _expireDateController = TextEditingController(text: widget.initialData['expireDate']);
    
    // ตัดคำว่า " กิโลกรัม" ออกเวลาแสดงผล เพื่อให้พิมพ์แก้ไขแค่ตัวเลขได้ง่ายๆ
    String amountText = widget.initialData['amount']?.replaceAll(' กิโลกรัม', '') ?? '';
    String thresholdText = widget.initialData['threshold']?.replaceAll(' กิโลกรัม', '') ?? '';
    
    _amountController = TextEditingController(text: amountText);
    _thresholdController = TextEditingController(text: thresholdText);
  }

  @override
  void dispose() {
    // 🌟 คืนหน่วยความจำเมื่อปิดหน้า
    _dateReceivedController.dispose();
    _amountController.dispose();
    _expireDateController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  // --- ฟังก์ชันจัดการการเปลี่ยนหน้าผ่าน BottomBar ---
  void onTabSelected(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CloseOpenDoor()),
      );
    } else if(index == 3){
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Mainchicken()),
      );
    } 
    else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainShowDataFood()),
      );
    } else if(index == 2){
       Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ShowChart()),
      );
    }
    else {
      // Index อื่นๆ -> เปลี่ยนสีปุ่มเฉยๆ
      setState(() {
        selectedIndex = index;
      });
    }
  }

  // 🌟 ปรับฟังก์ชันให้รับ TextEditingController แทน
  Widget _buildTextFieldGroup(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
          child: Text(
            label,
            style: GoogleFonts.kanit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        Container(
          height: 45,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F0F0), // สีพื้นหลังช่องกรอก (ขาวครีม)
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextField(
            controller: controller, // 🌟 ผูก Controller ตรงนี้
            style: GoogleFonts.kanit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  // ฟังก์ชันสร้างปุ่มกด (บันทึก / ยกเลิก)
  Widget _buildActionButton(String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 50,
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

          // --- ส่วนที่ 2: เนื้อหา (ฟอร์มแก้ไขข้อมูล) ---
          Positioned(
            top: 280, // เว้นระยะจาก Header ลงมา
            left: 0,
            right: 0,
            bottom: 80, // เว้นระยะให้ BottomBar
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                children: [
                  // --- การ์ดสีฟ้า (ฟอร์ม) ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBDDDE9), // สีฟ้าอ่อนตามรูป
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
                          "แก้ไขข้อมูลคลังอาหาร",
                          style: GoogleFonts.kanit(
                            fontSize: 24,
                            fontWeight: FontWeight.w900, // ตัวหนาพิเศษ
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 🌟 เรียกใช้ฟังก์ชันสร้างช่องกรอก พร้อมแนบ Controller
                        _buildTextFieldGroup("วัน / เดือน / ปี ที่รับอาหารเข้า", _dateReceivedController),
                        _buildTextFieldGroup("จำนวนอาหารที่รับเข้า", _amountController),
                        _buildTextFieldGroup("วันอาหารจะหมดอายุ", _expireDateController),
                        _buildTextFieldGroup("กำหนดค่าปริมาณใกล้จะหมด", _thresholdController),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- ปุ่มกด (บันทึก / ยกเลิก) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // ปุ่มบันทึก (สีเขียว)
                      _buildActionButton("บันทึก", const Color(0xFF66E675), () {
                        // 🌟 3. ดึงข้อมูลที่แก้เสร็จแล้ว แพ็คส่งกลับไปหน้าหลัก
                        String amountVal = _amountController.text;
                        if (amountVal.isNotEmpty && !amountVal.contains("กิโลกรัม")) {
                          amountVal = "$amountVal กิโลกรัม";
                        }

                        String thresholdVal = _thresholdController.text;
                        if (thresholdVal.isNotEmpty && !thresholdVal.contains("กิโลกรัม")) {
                          thresholdVal = "$thresholdVal กิโลกรัม";
                        }

                        Map<String, String> updatedData = {
                          "receiveDate": _dateReceivedController.text,
                          "amount": amountVal.isNotEmpty ? amountVal : "0 กิโลกรัม",
                          "expireDate": _expireDateController.text,
                          "threshold": thresholdVal.isNotEmpty ? thresholdVal : "-",
                        };
                        
                        Navigator.pop(context, updatedData);
                      }),
                      
                      // ปุ่มยกเลิก (สีส้มแดง)
                      _buildActionButton("ยกเลิก", const Color(0xFFEB856D), () {
                        // กดยกเลิก กลับหน้าเดิมโดยไม่ส่งค่ากลับ
                        Navigator.pop(context);
                      }),
                    ],
                  ),
                  
                  const SizedBox(height: 50), // พื้นที่ว่างด้านล่าง
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