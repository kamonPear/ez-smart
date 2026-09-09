import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/pages/calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bottombar.dart';
import '../../widgets/ez_header.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:flutter_application_1/models/coop.dart'; // 🌟 ปรับ path ให้ตรงกับโครงสร้างโปรเจกต์จริง

// 🌟 URL ของ Backend
import '../../services/backend_config.dart';
import '../../utils/thai_date.dart';

class AddDatachickenHealth extends StatefulWidget {
  final String? initialCoopId;

  const AddDatachickenHealth({super.key, this.initialCoopId});

  @override
  State<AddDatachickenHealth> createState() => _AddDatachickenHealthState();
}

class _AddDatachickenHealthState extends State<AddDatachickenHealth> {
  int? selectedIndex; // ไม่ใช่หน้าในแถบเมนูล่าง จึงไม่ไฮไลต์เมนูไหน
  bool isLoading = false; // สำหรับทำปุ่มโหลด

  DateTime selectedDate = DateTime.now();
  bool _isAppointment = false; // 🌟 นัดหมายตรวจล่วงหน้า (ยังไม่มีผลตรวจจริง)

  // 🌟 สำหรับ Dropdown เลือกคอก (Coop.id เป็น String ตามโมเดลจริง)
  List<Coop> _coopList = [];
  String? _selectedCoopId;
  bool _isLoadingCoops = true;

  final TextEditingController _healthyController = TextEditingController(
 
  );
  final TextEditingController _unhealthyController = TextEditingController(
  
  );
  final TextEditingController _noteController = TextEditingController(
    
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
    return thaiDate(date);
  }

  bool _isFutureDate(DateTime date) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    return dateOnly.isAfter(todayOnly);
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

    // 🌟 นัดหมายล่วงหน้า: ส่งเข้า backend เส้นเดียวกับการบันทึกตรวจสุขภาพปกติ
    // แค่ยังไม่กรอกจำนวนไก่ (เป็น 0 ไปก่อน) แล้วผู้ใช้ค่อยมาแก้ไขตัวเลขจริงทีหลังผ่านหน้าแก้ไข
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
          SnackBar(
            content: Text(
              _isAppointment
                  ? 'บันทึกนัดหมายล่วงหน้าแล้ว กรอกจำนวนไก่ทีหลังได้'
                  : 'บันทึกข้อมูลสำเร็จ',
              style: const TextStyle(color: Colors.white),
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
          backgroundColor: ezCardColor(context),
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
                    if (!_isFutureDate(date)) {
                      _isAppointment = false;
                    }
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

    final Color bgDarkColor = ezBackgroundColor(context);
    final Color cardColor = ezCardColor(context);
    final Color inputFillColor = ezColors(context).inputFill;
    final Color borderColor = ezColors(context).border;
    const Color highlightRed = Color(0xFFFF6E5C);
    final Color cancelBtnColor = ezColors(context).cardAlt;

    return Scaffold(
      extendBody: true,
      backgroundColor: bgDarkColor,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          constraints: BoxConstraints(minHeight: screenHeight),
          width: double.infinity,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const EzHeader(pageTitle: 'บันทึกสุขภาพไก่'),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            kThaiMonthsFull[selectedDate.month - 1],
                            style: GoogleFonts.kanit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ezColors(context).textPrimary,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down,
                              color: ezColors(context).textSecondary,
                            size: 20,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            '${selectedDate.year + 543}',
                            style: GoogleFonts.kanit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ezColors(context).textPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              border: Border.all(color: ezColors(context).border),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.calendar_today_outlined,
                                color: ezColors(context).textPrimary,
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
                                    color: ezColors(context).textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.calendar_view_week_outlined,
                                color: ezColors(context).textSecondary,
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
                                    color: ezColors(context).textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today_outlined,
                                    color: ezColors(context).textSecondary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (_isFutureDate(selectedDate)) ...[
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _isAppointment = !_isAppointment;
                                    });
                                  },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: _isAppointment
                                    ? const Color(0xFF42A5F5).withOpacity(0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _isAppointment
                                      ? const Color(0xFF42A5F5)
                                      : borderColor,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _isAppointment
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                    color: _isAppointment
                                        ? const Color(0xFF42A5F5)
                                        : ezColors(context).textSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'ตั้งเป็นนัดหมายล่วงหน้า (ยังไม่ตรวจตอนนี้ ระบบจะแจ้งเตือนเมื่อถึงวันที่)',
                                      style: GoogleFonts.kanit(
                                        fontSize: 12,
                                        color: ezColors(context).textPrimary,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: ezColors(context).textSecondary,
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
                                          color: ezColors(context).textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: _fetchCoops,
                                      child: Icon(
                                        Icons.refresh,
                                          color: ezColors(context).textSecondary,
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
                                        color: ezColors(context).textSecondary,
                                      ),
                                    ),
                                    style: GoogleFonts.kanit(
                                      color: ezColors(context).textPrimary,
                                      fontSize: 14,
                                    ),
                                    icon: Icon(
                                      Icons.keyboard_arrow_down,
                                        color: ezColors(context).textSecondary,
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

                        if (!_isAppointment) ...[
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
                                  color: ezColors(context).textPrimary,
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
                                  color: ezColors(context).textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

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
                              color: ezColors(context).border,
                              width: 1,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info,
                                  color: ezColors(context).textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _isAppointment
                                      ? 'ระบบจะแจ้งเตือนในแอปเมื่อถึงวันที่นัดหมาย\nแล้วค่อยกลับมากรอกผลตรวจจริงภายหลัง'
                                      : 'ระบบจะบันทึกข้อมูลวันที่ตรวจอัตโนมัติ\nเมื่อกดบันทึกข้อมูล',
                                  style: GoogleFonts.kanit(
                                    fontSize: 12,
                                    color: ezColors(context).textSecondary,
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
                                      color: ezColors(context).textPrimary,
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
                                          _isAppointment
                                              ? 'บันทึกนัดหมาย'
                                              : 'บันทึกข้อมูล',
                                          style: GoogleFonts.kanit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: ezColors(context).textPrimary,
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
        style: GoogleFonts.kanit(fontSize: 14, color: ezColors(context).textSecondary),
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
      style: GoogleFonts.kanit(color: ezColors(context).textPrimary, fontSize: 14),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        filled: true,
        fillColor: ezColors(context).inputFill,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ezColors(context).border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF42A5F5)),
        ),
      ),
    );
  }
}
