import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../bottombar.dart';
import '../../services/backend_config.dart';
import '../../widgets/ez_header.dart';

class AddDataadopt extends StatefulWidget {
  const AddDataadopt({super.key});

  @override
  State<AddDataadopt> createState() => _AddDataadoptState();
}

class _AddDataadoptState extends State<AddDataadopt> {
  int selectedIndex = 0;

  final TextEditingController importDateController = TextEditingController();
  final TextEditingController countController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  // ตัวแปรสำหรับปฏิทินที่สร้างขึ้นเอง
  DateTime? selectedDate;
  DateTime currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    // ตั้งค่าเริ่มต้นของวันที่นำเข้าเป็นวันนี้
    selectedDate = DateTime.now();
    currentMonth = DateTime(selectedDate!.year, selectedDate!.month, 1);
    importDateController.text = "${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}";
  }

  // แปลงวันที่ให้ตรงกับที่ Backend (Go) ต้องการเป๊ะๆ
  String _toISO8601(String dateStr) {
    if (dateStr.isEmpty) return '';
    final parts = dateStr.split('/');
    if (parts.length != 3) return '';
    final day = parts[0].padLeft(2, '0');
    final month = parts[1].padLeft(2, '0');
    final year = parts[2];
    
    return '$year-$month-${day}T00:00:00Z'; 
  }

  void onTabSelected(int index) {
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
    } else if (index == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Mainchicken()));
    } else if (index == 4) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainShowDataFood()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CloseOpenDoor()));
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ShowChart()));
    } else {
      setState(() { selectedIndex = index; });
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      helpText: 'เลือกวันที่',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF66E07A), // หัวปฏิทิน
              onPrimary: Colors.white,
              surface: Color(0xFF19232F), // พื้นหลังปฏิทิน
              onSurface: Colors.white, // ตัวหนังสือวันที่
            ),
            dialogBackgroundColor: const Color(0xFF19232F),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _submitData() async {
    if (importDateController.text.isEmpty ||
        countController.text.isEmpty ||
        birthDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'กรุณากรอกวันที่นำเข้า, จำนวนไก่ และวันเกิดให้ครบ',
            style: GoogleFonts.kanit(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final int? count = int.tryParse(countController.text.trim());
    if (count == null || count <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('จำนวนไก่ต้องเป็นตัวเลขที่มากกว่า 0', style: GoogleFonts.kanit()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF66E07A)),
      ),
    );

    try {
      final body = jsonEncode({
        "date_adopt_animals": _toISO8601(importDateController.text),
        "amount": count,
        "birthday": _toISO8601(birthDateController.text),
        "note": noteController.text.trim().isEmpty ? '-' : noteController.text.trim(),
      });

      debugPrint('POST /api/coops body: $body');
      final response = await http.post(
        Uri.parse('$backendBaseUrl/api/coops'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );
      
      Navigator.pop(context); // ปิด Dialog โหลด

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        Map<String, String> newData = {
          "id": responseData["CoopID"]?.toString() ?? responseData["coop_id"]?.toString() ?? '',
          "importDate": importDateController.text,
          "count": "${count} ตัว",
          "birthDate": birthDateController.text,
          "note": noteController.text.isNotEmpty ? noteController.text : "-",
        };

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกข้อมูลสำเร็จ!', style: GoogleFonts.kanit()),
            backgroundColor: const Color(0xFF66E07A),
          ),
        );

        Navigator.pop(context, newData);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'เกิดข้อผิดพลาด: ${response.statusCode} - ${response.body}',
              style: GoogleFonts.kanit(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // ปิด Dialog โหลด
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถเชื่อมต่อ Server ได้: $e', style: GoogleFonts.kanit()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ชื่อเดือนแบบภาษาอังกฤษ
  String _getMonthName(int month) {
    const months = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
    ];
    return months[month - 1];
  }

  // วิดเจ็ตฟอร์มกรอกข้อมูลตาม Design
  Widget _buildModernInputRow({
    required String label,
    required TextEditingController controller,
    String? suffixText,
    Widget? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: GoogleFonts.kanit(color: Colors.white, fontSize: 16)),
            const SizedBox(width: 15),
            Expanded(
              child: TextFormField(
                controller: controller,
                readOnly: readOnly,
                onTap: onTap,
                keyboardType: keyboardType,
                textAlign: TextAlign.right,
                style: GoogleFonts.kanit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  hintText: '',
                  hintStyle: const TextStyle(color: Colors.white54),
                ),
              ),
            ),
            if (suffixText != null)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(suffixText, style: GoogleFonts.kanit(color: Colors.white, fontSize: 16)),
              ),
            if (suffixIcon != null)
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: suffixIcon,
              ),
          ],
        ),
        const SizedBox(height: 5),
        Container(height: 2, color: const Color(0xFF67B5B6)), // เส้นใต้สีฟ้าตามแบบ
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // คำนวณวันสำหรับปฏิทิน
    int daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    int firstWeekday = DateTime(currentMonth.year, currentMonth.month, 1).weekday; 
    int offset = firstWeekday - 1; 

    return Scaffold(
      extendBody: true,
      backgroundColor: ezBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const EzHeader(pageTitle: 'เพิ่มคอก'),
                const SizedBox(height: 20),

                // 🔹 ส่วนปฏิทิน
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF19232F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => currentMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1)),
                            child: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                          ),
                          Text(
                            '${_getMonthName(currentMonth.month)} ${currentMonth.year}',
                            style: GoogleFonts.kanit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1)),
                            child: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: ['MON', 'TUES', 'WEDNES', 'THURS', 'FRI', 'SATUR', 'SUN'].map((day) => 
                          Expanded(
                            child: Center(
                              child: Text(day, style: GoogleFonts.kanit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
                            ),
                          )
                        ).toList(),
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: offset + daysInMonth,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 1.2,
                        ),
                        itemBuilder: (context, index) {
                          if (index < offset) return const SizedBox();
                          int day = index - offset + 1;
                          bool isSelected = selectedDate != null && 
                                            selectedDate!.year == currentMonth.year && 
                                            selectedDate!.month == currentMonth.month && 
                                            selectedDate!.day == day;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedDate = DateTime(currentMonth.year, currentMonth.month, day);
                                importDateController.text = "${day.toString().padLeft(2, '0')}/${currentMonth.month.toString().padLeft(2, '0')}/${currentMonth.year}";
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF66E07A) : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  day.toString(),
                                  style: GoogleFonts.kanit(
                                    color: isSelected ? Colors.black : Colors.white,
                                    fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 🔹 ส่วนข้อมูลไก่
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: const Color(0xFF19232F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'ข้อมูลไก่',
                        style: GoogleFonts.kanit(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 25),
                      _buildModernInputRow(
                        label: 'จำนวนไก่',
                        controller: countController,
                        suffixText: 'ตัว',
                        keyboardType: TextInputType.number,
                      ),
                      _buildModernInputRow(
                        label: 'วันเกิดไก่',
                        controller: birthDateController,
                        readOnly: true,
                        onTap: () => _selectDate(context, birthDateController),
                        suffixIcon: const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 24),
                      ),
                      _buildModernInputRow(
                        label: 'หมายเหตุ',
                        controller: noteController,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // 🔹 ปุ่มบันทึก (เพิ่มคอก)
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _submitData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF66E07A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      'เพิ่มคอก',
                      style: GoogleFonts.kanit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 100), // เว้นที่สำหรับ BottomNavigationBar
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomBar(selectedIndex: selectedIndex, onTabSelected: onTabSelected),
    );
  }
}