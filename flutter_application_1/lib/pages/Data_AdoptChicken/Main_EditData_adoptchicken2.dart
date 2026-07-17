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
import 'package:intl/intl.dart'; // อย่าลืม import intl สำหรับจัดการเดือน
import '../bottombar.dart';
import '../../services/backend_config.dart';

class EditDataAdoptchicken extends StatefulWidget {
  final Map<String, String> initialData;

  const EditDataAdoptchicken({super.key, required this.initialData});

  @override
  State<EditDataAdoptchicken> createState() => _EditDataAdoptchickenState();
}

class _EditDataAdoptchickenState extends State<EditDataAdoptchicken> {
  int selectedIndex = 0;

  late TextEditingController idController;
  late TextEditingController importDateController;
  late TextEditingController countController;
  late TextEditingController birthDateController;
  late TextEditingController noteController;

  // สำหรับจัดการปฏิทินที่หน้าจอ
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    idController = TextEditingController(text: widget.initialData['id']);
    importDateController = TextEditingController(text: widget.initialData['importDate']);
    
    String countText = widget.initialData['count']?.replaceAll(' ตัว', '') ?? '';
    countController = TextEditingController(text: countText);
    
    birthDateController = TextEditingController(text: widget.initialData['birthDate']);
    noteController = TextEditingController(text: widget.initialData['note']);

    // พยายามตั้งค่าวันที่เริ่มต้นบนปฏิทินจากข้อมูลที่มี
    if (importDateController.text.isNotEmpty) {
      try {
        List<String> parts = importDateController.text.split(RegExp(r'\s*/\s*'));
        if (parts.length == 3) {
          int day = int.parse(parts[0].trim());
          int month = int.parse(parts[1].trim());
          int year = int.parse(parts[2].trim());
          if (year > 2500) year -= 543;
          _selectedDate = DateTime(year, month, day);
          _focusedMonth = DateTime(year, month, 1);
        }
      } catch (e) {
        _focusedMonth = DateTime.now();
      }
    }
  }

  @override
  void dispose() {
    idController.dispose();
    importDateController.dispose();
    countController.dispose();
    birthDateController.dispose();
    noteController.dispose();
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

  // ปฏิทินแบบ Popup สำหรับวันเกิดไก่
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime initialDate = DateTime.now();
    
    if (controller.text.isNotEmpty) {
      try {
        List<String> parts = controller.text.split(RegExp(r'\s*/\s*'));
        if (parts.length == 3) {
          int day = int.parse(parts[0].trim());
          int month = int.parse(parts[1].trim());
          int year = int.parse(parts[2].trim());
          if (year > 2500) year -= 543;
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
      helpText: 'เลือกวันที่', 
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
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
        controller.text = "$day / $month / $thaiYear";
      });
    }
  }

  Future<void> _updateData() async {
    final String id = idController.text.trim();
    final String importDateRaw = importDateController.text.trim();
    final String countRaw = countController.text.trim();
    final String birthDateRaw = birthDateController.text.trim();
    final String noteRaw = noteController.text.trim();

    String toISO8601(String dateStr) {
      if (dateStr.isEmpty) return '';
      final parts = dateStr.split(RegExp(r'\s*/\s*'));
      if (parts.length != 3) return '';
      final day = parts[0].padLeft(2, '0');
      final month = parts[1].padLeft(2, '0');
      int year = int.parse(parts[2]);
      if (year > 2500) year -= 543;
      return '$year-$month-${day}T00:00:00Z';
    }

    String toDisplayFormat(String dateStr) {
      if (dateStr.isEmpty) return '';
      final parts = dateStr.split(RegExp(r'\s*/\s*'));
      if (parts.length != 3) return '';
      final day = parts[0].padLeft(2, '0');
      final month = parts[1].padLeft(2, '0');
      int year = int.parse(parts[2]);
      if (year > 2500) year -= 543;
      return '$day/$month/$year';
    }

    int? amount = int.tryParse(countRaw);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF6FE975)),
      ),
    );

    try {
      final body = jsonEncode({
        "date_adopt_animals": toISO8601(importDateRaw),
        "amount": amount ?? 0,
        "birthday": toISO8601(birthDateRaw),
        "note": noteRaw.isEmpty ? "-" : noteRaw,
      });

      final response = await http.put(
        Uri.parse('$backendBaseUrl/api/coops?id=$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (response.statusCode == 200) {
        Map<String, String> updatedData = {
          "id": id,
          "importDate": toDisplayFormat(importDateRaw),
          "count": "${amount ?? 0} ตัว",
          "birthDate": toDisplayFormat(birthDateRaw),
          "note": noteRaw.isEmpty ? "-" : noteRaw,
        };

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('แก้ไขข้อมูลสำเร็จ', style: GoogleFonts.kanit()),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, updatedData);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการแก้ไข: ${response.statusCode}', style: GoogleFonts.kanit()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $e', style: GoogleFonts.kanit()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- Widget ส่วนประกอบ UI ใหม่ตามแบบในรูป ---

  Widget _buildCustomCalendar() {
    List<String> daysOfWeek = ['MON', 'TUES', 'WEDNES', 'THURS', 'FRI', 'SATUR', 'SUN'];
    int daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    DateTime firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    int firstWeekdayOffset = firstDayOfMonth.weekday - 1; // 0 = Mon, 6 = Sun

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E282E), // สีพื้นหลัง Dark ตามรูป
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Header เดือนและปี
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                  });
                },
                child: const Icon(Icons.chevron_left, color: Colors.white, size: 24),
              ),
              Text(
                DateFormat('MMMM yyyy').format(_focusedMonth).toUpperCase(),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                  });
                },
                child: const Icon(Icons.chevron_right, color: Colors.white, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // วันในสัปดาห์
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: daysOfWeek.map((day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 10),

          // Grid วันที่
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42, // สร้างช่อง 6 แถว แถวละ 7 วัน
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              int day = index - firstWeekdayOffset + 1;
              bool isCurrentMonth = day > 0 && day <= daysInMonth;

              if (!isCurrentMonth) {
                return const SizedBox.shrink(); // ช่องว่างสำหรับวันก่อนหน้า/ถัดไป
              }

              DateTime currentDate = DateTime(_focusedMonth.year, _focusedMonth.month, day);
              bool isSelected = _selectedDate != null &&
                  currentDate.year == _selectedDate!.year &&
                  currentDate.month == _selectedDate!.month &&
                  currentDate.day == _selectedDate!.day;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = currentDate;
                    int thaiYear = currentDate.year + 543;
                    String d = currentDate.day.toString().padLeft(2, '0');
                    String m = currentDate.month.toString().padLeft(2, '0');
                    importDateController.text = "$d / $m / $thaiYear";
                  });
                },
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF6FE975).withOpacity(0.3) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      day.toString(),
                      style: GoogleFonts.inter(
                        color: isSelected ? const Color(0xFF6FE975) : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDarkTextFieldRow(String label, TextEditingController controller, {String? suffixText, bool isDate = false, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white54, width: 1.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.kanit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: isDate ? onTap : null,
              child: AbsorbPointer(
                absorbing: isDate, // ถ้ารับวันที่ให้ดักจับ event เพื่อไปแสดง DatePicker
                child: TextFormField(
                  controller: controller,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.kanit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    suffixIcon: suffixText != null 
                        ? Padding(
                            padding: const EdgeInsets.only(left: 5),
                            child: Text(
                              suffixText,
                              style: GoogleFonts.kanit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : (isDate ? const Padding(padding: EdgeInsets.only(left: 10), child: Icon(Icons.calendar_today, color: Colors.white, size: 20)) : null),
                  ),
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

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // พื้นหลังยังคงใช้งานอยู่ตามที่ Request (ไม่ถูกลบ)
          Container(
            height: screenHeight,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Editcoop.png'),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header (App Bar แบบ Custom มีปุ่ม Back)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      
                      const SizedBox(width: 48), // Spacer สำหรับ Balance ให้ Title อยู่ตรงกลาง
                    ],
                  ),
                ),

                // พื้นที่เนื้อหาหลักแบบเลื่อนได้
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // 👇 เพิ่มตรงนี้เพื่อดันปฏิทินลงมา ไม่ให้ทับหัวพื้นหลัง (ปรับตัวเลขตามต้องการ)
                        const SizedBox(height: 100), 

                        // ปฏิทินเลือกวัน
                        _buildCustomCalendar(),
                        const SizedBox(height: 20),

                        // กล่องข้อมูลไก่ (Data Container)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E282E),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "ข้อมูลไก่",
                                style: GoogleFonts.kanit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 25),

                              _buildDarkTextFieldRow(
                                "จำนวนไก่",
                                countController,
                                suffixText: " ตัว",
                              ),
                              _buildDarkTextFieldRow(
                                "วันเกิดไก่",
                                birthDateController,
                                isDate: true,
                                onTap: () => _selectDate(context, birthDateController),
                              ),
                              _buildDarkTextFieldRow(
                                "หมายเหตุ",
                                noteController,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // ปุ่มอัพเดตคอกแบบเต็มความกว้าง
                        GestureDetector(
                          onTap: _updateData,
                          child: Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              color: const Color(0xFF65CC6C), // สีเขียวตรงตามในรูป
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Center(
                              child: Text(
                                "อัพเดตคอก",
                                style: GoogleFonts.kanit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // 👇 เพิ่มความกว้างตรงนี้เพื่อให้หน้าจอเลื่อนขึ้นพ้น Bottom Bar ได้เต็มที่
                        const SizedBox(height: 150), 
                      ],
                    ),
                  ),
                ),
              ],
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