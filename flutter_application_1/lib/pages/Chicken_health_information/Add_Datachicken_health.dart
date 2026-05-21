import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bottombar.dart';

class AddDatachickenHealth extends StatefulWidget {
  const AddDatachickenHealth({super.key});

  @override
  State<AddDatachickenHealth> createState() => _AddDatachickenHealthState();
}

class _AddDatachickenHealthState extends State<AddDatachickenHealth> {
  int selectedIndex = 0;

  // 🌟 1. สร้าง Controller ไว้รับค่าจากฟอร์ม
  final TextEditingController _recordIdController = TextEditingController();
  final TextEditingController _healthyCountController = TextEditingController();
  final TextEditingController _sickCountController = TextEditingController();
  final TextEditingController _inspectionDateController = TextEditingController();

  @override
  void dispose() {
    _recordIdController.dispose();
    _healthyCountController.dispose();
    _sickCountController.dispose();
    _inspectionDateController.dispose();
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

  // --- Helper: เพิ่มพารามิเตอร์ controller ---
  Widget _buildTextFieldRow({
    required String label, 
    required TextEditingController controller, // 🌟 เพิ่มตรงนี้
    String? hintText, 
    String? suffixText
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
                fontSize: 16,
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
                      controller: controller, // 🌟 นำ controller มาผูกกับ TextFormField
                      textAlign: TextAlign.center, 
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    const SizedBox(height: 270), 
                    
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
                            "เพิ่มข้อมูลการตรวจสุขภาพ",
                            style: GoogleFonts.kanit(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 🌟 2. โยน Controller เข้าไปในแต่ละช่อง
                          _buildTextFieldRow(
                            label: "รหัสบันทึก :", 
                            controller: _recordIdController,
                            hintText: "REC..."
                          ),
                          _buildTextFieldRow(
                            label: "ไก่ที่สุขภาพดี :", 
                            controller: _healthyCountController,
                            hintText: "0", 
                            suffixText: "ตัว"
                          ),
                          _buildTextFieldRow(
                            label: "ไก่ที่สุขภาพไม่ดี :", 
                            controller: _sickCountController,
                            hintText: "0", 
                            suffixText: "ตัว"
                          ),
                          _buildTextFieldRow(
                            label: "วันที่ตรวจไก่ :", 
                            controller: _inspectionDateController,
                            hintText: "DD/MM/YYYY"
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton("บันทึก", const Color(0xFF66E675), () {
                          // 🌟 3. แพ็คข้อมูลแล้วเด้งกลับหน้าเดิม
                          Map<String, String> newData = {
                            "recordId": _recordIdController.text,
                            "healthyCount": _healthyCountController.text.isNotEmpty ? _healthyCountController.text : "0",
                            "sickCount": _sickCountController.text.isNotEmpty ? _sickCountController.text : "0",
                            "inspectionDate": _inspectionDateController.text,
                          };
                          Navigator.pop(context, newData);
                        }),
                        _buildActionButton("ยกเลิก", const Color(0xFFEB856D), () {
                          Navigator.pop(context);
                        }),
                      ],
                    ),
                    
                    const SizedBox(height: 100),
                  ],
                ),
              ),

              // --- Header ---
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