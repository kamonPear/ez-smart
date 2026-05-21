import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bottombar.dart';

class Adddatasensor extends StatefulWidget {
  const Adddatasensor({super.key});

  @override
  State<Adddatasensor> createState() => _AdddatasensorState();
}

class _AdddatasensorState extends State<Adddatasensor> {
  int selectedIndex = 0;

  void onTabSelected(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  // --- Helper: ฟังก์ชันสร้างช่องกรอกข้อมูลแนวนอน (อัปเดตตามรูป) ---
  Widget _buildTextFieldRow({
    required String label, 
    String? hintText, 
    String? suffixText
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ส่วนข้อความ Label ฝั่งซ้าย
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: GoogleFonts.kanit(
                fontSize: 16,
                fontWeight: FontWeight.w900, // ตัวหนาตามรูป
                color: Colors.black,
              ),
            ),
          ),
          // ส่วนช่องกรอกข้อมูลและคำต่อท้าย ฝั่งขวา
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Expanded(
                  flex: suffixText != null ? 3 : 5, // ย่อขนาดช่องกรอกให้สั้นลงถ้ามีคำต่อท้าย
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white, // พื้นหลังสีขาว
                      borderRadius: BorderRadius.circular(20), // ทรงแคปซูลมน
                    ),
                    child: TextFormField(
                      textAlign: TextAlign.center, // จัดข้อความให้อยู่กึ่งกลาง
                      style: GoogleFonts.kanit(
                        fontSize: 16, 
                        fontWeight: FontWeight.w900, 
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: GoogleFonts.kanit(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.black54,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                // แสดงคำต่อท้าย (ถ้ามี) เช่น "ตัว"
                if (suffixText != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Text(
                      suffixText,
                      style: GoogleFonts.kanit(
                        fontSize: 16,
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
      backgroundColor: Colors.white, // ใส่สีขาวเผื่อเวลาเลื่อนจนสุดรูป
      
      // 1. ครอบด้วย SingleChildScrollView และตั้งให้เลื่อนได้เสมอ
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          // 2. ให้ Container อย่างน้อยสูงเท่าหน้าจอ และใส่ภาพพื้นหลังไว้ที่นี่
          constraints: BoxConstraints(minHeight: screenHeight),
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/back1.png'),
              fit: BoxFit.fitWidth, // ให้ภาพขยายกว้างเต็มจอแล้วเลื่อนขึ้นไปพร้อมกัน
              alignment: Alignment.topCenter,
            ),
          ),
          child: Stack(
            children: [
              // --- ส่วนที่ 2: เนื้อหาหลัก ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    // ดันกล่องฟอร์มลงมาให้อยู่ใต้ Header พอดี
                    const SizedBox(height: 270), 
                    
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
                            "เพิ่มข้อมูลอุปกรณ์", // เปลี่ยนชื่อหัวข้อให้สอดคล้อง
                            style: GoogleFonts.kanit(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 🌟 อัปเดตช่องกรอกข้อมูลให้ตรงตามรูปภาพ
                          _buildTextFieldRow(
                            label: "รหัสอุปกรณ์ :", 
                            hintText: ""
                          ),
                          _buildTextFieldRow(
                            label: "ชื่ออุปกรณ์ :", 
                            hintText: ""
                          ),
                          _buildTextFieldRow(
                            label: "ประเภทอุปกรณ์ :", 
                            hintText: ""
                          ),
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
                          // Action เมื่อกดยกเลิก
                          Navigator.pop(context);
                        }),
                      ],
                    ),
                    
                    // เว้นระยะด้านล่างสุดไม่ให้โดน BottomBar บัง
                    const SizedBox(height: 100),
                  ],
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
        ),
      ),

      bottomNavigationBar: CustomBottomBar(
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected,
      ),
    );
  }
}