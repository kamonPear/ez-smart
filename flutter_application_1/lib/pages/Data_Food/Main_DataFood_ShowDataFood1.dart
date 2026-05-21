import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataAdd_Food1.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_AddFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bottombar.dart';
import '../close_open_Door.dart';           
import 'Main_EditData_ShowFood1.dart';  


class MainShowDataFood extends StatefulWidget {
  const MainShowDataFood({super.key});

  @override
  State<MainShowDataFood> createState() => _MainShowDataFoodState();
}

class _MainShowDataFoodState extends State<MainShowDataFood> {
  int selectedIndex = 4;

  Map<String, String>? foodData = {
    "receiveDate": "28 / 03 / 2568",
    "amount": "100", 
    "expireDate": "14 / 08 / 2568",
    "threshold": "20 กิโลกรัม",
  };

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
    } else if (index == 4) {
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
      setState(() {
        selectedIndex = index;
      });
    }
  }

  Widget _buildInfoField(String label, String value, {bool isUnderlined = false}) {
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
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F0F0),
            borderRadius: BorderRadius.circular(20),
          ),
          child: isUnderlined
              ? RichText(
                  text: TextSpan(
                    style: GoogleFonts.kanit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(
                        text: value.split(' ')[0],
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.blue,
                          decorationThickness: 2,
                        ),
                      ),
                      TextSpan(
                        text: value.contains(' ') ? ' ${value.split(' ').sublist(1).join(' ')}' : '',
                      ),
                    ],
                  ),
                )
              : Text(
                  value,
                  style: GoogleFonts.kanit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSmallButton(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.kanit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: (text == 'ลบข้อมูล') ? Colors.white : Colors.black87,
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

          Positioned(
            top: 290,
            left: 0,
            right: 0,
            bottom: 80,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  if (foodData != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                            "ข้อมูลคลังอาหาร",
                            style: GoogleFonts.kanit(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 15),

                          _buildInfoField("วัน / เดือน / ปี ที่รับอาหารเข้า", foodData!['receiveDate']!),
                          _buildInfoField("จำนวนอาหารคงเหลือ", "${foodData!['amount']} กิโลกรัม", isUnderlined: true),
                          _buildInfoField("วันที่อาหารใกล้จะหมด", foodData!['expireDate']!),
                          _buildInfoField("กำหนดค่าปริมาณใกล้จะหมด", foodData!['threshold']!),

                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MainEditdataShowfood1(
                                        initialData: {
                                          ...foodData!,
                                          "amount": "${foodData!['amount']} กิโลกรัม",
                                        }
                                      ),
                                    ),
                                  );

                                  if (result != null) {
                                    result["amount"] = result["amount"]!.replaceAll(" กิโลกรัม", "");
                                    setState(() {
                                      foodData = result;
                                    });
                                  }
                                },
                                child: _buildSmallButton("แก้ไขข้อมูล", const Color(0xFFEEDD44)),
                              ),
                              
                              const SizedBox(width: 10),
                              
                              GestureDetector(
                                 onTap: () {
                                   showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('ยืนยันการลบ', style: GoogleFonts.kanit()),
                                        content: Text('ต้องการลบข้อมูลคลังอาหารใช่หรือไม่?', style: GoogleFonts.kanit()),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: Text('ยกเลิก', style: GoogleFonts.kanit()),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                foodData = null; 
                                              });
                                              Navigator.pop(context);
                                            },
                                            child: Text('ลบ', style: GoogleFonts.kanit(color: Colors.red)),
                                          ),
                                        ],
                                      )
                                   );
                                 },
                                 child: _buildSmallButton("ลบข้อมูล", const Color(0xFFFF0000)),
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.center,
                      child: Text(
                        "ไม่มีข้อมูลคลังอาหาร",
                        style: GoogleFonts.kanit(fontSize: 18, color: Colors.black54),
                      ),
                    ),

                  const SizedBox(height: 30),

                  // 🌟 ปุ่มเพิ่มข้อมูล 
                  GestureDetector(
                    onTap: () async {
                      // 🌟 เพิ่ม Navigator.push เพื่อเปลี่ยนไปหน้า MainaddDataFood
                      // และรอรับค่าข้อมูลใหม่ (newData) กลับมาเมื่อผู้ใช้กดปุ่ม "เพิ่มข้อมูล" ในหน้านั้น
                      final newData = await Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => const MainaddDataFood()),
                      );
                      
                      // 🌟 ถ้ารับข้อมูลกลับมาสำเร็จ ให้อัปเดตตัวแปร foodData เพื่อแสดงผล
                      if (newData != null) { 
                        // เนื่องจากหน้าก่อนหน้านี้เราตัดคำว่า " กิโลกรัม" ออกตอนคำนวณ เราจะตัดออกก่อนจัดเก็บด้วย
                        newData["amount"] = newData["amount"].toString().replaceAll(" กิโลกรัม", "");
                        
                        setState(() { 
                          foodData = Map<String, String>.from(newData); 
                        }); 
                      }
                    },
                    child: Container(
                      width: 200,
                      height: 55,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9DE492), 
                        borderRadius: BorderRadius.circular(15),
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
                          "เพิ่มข้อมูล",
                          style: GoogleFonts.kanit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              const Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black26),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  GestureDetector(
                    onTap: () async {
                      if (foodData == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ไม่มีข้อมูลคลังอาหารให้ตัดสต็อก')),
                        );
                        return;
                      }

                      final newAmount = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MainAddDataFood(
                            currentAmount: int.tryParse(foodData!['amount']!) ?? 0,
                          ),
                        ), 
                      );

                      if (newAmount != null) {
                        setState(() {
                          foodData!['amount'] = newAmount.toString();
                        });
                      }
                    },
                    child: Container(
                      width: 200,
                      height: 55,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF836B), 
                        borderRadius: BorderRadius.circular(15),
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
                          "ตัดสต็อก",
                          style: GoogleFonts.kanit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              const Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black26),
                            ],
                          ),
                        ),
                      ),
                    ),
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