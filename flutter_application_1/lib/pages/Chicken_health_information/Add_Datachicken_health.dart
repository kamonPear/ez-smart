import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/pages/calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bottombar.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:flutter_application_1/models/coop.dart'; // 🌟 ปรับ path ให้ตรงกับโครงสร้างโปรเจกต์จริง

// 🌟 URL ของ Backend
const String backendBaseUrl = 'http://10.0.2.2:8080';

class AddDatachickenHealth extends StatefulWidget {
  final String? initialCoopId;

  const AddDatachickenHealth({super.key, this.initialCoopId});

  @override
  State<AddDatachickenHealth> createState() => _AddDatachickenHealthState();
}

class _AddDatachickenHealthState extends State<AddDatachickenHealth> {
  int selectedIndex = 0;
  bool isLoading = false; // สำหรับทำปุ่มโหลด

  DateTime selectedDate = DateTime.now();

  // 🌟 สำหรับ Dropdown เลือกคอก (Coop.id เป็น String ตามโมเดลจริง)
  List<Coop> _coopList = [];
  String? _selectedCoopId;
  bool _isLoadingCoops = true;

  final List<String> monthNames = [
    'JANUARY',
    'FEBRUARY',
    'MARCH',
    'APRIL',
    'MAY',
    'JUNE',
    'JULY',
    'AUGUST',
    'SEPTEMBER',
    'OCTOBER',
    'NOVEMBER',
    'DECEMBER',
  ];

  final TextEditingController _healthyController = TextEditingController(
    text: '180',
  );
  final TextEditingController _unhealthyController = TextEditingController(
    text: '20',
  );
  final TextEditingController _noteController = TextEditingController(
    text: 'ไก่บางตัวซึม ไม่กินอาหาร',
  );

  @override
  void initState() {
    super.initState();
    _fetchCoops(); // 🌟 ดึงรายชื่อคอกตอนเปิดหน้านี้
  }

  @override
  void dispose() {
    _healthyController.dispose();
    _unhealthyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _getFormattedDate(DateTime date) {
    String day = date.day.toString().padLeft(2, '0');
    String month = monthNames[date.month - 1];
    return "$day $month ${date.year}";
  }

  String _getDbFormattedDate(DateTime date) {
    String month = date.month.toString().padLeft(2, '0');
    String day = date.day.toString().padLeft(2, '0');
    // 🌟 เพิ่มเวลาแบบ RFC3339 ต่อท้าย เพราะ Go's time.Time ต้องการ format นี้ตอน JSON unmarshal
    // ถ้าส่งแค่ "2026-06-27" เปล่า ๆ backend จะ parse ไม่ผ่านแล้วตอบ 400 กลับมา
    return "${date.year}-$month-${day}T00:00:00Z";
  }

  // 🌟 ดึงรายชื่อคอกทั้งหมดจาก backend เพื่อมาทำ Dropdown
  Future<void> _fetchCoops() async {
    try {
      final url = Uri.parse('$backendBaseUrl/api/coops');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _coopList = data.map((item) => Coop.fromJson(item)).toList();
          if (_coopList.isNotEmpty) {
            // ✅ ถ้าเปิดหน้านี้มาจากคอกใดคอกหนึ่งโดยเฉพาะ ให้เลือกคอกนั้นไว้ล่วงหน้า
            bool hasInitialCoop =
                widget.initialCoopId != null &&
                _coopList.any((c) => c.id == widget.initialCoopId);
            _selectedCoopId = hasInitialCoop
                ? widget.initialCoopId
                : _coopList.first.id;
          }
          _isLoadingCoops = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoadingCoops = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ดึงรายชื่อคอกไม่สำเร็จ: รหัส ${response.statusCode}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error ดึงข้อมูลคอก: $e");
      if (!mounted) return;
      setState(() => _isLoadingCoops = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ (โหลดคอก): $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // 🌟 ฟังก์ชันส่งข้อมูลเข้า Database
  Future<void> _saveHealthData() async {
    // เช็คว่าเลือกคอกแล้วหรือยัง และแปลงเป็น int ได้จริง
    final int? coopIdValue = int.tryParse(_selectedCoopId ?? '');
    if (coopIdValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'กรุณาเลือกคอกก่อนบันทึก',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final Map<String, dynamic> requestData = {
      'coop_id': coopIdValue, // 🌟 ส่ง coop_id เป็น int ตามที่ backend ต้องการ
      'record_date': _getDbFormattedDate(selectedDate),
      'healthy': int.tryParse(_healthyController.text.trim()) ?? 0,
      'poor_health': int.tryParse(_unhealthyController.text.trim()) ?? 0,
      'note': _noteController.text.trim(),
    };

    print("กำลังส่งข้อมูล API: $requestData"); // เช็คใน Console

    try {
      final url = Uri.parse('$backendBaseUrl/api/healths');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestData),
          )
          .timeout(
            const Duration(seconds: 10),
          ); // ป้องกันแอปค้างถ้าหาเซิร์ฟเวอร์ไม่เจอ

      print("Status Code ที่ตอบกลับ: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'บันทึกข้อมูลสำเร็จ',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'บันทึกไม่สำเร็จ: รหัส ${response.statusCode}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      print("Error เชื่อมต่อ: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showCalendarDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1B242D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              // 🌟 แก้ไข 3: ลบบรรทัด height: 400 ทิ้งไปเลย เพื่อปล่อยให้กล่องปรับความสูงอัตโนมัติตามเดือนนั้นๆ
              child: CustomCalendar(
                initialDate: selectedDate,
                onDateSelected: (DateTime date) {
                  setState(() {
                    selectedDate = date;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void onTabSelected(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Mainchicken()),
      );
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainShowDataFood()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CloseOpenDoor()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ShowChart()),
      );
    } else {
      setState(() {
        selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    const Color bgDarkColor = Color(0xFF0F171E);
    const Color cardColor = Color(0xFF1B242D);
    const Color inputFillColor = Color(0xFF151D24);
    const Color borderColor = Colors.white24;
    const Color highlightRed = Color(0xFFFF6E5C);
    const Color cancelBtnColor = Color(0xFF3B4654);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: bgDarkColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          constraints: BoxConstraints(minHeight: screenHeight),
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/heal.png'),
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 130),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            monthNames[selectedDate.month - 1],
                            style: GoogleFonts.kanit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white54,
                            size: 20,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            '${selectedDate.year}',
                            style: GoogleFonts.kanit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white54),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.calendar_today_outlined,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF42A5F5),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'บันทึกตรวจสุขภาพ',
                                  style: GoogleFonts.kanit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.calendar_view_week_outlined,
                              color: Colors.white70,
                              size: 24,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        _buildLabel('วันที่ตรวจไก่'),
                        InkWell(
                          onTap: isLoading ? null : _showCalendarDialog,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: inputFillColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _getFormattedDate(selectedDate),
                                  style: GoogleFonts.kanit(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 🌟 Dropdown เลือกคอก
                        _buildLabel('เลือกคอก'),
                        _isLoadingCoops
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: inputFillColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: borderColor),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                              )
                            : _coopList.isEmpty
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: inputFillColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'ไม่พบข้อมูลคอก',
                                        style: GoogleFonts.kanit(
                                          color: Colors.white54,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: _fetchCoops,
                                      child: const Icon(
                                        Icons.refresh,
                                        color: Colors.white54,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: inputFillColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: borderColor),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCoopId,
                                    isExpanded: true,
                                    dropdownColor: cardColor,
                                    hint: Text(
                                      'เลือกคอก',
                                      style: GoogleFonts.kanit(
                                        color: Colors.white54,
                                      ),
                                    ),
                                    style: GoogleFonts.kanit(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Colors.white54,
                                    ),
                                    items: _coopList.map((coop) {
                                      return DropdownMenuItem<String>(
                                        value: coop.id,
                                        child: Text(coop.displayLabel),
                                      );
                                    }).toList(),
                                    onChanged: isLoading
                                        ? null
                                        : (String? newValue) {
                                            setState(() {
                                              _selectedCoopId = newValue;
                                            });
                                          },
                                  ),
                                ),
                              ),
                        const SizedBox(height: 16),

                        _buildLabel('จำนวนไก่ที่สุขภาพดี (ตัว)'),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _healthyController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'ตัว',
                              style: GoogleFonts.kanit(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _buildLabel('จำนวนไก่ที่สุขภาพไม่ดี (ตัว)'),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _unhealthyController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'ตัว',
                              style: GoogleFonts.kanit(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _buildLabel('หมายเหตุ'),
                        _buildTextField(
                          controller: _noteController,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white30,
                              width: 1,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info,
                                color: Colors.white54,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'ระบบจะบันทึกข้อมูลวันที่ตรวจอัตโนมัติ\nเมื่อกดบันทึกข้อมูล',
                                  style: GoogleFonts.kanit(
                                    fontSize: 12,
                                    color: Colors.white70,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          Navigator.pop(context);
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: cancelBtnColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'ยกเลิก',
                                    style: GoogleFonts.kanit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : _saveHealthData, // 🌟 ตรงนี้คือปุ่มที่เรียกใช้ API
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: highlightRed,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'บันทึกข้อมูล',
                                          style: GoogleFonts.kanit(
                                            fontSize: 16,
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
                  const SizedBox(height: 120),
                ],
              ),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: GoogleFonts.kanit(fontSize: 14, color: Colors.white70),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.kanit(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        filled: true,
        fillColor: const Color(0xFF151D24),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF42A5F5)),
        ),
      ),
    );
  }
}
