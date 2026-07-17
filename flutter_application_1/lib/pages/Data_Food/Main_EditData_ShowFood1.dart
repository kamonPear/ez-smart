import 'dart:convert'; // 🌟 เพิ่มสำหรับการแปลงข้อมูลเป็น JSON
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // 🌟 เพิ่มสำหรับเรียก API

import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bottombar.dart';
import '../close_open_Door.dart';       

class MainEditdataShowfood1 extends StatefulWidget {
  final Map<String, String> initialData;

  const MainEditdataShowfood1({super.key, required this.initialData});

  @override
  State<MainEditdataShowfood1> createState() => _MainEditdataShowfood1State();
}

class _MainEditdataShowfood1State extends State<MainEditdataShowfood1> {
  int selectedIndex = 4;
  bool _isLoading = false; // 🌟 ตัวแปรสำหรับแสดงสถานะ Loading

  late TextEditingController _dateReceivedController;
  late TextEditingController _amountController;
  late TextEditingController _expireDateController;
  late TextEditingController _thresholdController;

  @override
  void initState() {
    super.initState();
    _dateReceivedController = TextEditingController(text: widget.initialData['receiveDate']);
    _expireDateController = TextEditingController(text: widget.initialData['expireDate']);
    
    String amountText = widget.initialData['amount']?.replaceAll(' กิโลกรัม', '') ?? '';
    String thresholdText = widget.initialData['threshold']?.replaceAll(' กิโลกรัม', '') ?? '';
    
    _amountController = TextEditingController(text: amountText);
    _thresholdController = TextEditingController(text: thresholdText);
  }

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
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CloseOpenDoor()));
    } else if (index == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Mainchicken()));
    } else if (index == 4) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainShowDataFood()));
    } else if (index == 2) {
       Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ShowChart()));
    } else {
      setState(() { selectedIndex = index; });
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime initialDate = DateTime.now();
    if (controller.text.isNotEmpty) {
      try {
        List<String> parts = controller.text.split('/');
        if (parts.length == 3) {
          int day = int.parse(parts[0].trim());
          int month = int.parse(parts[1].trim());
          int year = int.parse(parts[2].trim()) - 543; 
          initialDate = DateTime(year, month, day);
        }
      } catch (e) {
        initialDate = DateTime.now();
      }
    }

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
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF6FE975)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        int thaiYear = picked.year + 543;
        String day = picked.day.toString().padLeft(2, '0');
        String month = picked.month.toString().padLeft(2, '0');
        controller.text = "$day / $month / $thaiYear";
      });
    }
  }

  // 🌟 ฟังก์ชันช่วยแปลงวันที่จาก "DD / MM / YYYY" (พ.ศ.) เป็น "YYYY-MM-DDT00:00:00Z" (ค.ศ. สากลสำหรับ Go Backend)
  String _formatDateForGo(String thaiDateStr) {
    if (thaiDateStr.isEmpty) return "";
    try {
      List<String> parts = thaiDateStr.split('/');
      if (parts.length == 3) {
        int day = int.parse(parts[0].trim());
        int month = int.parse(parts[1].trim());
        int year = int.parse(parts[2].trim()) - 543;
        
        String d = day.toString().padLeft(2, '0');
        String m = month.toString().padLeft(2, '0');
        
        return "$year-$m-${d}T00:00:00Z";
      }
    } catch (e) {
      print("แปลงวันที่ผิดพลาด: $e");
    }
    return DateTime.now().toUtc().toIso8601String();
  }

  // 🌟 ฟังก์ชันหลักสำหรับบันทึกการแก้ไขไปยัง Go Backend API
  Future<void> _updateDataToAPI() async {
    // ดักจับ Error: เช็คว่ามี ID ส่งมาให้หน้านี้จริงหรือไม่
    String foodIdStr = widget.initialData['id'] ?? '';
    if (foodIdStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบ ID ของรายการนี้ ไม่สามารถแก้ไขได้'), backgroundColor: Colors.red),
      );
      print("🚨 ข้อมูล widget.initialData ไม่มี Key 'id' หรือค่าเป็น null");
      return; 
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var url = Uri.parse('http://10.0.2.2:8080/api/foods?id=$foodIdStr'); 

      String amountVal = _amountController.text.replaceAll(' กิโลกรัม', '').trim();
      String thresholdVal = _thresholdController.text.replaceAll(' กิโลกรัม', '').trim();

      // แปลงเป็นทศนิยมเพื่อให้ตรงกับ float64 ของ Go
      double quantity = double.tryParse(amountVal) ?? 0.0;
      double minQuantity = double.tryParse(thresholdVal) ?? 0.0;

      String isoImportDate = _formatDateForGo(_dateReceivedController.text);
      String isoExpireDate = _formatDateForGo(_expireDateController.text);

      var requestBody = {
        "quantity_current": quantity,
        "min_quantity": minQuantity,
        "import_date": isoImportDate, 
        "expiry_date": isoExpireDate,
        "date_up": DateTime.now().toUtc().toIso8601String(), 
      };

      print("📦 ข้อมูลที่จะส่งไป Go: ${jsonEncode(requestBody)}"); 

      var response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody), 
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('บันทึกการแก้ไขสำเร็จ!'), backgroundColor: Colors.green),
          );
          
          Map<String, String> updatedDataForUI = {
            "id": foodIdStr,
            "receiveDate": _dateReceivedController.text, 
            "amount": "$amountVal กิโลกรัม",
            "expireDate": _expireDateController.text,
            "threshold": "$thresholdVal กิโลกรัม",
          };
          Navigator.pop(context, updatedDataForUI);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.statusCode}'), backgroundColor: Colors.red),
          );
          print("🚨 Go Error Response: ${response.body}"); 
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; 
        });
      }
    }
  }

  Widget _buildTextFieldGroup(String label, TextEditingController controller, {bool readOnly = false, VoidCallback? onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
          child: Text(
            label,
            style: GoogleFonts.kanit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        Container(
          height: 45,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F0F0),
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextField(
            controller: controller, 
            readOnly: readOnly,     
            onTap: onTap,           
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

  Widget _buildActionButton(String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap, 
      child: Container(
        width: 120,
        height: 50,
        decoration: BoxDecoration(
          color: _isLoading ? Colors.grey : color, 
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
            style: GoogleFonts.kanit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
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
          // พื้นหลัง
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

          // ฟอร์มเนื้อหา
          Positioned(
            top: 280,
            left: 0,
            right: 0,
            bottom: 80,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBDDDE9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text("แก้ไขข้อมูลคลังอาหาร", style: GoogleFonts.kanit(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black)),
                        const SizedBox(height: 20),
                        _buildTextFieldGroup("วัน / เดือน / ปี ที่รับอาหารเข้า", _dateReceivedController, readOnly: true, onTap: () => _selectDate(context, _dateReceivedController)),
                        _buildTextFieldGroup("จำนวนอาหารที่รับเข้า (กิโลกรัม)", _amountController),
                        _buildTextFieldGroup("วันอาหารจะหมดอายุ", _expireDateController, readOnly: true, onTap: () => _selectDate(context, _expireDateController)),
                        _buildTextFieldGroup("กำหนดค่าปริมาณใกล้จะหมด (กิโลกรัม)", _thresholdController),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton("บันทึก", const Color(0xFF66E675), () {
                        _updateDataToAPI(); 
                      }),
                      _buildActionButton("ยกเลิก", const Color(0xFFEB856D), () {
                        Navigator.pop(context);
                      }),
                    ],
                  ),
                  const SizedBox(height: 50), 
                ],
              ),
            ),
          ),

          // Header
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                height: 160,
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Stack(
                  children: [
                    Positioned(left: 0, top: 0, child: Image.asset('assets/images/logo.png', width: 120, height: 120)),
                    Positioned(
                      left: 135, top: 25,
                      child: Text('EZ -\nSMART\nFARM', style: GoogleFonts.kanit(fontSize: 28, height: 1.1, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    Positioned(
                      right: 0, bottom: 20,
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Notifications())),
                        child: const Icon(Icons.notifications_active, color: Colors.black87, size: 32),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // แสดง Loading ซ้อนทับบนสุดเมื่อกำลังโหลด
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6FE975)),
                ),
              ),
            ),
        ],
      ),

      bottomNavigationBar: CustomBottomBar(selectedIndex: selectedIndex, onTabSelected: onTabSelected),
    );
  }
}