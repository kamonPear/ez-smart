import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bottombar.dart'; 
import '../close_open_Door.dart'; 

class MainaddDataFood extends StatefulWidget {
  const MainaddDataFood({super.key});

  @override
  State<MainaddDataFood> createState() => _MainaddDataFoodState();
}

class _MainaddDataFoodState extends State<MainaddDataFood> {
  int selectedIndex = 4;

  final TextEditingController _dateReceivedController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _expireDateController = TextEditingController();
  final TextEditingController _thresholdController = TextEditingController();

  @override
  void dispose() {
    _dateReceivedController.dispose();
    _amountController.dispose();
    _expireDateController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10.0, bottom: 4.0),
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
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F0F0), 
            borderRadius: BorderRadius.circular(20), 
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.kanit(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              border: InputBorder.none, 
              contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 12), 
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 120,
      height: 45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 3),
            blurRadius: 4,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.kanit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
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
      resizeToAvoidBottomInset: false, 
      body: Stack(
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

          Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 280), 

                  Container(
                    width: 320, 
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBCE0EA), 
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "เพิ่มข้อมูลคลังอาหาร",
                          style: GoogleFonts.kanit(
                            fontSize: 22,
                            fontWeight: FontWeight.w900, 
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 15),

                        _buildTextField(
                          label: "วัน / เดือน / ปี ที่รับอาหารเข้า",
                          controller: _dateReceivedController,
                        ),
                        _buildTextField(
                          label: "จำนวนอาหารที่รับเข้า",
                          controller: _amountController,
                        ),
                        _buildTextField(
                          label: "วันอาหารจะหมดอายุ",
                          controller: _expireDateController,
                        ),
                        _buildTextField(
                          label: "กำหนดค่าปริมาณใกล้จะหมด",
                          controller: _thresholdController,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton(
                        label: 'บันทึก',
                        color: const Color(0xFF6FE975),
                        textColor: Colors.white,
                        onTap: () {
                          // 🌟 แพ็คข้อมูลแล้วโยนกลับไปทับของเดิมที่หน้าแสดงผล
                          Map<String, String> newData = {
                            "receiveDate": _dateReceivedController.text,
                            "amount": _amountController.text.isNotEmpty ? "${_amountController.text} กิโลกรัม" : "0 กิโลกรัม",
                            "expireDate": _expireDateController.text,
                            "threshold": _thresholdController.text.isNotEmpty ? "${_thresholdController.text} กิโลกรัม" : "-",
                          };
                          Navigator.pop(context, newData);
                        },
                      ),
                      const SizedBox(width: 30),
                      _buildActionButton(
                        label: 'ยกเลิก',
                        color: const Color(0xFFEF836B),
                        textColor: Colors.white,
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
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

      bottomNavigationBar: CustomBottomBar(
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected,
      ),
    );
  }
}