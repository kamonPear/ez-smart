import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bottombar.dart'; 
import 'close_open_Door.dart'; 

class MainAddDatachicken extends StatefulWidget {
  const MainAddDatachicken({super.key});

  @override
  State<MainAddDatachicken> createState() => _MainAddDatachickenState();
}

class _MainAddDatachickenState extends State<MainAddDatachicken> {
  int selectedIndex = 2; 

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  
  final TextEditingController _tempController = TextEditingController(text: '28');
  final TextEditingController _ppmController = TextEditingController(text: '20');

  @override
  void dispose() {
    _idController.dispose();
    _numberController.dispose();
    _tempController.dispose();
    _ppmController.dispose();
    super.dispose();
  }

  void onTabSelected(int index) {
    if (index == 0) {
      Navigator.pop(context);
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CloseOpenDoor()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainShowDataFood()),
      );
    } else {
      setState(() {
        selectedIndex = index;
      });
    }
  }

  Widget _buildValueBox(TextEditingController controller, Color bgColor, String unit) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 70, 
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(15), 
          ),
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center, 
            keyboardType: TextInputType.number, 
            style: GoogleFonts.kanit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none, 
              isDense: true, 
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          unit,
          style: GoogleFonts.kanit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildEditButton() {
    return GestureDetector(
      onTap: () {
        print("กดปุ่มแก้ไข");
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFF7A5F), 
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          'แก้ไข',
          style: GoogleFonts.kanit(
            fontSize: 16,
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
      resizeToAvoidBottomInset: true, 
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBCE0EA), 
                        borderRadius: BorderRadius.circular(12), 
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, 
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'เพิ่มข้อมูลคอกไก่',
                            style: GoogleFonts.kanit(
                              fontSize: 22,
                              fontWeight: FontWeight.w900, 
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 15),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'รหัสคอกไก่',
                              style: GoogleFonts.kanit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          _buildTextField(controller: _idController),
                          
                          const SizedBox(height: 15),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'คอกไก่ ที่ เท่าไหร่',
                              style: GoogleFonts.kanit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          _buildTextField(controller: _numberController),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30), 

                    Text(
                      'ค่าที่ตั้งไว้คงที่ทุกคอก',
                      style: GoogleFonts.kanit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 15),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildValueBox(_tempController, const Color(0xFF8CEEFA), 'C'), 
                        const SizedBox(width: 25), 
                        _buildValueBox(_ppmController, const Color(0xFFFF5E5E), 'PPM'), 
                      ],
                    ),
                    const SizedBox(height: 15),

                    _buildEditButton(),

                    const SizedBox(height: 40), 

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildButton(
                          label: 'บันทึก',
                          color: const Color(0xFF6FE975), 
                          textColor: Colors.white,
                          onTap: () {
                            if (_numberController.text.isEmpty) return; // เช็คว่าไม่ได้เว้นว่าง
                            
                            // ส่งข้อมูลกลับไปหน้าหลัก
                            Navigator.pop(context, {
                              "id": _idController.text,
                              "number": _numberController.text,
                              "temp": _tempController.text,
                              "ppm": _ppmController.text,
                            });
                          },
                        ),
                        const SizedBox(width: 20),
                        _buildButton(
                          label: 'ยกเลิก',
                          color: const Color(0xFFEF836B), 
                          textColor: Colors.white,
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 50), 
                  ],
                ),
              ),
            ),
          ),

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
                    Positioned(
                      left: 135,
                      top: 25,
                      child: Text(
                        'Ez Smart Frame',
                        style: GoogleFonts.kanit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 252, 250, 250),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 20,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const Notifications()),
                              );
                            },
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 15),
                          const Icon(
                            Icons.tune_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ],
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

  Widget _buildTextField({required TextEditingController controller}) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade400),
         boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 2,
          )
        ],
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.kanit(fontSize: 16),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}