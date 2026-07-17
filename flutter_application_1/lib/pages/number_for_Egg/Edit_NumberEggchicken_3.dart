import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../bottombar.dart';
import '../../services/backend_config.dart'; 

class EditNumbereggchicken extends StatefulWidget {
  final Map<String, dynamic> initialData; 

  const EditNumbereggchicken({super.key, required this.initialData});

  @override
  State<EditNumbereggchicken> createState() => _EditNumbereggchickenState();
}

class _EditNumbereggchickenState extends State<EditNumbereggchicken> {
  int selectedIndex = 0;

  late TextEditingController _eggIdController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  String _rawDateToSave = ""; 

  @override
  void initState() {
    super.initState();
    _eggIdController = TextEditingController(text: widget.initialData['id']?.toString());
    _rawDateToSave = widget.initialData['date']?.toString() ?? "";
    
    String countText = widget.initialData['count']?.toString().replaceAll(' ฟอง', '') ?? '';
    _amountController = TextEditingController(text: countText);
    
    _noteController = TextEditingController(text: widget.initialData['note']?.toString());
  }

  @override
  void dispose() {
    _eggIdController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void onTabSelected(int index) {
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
    } else if(index == 3){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Mainchicken()));
    } else if(index == 4){
       Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainShowDataFood()));
    } else if(index == 1){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CloseOpenDoor()));
    }else if(index == 2){
       Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ShowChart()));
    } else {
      setState(() {
        selectedIndex = index;
      });
    }
  }

  Future<void> _updateEggData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF6FE975))),
    );

    try {
      String id = _eggIdController.text;
      
      // 🌟 ดักจับ ID หายเพื่อความปลอดภัย
      if (id.isEmpty || id == "null") {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ข้อผิดพลาด: ไม่พบ ID ของข้อมูล', style: GoogleFonts.kanit()), backgroundColor: Colors.red),
        );
        return;
      }

      // 🌟 ปรับปรุงการจัดการวันที่แบบรัดกุมที่สุด (Bulletproof Date Parsing)
      String dateToSend = _rawDateToSave.trim();
      String isoDate;

      try {
        if (dateToSend.isEmpty || dateToSend == "null") {
          // หากไม่มีข้อมูลวันที่ ให้ใช้วันที่และเวลาปัจจุบันแทน
          isoDate = DateTime.now().toUtc().toIso8601String();
        } else if (dateToSend.contains('/')) {
          // แปลงวันที่แบบไทย DD/MM/YYYY
          List<String> parts = dateToSend.split('/');
          int day = int.parse(parts[0].trim());
          int month = int.parse(parts[1].trim());
          int year = int.parse(parts[2].trim());
          if (year > 2500) year -= 543;
          isoDate = DateTime.utc(year, month, day).toIso8601String();
        } else {
          // ให้ Dart จัดการวันที่รูปแบบแปลกๆ อัตโนมัติ (เช่น มีช่องว่าง, ไม่มี T)
          isoDate = DateTime.parse(dateToSend).toUtc().toIso8601String();
        }
      } catch (e) {
        // กันเหนียว: หากรูปแบบข้อมูลพังจนแปลงไม่ได้จริงๆ ให้ใช้วันที่ปัจจุบัน
        isoDate = DateTime.now().toUtc().toIso8601String();
      }

      // แพ็คข้อมูล JSON
      Map<String, dynamic> requestBody = {
        "coop_id": int.tryParse(widget.initialData['coop_id']?.toString() ?? '0') ?? 0,
        "date_collect_egg": isoDate,
        "number_egg": int.tryParse(_amountController.text.trim()) ?? 0,
        "note": _noteController.text,
      };

      print("🚀 Data sending to API: ${jsonEncode(requestBody)}");

      final response = await http.put(
        Uri.parse('$backendBaseUrl/api/eggs?id=$id'), 
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); 

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('อัปเดตข้อมูลสำเร็จ', style: GoogleFonts.kanit()), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); 
      } else {
        String errorMsg = 'เกิดข้อผิดพลาด (${response.statusCode})';
        try {
          var errorData = jsonDecode(response.body);
          if (errorData['error'] != null) { 
            errorMsg = errorData['error'];
          } else if (errorData['message'] != null) {
            errorMsg = errorData['message'];
          } else {
             errorMsg = response.body;
          }
        } catch (_) {
          errorMsg = response.body.isNotEmpty ? response.body : errorMsg;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เซิร์ฟเวอร์ปฏิเสธ: $errorMsg', style: GoogleFonts.kanit()), 
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เชื่อมต่อเซิร์ฟเวอร์ล้มเหลว: $e', style: GoogleFonts.kanit()), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildDarkTextFieldRow({
    required String label, 
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0, left: 20, right: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.kanit(
                fontSize: 16,
                fontWeight: FontWeight.bold, 
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 40, 
              decoration: BoxDecoration(
                color: const Color(0xFF151C22), 
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.4), width: 1.5), 
              ),
              child: TextFormField(
                controller: controller, 
                keyboardType: keyboardType, 
                style: GoogleFonts.kanit(
                  fontSize: 15, 
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  isDense: true,
                  hintStyle: GoogleFonts.kanit(color: Colors.white54),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    // ดึงเลขคอกมาจากข้อมูลเริ่มต้นเพื่อนำไปแสดงผลบนหัวข้อการ์ด
    String coopId = widget.initialData['coop_id']?.toString() ?? '-';

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true, 
      
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
          // 1. ภาพพื้นหลังเดิมของคุณ
          Container(
            height: screenHeight,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/egg.png'),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),

          // 2. การ์ดแก้ไขข้อมูลจัดให้อยู่ตรงกลางหน้าจอ
          Center(
            child: SingleChildScrollView( 
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 25),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2933), 
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    const SizedBox(height: 30),

                    // 🌟 ปรับหัวข้อให้แสดง "เลขคอก" ที่กำลังแก้ไข
                    Text(
                      "แก้ไขข้อมูลคอกที่ $coopId",
                      style: GoogleFonts.kanit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 25),

                    // ช่องกรอก จำนวนไข่
                    _buildDarkTextFieldRow(
                      label: "จำนวนไข่", 
                      controller: _amountController,
                      keyboardType: TextInputType.number, 
                    ),
                    
                    // ช่องกรอก หมายเหตุ
                    _buildDarkTextFieldRow(
                      label: "หมายเหตุ", 
                      controller: _noteController
                    ),

                    const SizedBox(height: 10),

                    // ปุ่มบันทึกการแก้ไข
                    GestureDetector(
                      onTap: () {
                        if (_amountController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('กรุณากรอกจำนวนไข่', style: GoogleFonts.kanit()), backgroundColor: Colors.red),
                          );
                          return;
                        }
                        _updateEggData();
                      },
                      child: Container(
                        height: 55,
                        decoration: const BoxDecoration(
                          color: Color(0xFF43A047), 
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 20),
                            const Icon(Icons.feed_outlined, color: Colors.white, size: 28), 
                            Expanded(
                              child: Center(
                                child: Text(
                                  "บันทึกการแก้ไข",
                                  style: GoogleFonts.kanit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 48), 
                          ],
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