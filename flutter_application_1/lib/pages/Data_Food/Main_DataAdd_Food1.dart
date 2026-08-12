import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../bottombar.dart';
import '../close_open_Door.dart';

class MainaddDataFood extends StatefulWidget {
  const MainaddDataFood({super.key});

  @override
  State<MainaddDataFood> createState() => _MainaddDataFoodState();
}

class _MainaddDataFoodState extends State<MainaddDataFood> {
  int selectedIndex = 4;

  final String backendBaseUrl = "http://10.0.2.2:8080";

  final TextEditingController _dateReceivedController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _expireDateController = TextEditingController();
  final TextEditingController _thresholdController = TextEditingController();

  DateTime? _selectedImportDate;
  DateTime? _selectedExpiryDate;

  @override
  void initState() {
    super.initState();
    // 🌟 ดักจับเหตุการณ์เมื่อผู้ใช้พิมพ์ปริมาณอาหารหรือปริมาณใกล้หมด ให้คำนวณวันอัตโนมัติ
    _amountController.addListener(_calculateExpiryDate);
    _thresholdController.addListener(_calculateExpiryDate);
  }

  @override
  void dispose() {
    _dateReceivedController.dispose();
    _amountController.dispose();
    _expireDateController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  // 🌟 ฟังก์ชันคำนวณวันที่อาหารใกล้หมดอัตโนมัติ
  void _calculateExpiryDate() {
    // ถ้ายังไม่ได้เลือกวันนำเข้า ให้ใช้วันนี้เป็นฐานคำนวณไปก่อน
    DateTime startDate = _selectedImportDate ?? DateTime.now();

    double amount = double.tryParse(_amountController.text) ?? 0.0;
    double threshold = double.tryParse(_thresholdController.text) ?? 0.0;
    
    // อัตราการกิน/ตัดสต็อก ต่อวัน (20 กิโลกรัม)
    double consumePerDay = 20.0; 

    if (amount > 0) {
      int daysLeft = 0;
      // ถ้าปริมาณอาหาร มากกว่าปริมาณแจ้งเตือน ถึงจะคำนวณวันได้
      if (amount > threshold) {
        // หาว่าใช้เวลากี่วันถึงจะลดไปถึงจุด threshold
        daysLeft = ((amount - threshold) / consumePerDay).ceil();
      }

      setState(() {
        // เอาวันที่เริ่มต้น + จำนวนวันที่อยู่ได้
        _selectedExpiryDate = startDate.add(Duration(days: daysLeft));

        // อัปเดตไปแสดงผลที่ช่อง TextField ของวันหมดอายุ
        int thaiYear = _selectedExpiryDate!.year + 543;
        String day = _selectedExpiryDate!.day.toString().padLeft(2, '0');
        String month = _selectedExpiryDate!.month.toString().padLeft(2, '0');
        _expireDateController.text = "$day / $month / $thaiYear";
      });
    }
  }

  // 🌟 ฟังก์ชันส่งข้อมูลไปยัง API
  Future<void> _saveFoodData() async {
    final url = Uri.parse('$backendBaseUrl/api/foods');

    // ตรวจสอบก่อนส่งว่ากรอกข้อมูลวันที่หรือยัง
    if (_selectedImportDate == null || _selectedExpiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกวันที่รับเข้าและวันหมดอายุให้ครบถ้วน')),
      );
      return;
    }

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          // 🌟 ส่ง food_id: 1 ไปด้วย เพื่อให้ข้อมูลวิ่งไปทับที่ช่องเดิมเสมอ
          "food_id": 1,
          "quantity_current": double.tryParse(_amountController.text) ?? 0.0,
          "min_quantity": double.tryParse(_thresholdController.text) ?? 0.0,
          "import_volume": double.tryParse(_amountController.text) ?? 0.0,
          "up_quantity": 0.0,

          "import_date": _selectedImportDate!.toUtc().toIso8601String(),
          "expiry_date": _selectedExpiryDate!.toUtc().toIso8601String(),
          "date_up": DateTime.now().toUtc().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เพิ่มข้อมูลคลังอาหารสำเร็จ!')),
        );
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกไม่สำเร็จ (${response.statusCode}): ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e')),
      );
    }
  }

  void onTabSelected(int index) {
    if (index == 0) {
       Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CloseOpenDoor()));
    } else if(index == 3){
       Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Mainchicken()));
    } else if (index == 4) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainShowDataFood()));
    } else if(index == 2){
       Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ShowChart()));
    } else {
      setState(() { selectedIndex = index; });
    }
  }

  // 🌟 ฟังก์ชันเปิดปฏิทินที่บันทึกค่าลงตัวแปร DateTime ด้วย
  Future<void> _selectDate(BuildContext context, TextEditingController controller, bool isImportDate) async {
    DateTime initialDate = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6FE975),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isImportDate) {
          _selectedImportDate = picked;
        } else {
          _selectedExpiryDate = picked;
        }

        int thaiYear = picked.year + 543;
        String day = picked.day.toString().padLeft(2, '0');
        String month = picked.month.toString().padLeft(2, '0');
        controller.text = "$day / $month / $thaiYear";

        // 🌟 ถ้าผู้ใช้เปลี่ยนวันนำเข้าใหม่ ให้คำนวณวันหมดอายุใหม่ด้วย
        if (isImportDate) {
          _calculateExpiryDate();
        }
      });
    }
  }

  // 🌟 เพิ่มพารามิเตอร์ keyboardType เข้ามา เพื่อให้กำหนดเป็นตัวเลขได้
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    VoidCallback? onTap,
    bool showCalendarIcon = false, 
    TextInputType? keyboardType, 
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          SizedBox(
            width: 140, 
            child: Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: Text(
                label,
                style: GoogleFonts.kanit(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.white), 
                textAlign: TextAlign.end, 
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36, 
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2933).withOpacity(0.5), 
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.0), 
                    ),
                    child: TextField(
                      controller: controller,
                      readOnly: readOnly,
                      onTap: onTap,
                      keyboardType: keyboardType, // 🌟 ใช้งาน keyboardType
                      style: GoogleFonts.kanit(fontSize: 16, color: Colors.white, fontWeight: FontWeight.normal),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                if (showCalendarIcon) ...[
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: onTap,
                    child: const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 22),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(
            height: screenHeight,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Food.png'),
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
                    width: 340, 
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2933), 
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4), 
                          blurRadius: 8,
                          offset: const Offset(0, 4)
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "เพิ่มข้อมูลคลังอาหาร",
                          style: GoogleFonts.kanit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white) 
                        ),
                        const SizedBox(height: 25), 

                        _buildTextField(
                          label: "วันที่นำอาหารเข้า",
                          controller: _dateReceivedController,
                          readOnly: true,
                          onTap: () => _selectDate(context, _dateReceivedController, true), 
                          showCalendarIcon: true, 
                        ),
                        // 🌟 เพิ่ม keyboardType ให้ขึ้นแป้นพิมพ์ตัวเลข
                        _buildTextField(
                          label: "ปริมาณที่นำเข้า",
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        // 🌟 เพิ่ม keyboardType ให้ขึ้นแป้นพิมพ์ตัวเลข
                        _buildTextField(
                          label: "กำหนดปริมาณใกล้หมด",
                          controller: _thresholdController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        _buildTextField(
                          label: "วันที่อาหารใกล้หมด",
                          controller: _expireDateController,
                          readOnly: true,
                          // ยังคงปุ่มเปิดปฏิทินไว้ เผื่อแอดมินต้องการแก้ไขวันที่คำนวณอัตโนมัติ
                          onTap: () => _selectDate(context, _expireDateController, false), 
                          showCalendarIcon: true, 
                        ),

                        const SizedBox(height: 20), 

                        GestureDetector(
                          onTap: () => _saveFoodData(),
                          child: Container(
                            width: double.infinity, 
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6FE975), 
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  offset: const Offset(0, 3),
                                  blurRadius: 4
                                )
                              ],
                            ),
                            child: Center(
                              child: Text(
                                "เข้าสต็อกอาหาร",
                                style: GoogleFonts.kanit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(selectedIndex: selectedIndex, onTabSelected: onTabSelected),
    );
  }
}