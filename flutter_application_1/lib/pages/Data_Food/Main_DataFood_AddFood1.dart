import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bottombar.dart';

class MainAddDataFood extends StatefulWidget {
  // 🌟 1. รับค่ายอดคงเหลือปัจจุบันมาจากหน้าหลัก
  final int currentAmount;

  const MainAddDataFood({super.key, required this.currentAmount});

  @override
  State<MainAddDataFood> createState() => _MainAddDataFoodState();
}

class _MainAddDataFoodState extends State<MainAddDataFood> {
  int selectedIndex = 4;
  
  // Controller สำหรับช่องกรอกจำนวนที่ต้องการตัด
  final TextEditingController _foodAmountController = TextEditingController();

  void onTabSelected(int index) {
    if ( index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }else if(index == 1){
       Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CloseOpenDoor()),
      );
    } else if(index == 3){
       Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Mainchicken()),
      );
    } else if(index == 4){
        Navigator.push(
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

          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 320, 
                    padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 176, 212, 233), 
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.black54, width: 0.5), 
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'กรอกข้อมูลปริมาณอาหาร',
                          style: GoogleFonts.kanit(
                            fontSize: 24,
                            fontWeight: FontWeight.w900, 
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'ปริมาณอาหารที่นำไปให้ไก่ในแต่ละวัน',
                          style: GoogleFonts.kanit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 25),
                        
                        // 🌟 2. แสดงยอดคงเหลือปัจจุบันจริงๆ ที่รับมาจากหน้าแรก
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.kanit(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.bold
                            ),
                            children: [
                              const TextSpan(text: 'ปริมาณอาหารคงเหลือ : '),
                              TextSpan(
                                text: '${widget.currentAmount} กิโลกรัม',
                                style: const TextStyle(fontWeight: FontWeight.w900), 
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        
                        // ช่องกรอกข้อมูลปริมาณที่จะตัดออก
                        Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F0F0), 
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: TextField(
                            controller: _foodAmountController,
                            keyboardType: TextInputType.number, // บังคับคีย์บอร์ดตัวเลข
                            textAlign: TextAlign.left,
                            style: GoogleFonts.kanit(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                              border: InputBorder.none, 
                              hintText: "เช่น 5", // ตัวอย่าง
                              hintStyle: GoogleFonts.kanit(
                                color: Colors.black38,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 2.2 ปุ่มกด (บันทึก / ยกเลิก)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ปุ่มบันทึก (สีเขียว)
                      GestureDetector(
                        onTap: () {
                          // 🌟 3. ดึงตัวเลขมาคำนวณหักลบกับยอดคงเหลือ
                          int amountToCut = int.tryParse(_foodAmountController.text) ?? 0;
                          
                          if (amountToCut > widget.currentAmount) {
                            // แจ้งเตือนถ้าจะตัดสต็อกเกินยอดคงเหลือ
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ปริมาณที่เบิกออก มากกว่ายอดคงเหลือ!')),
                            );
                            return;
                          }

                          // คำนวณยอดสุทธิ
                          int newTotalAmount = widget.currentAmount - amountToCut;
                          
                          // ส่งยอดสุทธิกลับไปให้หน้าแรกอัปเดต
                          Navigator.pop(context, newTotalAmount); 
                        },
                        child: Container(
                          width: 120,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6FE975),
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
                              'บันทึก',
                              style: GoogleFonts.kanit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 30), 
                      
                      // ปุ่มยกเลิก (สีส้ม)
                      GestureDetector(
                        onTap: () {
                          // กดยกเลิก ส่งค่ากลับเป็น null
                           Navigator.pop(context, null);
                        },
                        child: Container(
                          width: 120,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF836B),
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
                              'ยกเลิก',
                              style: GoogleFonts.kanit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Header
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