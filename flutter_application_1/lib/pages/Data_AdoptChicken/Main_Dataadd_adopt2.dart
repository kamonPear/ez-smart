import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bottombar.dart'; 

class AddDataadopt extends StatefulWidget {
  const AddDataadopt({super.key});

  @override
  State<AddDataadopt> createState() => _AddDataadoptState();
}

class _AddDataadoptState extends State<AddDataadopt> {
  int selectedIndex = 0;

  // 🌟 สร้าง Controller สำหรับรับค่าจากช่องพิมพ์แต่ละช่อง
  final TextEditingController idController = TextEditingController();
  final TextEditingController importDateController = TextEditingController();
  final TextEditingController countController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

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

  // --- Helper: ฟังก์ชันสร้างช่องกรอกข้อมูลแนวนอน ---
  Widget _buildTextFieldRow({
    required String label, 
    String? hintText, 
    String? suffixText,
    TextEditingController? controller, // 🌟 เพิ่ม controller ตรงนี้
  }) {
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
                      controller: controller, // 🌟 นำ controller มาผูกกับช่องกรอก
                      textAlign: TextAlign.center, 
                      style: GoogleFonts.kanit(
                        fontSize: 15, 
                        fontWeight: FontWeight.w900, 
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: GoogleFonts.kanit(
                          fontSize: 15,
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

  // --- Helper: ฟังก์ชันสร้างปุ่มกด ---
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
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: GoogleFonts.kanit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
      backgroundColor: Colors.white,
      
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          constraints: BoxConstraints(minHeight: screenHeight),
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/back1.png'),
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          child: Stack(
            children: [
              // --- ส่วนที่ 2: เนื้อหา (แบบฟอร์มเพิ่มข้อมูล) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25), 
                child: Column(
                  children: [
                    const SizedBox(height: 270), 

                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBDE0EA), 
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'เพิ่มข้อมูลการรับเข้าเลี้ยง',
                            style: GoogleFonts.kanit(
                              fontSize: 20,
                              fontWeight: FontWeight.w900, 
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 25), 
                          
                          // 🌟 ใส่ controller ให้แต่ละช่อง
                          _buildTextFieldRow(
                            label: "รหัสคอกไก่ :", 
                            hintText: "",
                            controller: idController,
                          ),
                          _buildTextFieldRow(
                            label: "วันที่นำเข้าเลี้ยง :", 
                            hintText: "",
                            controller: importDateController,
                          ),
                          _buildTextFieldRow(
                            label: "จำนวนไก่ :", 
                            hintText: "",
                            suffixText: "ตัว",
                            controller: countController,
                          ),
                          _buildTextFieldRow(
                            label: "วันเกิดไก่ลอตนั้น :", 
                            hintText: "",
                            controller: birthDateController,
                          ),
                          _buildTextFieldRow(
                            label: "หมายเหตุ :", 
                            hintText: "",
                            controller: noteController,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40), 

                    // ปุ่มกด 2 ปุ่ม
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                      children: [
                        _buildActionButton('บันทึก', const Color(0xFF66E07A), () {
                          // 🌟 ดึงค่าจากช่องพิมพ์มาจัดเป็น Map แล้วส่งกลับ
                          Map<String, String> newData = {
                            "id": idController.text,
                            "importDate": importDateController.text,
                            "count": countController.text.isNotEmpty ? "${countController.text} ตัว" : "0 ตัว",
                            "birthDate": birthDateController.text,
                            "note": noteController.text.isNotEmpty ? noteController.text : "-",
                          };
                          Navigator.pop(context, newData);
                        }),
                        _buildActionButton('ยกเลิก', const Color(0xFFE5735F), () {
                          Navigator.pop(context);
                        }),
                      ],
                    ),
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