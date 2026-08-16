import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bottombar.dart';
import '../../widgets/ez_header.dart';

import '../../services/backend_config.dart';

class Editckickenhealth extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const Editckickenhealth({super.key, required this.initialData});

  @override
  State<Editckickenhealth> createState() => _EditckickenhealthState();
}

class _EditckickenhealthState extends State<Editckickenhealth> {
  int selectedIndex = 0;

  late TextEditingController _recordIdController;
  late TextEditingController _healthyCountController;
  late TextEditingController _sickCountController;
  late TextEditingController _inspectionDateController;
  late TextEditingController _noteController; 

  @override
  void initState() {
    super.initState();
    
    _recordIdController = TextEditingController(text: widget.initialData['health_id']?.toString() ?? widget.initialData['recordId']?.toString() ?? '-');
    _healthyCountController = TextEditingController(text: widget.initialData['healthy']?.toString() ?? widget.initialData['healthyCount']?.toString() ?? '0');
    _sickCountController = TextEditingController(text: widget.initialData['poor_health']?.toString() ?? widget.initialData['sickCount']?.toString() ?? '0');
    _noteController = TextEditingController(text: widget.initialData['note']?.toString() ?? '');
    
    String initialDateStr = widget.initialData['record_date']?.toString() ?? widget.initialData['inspectionDate']?.toString() ?? '';
    String formattedDate = '';
    if (initialDateStr.isNotEmpty) {
      try {
        DateTime dt = DateTime.parse(initialDateStr).toLocal();
        String day = dt.day.toString().padLeft(2, '0');
        String month = dt.month.toString().padLeft(2, '0');
        int year = dt.year + 543; 
        formattedDate = "$day / $month / $year";
      } catch (_) {
        formattedDate = initialDateStr; 
      }
    }
    _inspectionDateController = TextEditingController(text: formattedDate);
  }

  @override
  void dispose() {
    _recordIdController.dispose();
    _healthyCountController.dispose();
    _sickCountController.dispose();
    _inspectionDateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> updateHealthData() async {
    try {
      List<String> parts = _inspectionDateController.text.split('/');
      String backendDate = widget.initialData['record_date']?.toString() ?? "";
      if (parts.length == 3) {
        int day = int.parse(parts[0].trim());
        int month = int.parse(parts[1].trim());
        int year = int.parse(parts[2].trim()) - 543; 
        backendDate = "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}T00:00:00Z";
      }

      int healthId = int.tryParse(_recordIdController.text) ?? 0;
      int healthyCount = int.tryParse(_healthyCountController.text) ?? 0;
      int sickCount = int.tryParse(_sickCountController.text) ?? 0;

      final url = Uri.parse('$backendBaseUrl/api/healths?id=$healthId');
      
      final requestBody = json.encode({
        "id": healthId, 
        "healthy": healthyCount,
        "poor_health": sickCount,
        "note": _noteController.text, 
        "record_date": backendDate,
      });

      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); 
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกไม่สำเร็จ: ${response.statusCode}', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
      );
    }
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
    } else if(index == 2){
       Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ShowChart()));
    } else {
      setState(() {
        selectedIndex = index;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    try {
      if (_inspectionDateController.text.isNotEmpty) {
        List<String> parts = _inspectionDateController.text.split('/');
        if (parts.length == 3) {
          int day = int.parse(parts[0].trim());
          int month = int.parse(parts[1].trim());
          int year = int.parse(parts[2].trim()) - 543; 
          initialDate = DateTime(year, month, day);
        }
      }
    } catch (e) {
      initialDate = DateTime.now();
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
        _inspectionDateController.text = "$day / $month / $thaiYear";
      });
    }
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? suffixText,
    Widget? suffixIcon,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.kanit(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: GoogleFonts.kanit(fontSize: 16, color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixText: suffixText,
              suffixStyle: GoogleFonts.kanit(fontSize: 16, color: Colors.white),
              suffixIcon: suffixIcon,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.blueAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // ทำให้พื้นหลังไหลทะลุไปใต้ BottomNavigationBar ได้
      backgroundColor: ezBackgroundColor,
      body: SafeArea(
        child: Container(
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          // ใช้ Padding จัดการระยะเว้นขอบบน-ล่าง แทนการใช้ Stack/Positioned
          padding: EdgeInsets.only(
            top: 10,
            left: 20,
            right: 20,
            // เผื่อพื้นที่ด้านล่าง 120 (สำหรับ BottomBar) + ขนาดคีย์บอร์ดตอนเด้งขึ้นมา
            bottom: MediaQuery.of(context).viewInsets.bottom + 120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EzHeader(pageTitle: 'แก้ไขสุขภาพไก่'),
              const SizedBox(height: 20),
              Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2733), 
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 5,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.lightBlueAccent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "แก้ไขข้อมูลการตรวจสุขภาพ", 
                          style: GoogleFonts.kanit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.calendar_month, color: Colors.white70),
                  ],
                ),
                const SizedBox(height: 25),

                // Input Fields
                _buildInputField(
                  label: "วันที่ตรวจไก่", 
                  controller: _inspectionDateController,
                  suffixIcon: const Icon(Icons.calendar_today, color: Colors.white70, size: 20),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
                _buildInputField(
                  label: "จำนวนไก่ที่สุขภาพดี (ตัว)", 
                  controller: _healthyCountController, 
                  suffixText: "ตัว",
                  keyboardType: TextInputType.number, 
                ),
                _buildInputField(
                  label: "จำนวนไก่ที่สุขภาพไม่ดี (ตัว)", 
                  controller: _sickCountController, 
                  suffixText: "ตัว",
                  keyboardType: TextInputType.number,
                ),
                _buildInputField(
                  label: "หมายเหตุ", 
                  controller: _noteController,
                  maxLines: 3,
                ),

                // Info Box
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.white54, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "ระบบจะบันทึกข้อมูลวันที่ตรวจอัตโนมัติ\nเมื่อกดบันทึกข้อมูล",
                          style: GoogleFonts.kanit(fontSize: 12, color: Colors.white54),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 25),

                // Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A5568),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          "ยกเลิก", 
                          style: GoogleFonts.kanit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: updateHealthData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B5A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          "บันทึกข้อมูล", 
                          style: GoogleFonts.kanit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
              ],
            ),
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