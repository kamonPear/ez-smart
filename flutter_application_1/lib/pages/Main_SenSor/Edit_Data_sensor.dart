import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bottombar.dart';

class Editsensor extends StatefulWidget {
  const Editsensor({super.key});

  @override
  State<Editsensor> createState() => _EditsensorState();
}

class _EditsensorState extends State<Editsensor> {
  int selectedIndex = 0;

  void onTabSelected(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  // --- Helper: ฟังก์ชันสร้างช่องกรอกข้อมูล (อัปเดตเป็นแนวนอน Row) ---
  Widget _buildTextFieldRow(String label, String initialValue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ส่วนข้อความ Label ด้านซ้าย
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.kanit(
                fontSize: 16,
                fontWeight: FontWeight.w900, // ปรับให้หนาขึ้นตามรูป
                color: Colors.black,
              ),
            ),
          ),
          // ส่วนช่องกรอกข้อมูล ด้านขวา
          Expanded(
            flex: 3,
            child: Container(
              height: 40, // ปรับขนาดความสูงให้พอดี
              decoration: BoxDecoration(
                color: Colors.white, // สีพื้นหลังช่องกรอกสีขาว
                borderRadius: BorderRadius.circular(20), // ขอบมนทรงแคปซูล
              ),
              child: TextFormField(
                initialValue: initialValue, // ใส่ค่าเริ่มต้นให้เหมือนในรูป
                textAlign: TextAlign.center, // จัดข้อความให้อยู่กึ่งกลางตามรูปภาพ
                style: GoogleFonts.kanit(
                  fontSize: 16, 
                  fontWeight: FontWeight.w900, // ตัวหนังสือในช่องกรอกเป็นตัวหนา
                  color: Colors.black,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  isDense: true, // ช่วยจัดข้อความให้อยู่กึ่งกลางแนวตั้งพอดี
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper: ฟังก์ชันสร้างปุ่มกด (บันทึก/ยกเลิก) ---
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
            top: 270, // เว้นระยะจาก Header
            left: 0,
            right: 0,
            bottom: 80, // เว้นระยะให้ BottomBar
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 20), // ดันลงมานิดหน่อย
                  
                  // กล่องสีฟ้า (Form)
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
                          "แก้ไขข้อมูลอุปกรณ์", 
                          style: GoogleFonts.kanit(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 25),

                        // 🌟 เรียกใช้ Widget ช่องกรอกข้อมูลอุปกรณ์
                        _buildTextFieldRow("รหัสอุปกรณ์ :", "DEV-001"),
                        _buildTextFieldRow("ชื่ออุปกรณ์ :", "เซนเซอร์วัดอุณหภูมิ"),
                        _buildTextFieldRow("ประเภทอุปกรณ์ :", "เซนเซอร์"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ปุ่มกดด้านล่าง
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton("บันทึก", const Color(0xFF66E675), () {
                        // Action เมื่อกดบันทึก
                      }),
                      _buildActionButton("ยกเลิก", const Color(0xFFEB856D), () {
                        // Action เมื่อกดยกเลิก (เช่น Navigator.pop)
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