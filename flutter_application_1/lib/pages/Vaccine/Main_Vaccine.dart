import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Import สำหรับการนำทาง (กรุณาปรับให้ตรงกับ Path ของโปรเจกต์คุณ)
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/Vaccine/Show_Datavaccine.dart';
import 'package:flutter_application_1/pages/calendar.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bottombar.dart';
import '../main_dash.dart';

class MainVaccine extends StatefulWidget {
  final String? initialCoopId;

  const MainVaccine({super.key, this.initialCoopId});

  @override
  State<MainVaccine> createState() => _MainVaccineState();
}

class _MainVaccineState extends State<MainVaccine> {
  int selectedIndex = 0;

  DateTime _selectedDay = DateTime.now();
  List<DateTime> _markedDates = [];
  List<dynamic> _vaccineAlerts = [];
  bool _isLoading = true;
  Map<String, String> _coopNames =
      {}; // ✅ แผนที่ coop_id -> ชื่อคอก สำหรับแสดงผล

  @override
  void initState() {
    super.initState();
    fetchVaccineAlerts();
    _fetchCoopNames();
  }

  Future<void> _fetchCoopNames() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/coops'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _coopNames = {
            for (var item in data)
              (item['coop_id'] ?? item['id']).toString():
                  (item['name_coop']?.toString().trim().isNotEmpty == true)
                  ? item['name_coop'].toString()
                  : (item['coop_id'] ?? item['id']).toString(),
          };
        });
      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการดึงชื่อคอก: $e');
    }
  }

  // ✅ ถ้าเปิดหน้านี้มาจากคอกใดคอกหนึ่งโดยเฉพาะ ให้กรองเหลือแค่คอกนั้น
  List<dynamic> get _coopFilteredAlerts {
    if (widget.initialCoopId == null) return _vaccineAlerts;
    return _vaccineAlerts.where((alert) {
      return alert['coop_id']?.toString() == widget.initialCoopId;
    }).toList();
  }

  void _updateMarkedDates() {
    Set<DateTime> pendingDates = {};
    for (var alert in _coopFilteredAlerts) {
      bool isCompleted = alert['is_completed'] ?? false;
      if (!isCompleted && alert['date'] != null) {
        try {
          DateTime d = DateTime.parse(alert['date']).toLocal();
          pendingDates.add(DateTime(d.year, d.month, d.day));
        } catch (e) {
          print('Date parsing error: $e');
        }
      }
    }
    _markedDates = pendingDates.toList();
  }

  Future<void> fetchVaccineAlerts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/vaccines/alerts'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          _vaccineAlerts = data;
          _updateMarkedDates();
          _isLoading = false;
        });
      } else {
        print('Failed to load data: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error Fetching API: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> updateCompletionStatus(
    Map<String, dynamic> alert,
    bool newValue,
  ) async {
    String id = alert['id']?.toString() ?? '';
    if (id.isEmpty) return;

    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:8080/api/vaccines/alerts?id=$id'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "is_completed": newValue,
          "method": alert['injection_type'] ?? '-',
          "chicken_age": alert['chicken_age'] ?? 0,
          "note": alert['description'] ?? 'ไม่มีหมายเหตุ',
        }),
      );

      if (response.statusCode == 200) {
        print('✅ อัปเดตฐานข้อมูลสำเร็จ');
      } else {
        print('❌ อัปเดตฐานข้อมูลไม่สำเร็จ: Status Code ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error Updating Status: $e');
    }
  }

  // ==========================================
  // 🌟 ส่วนของฟังก์ชัน "ลบ" และ "แสดงข้อมูล" 🌟
  // ==========================================
  Future<void> deleteVaccineAlertData(String id) async {
    if (id.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:8080/api/vaccines/alerts?id=$id'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        print('✅ ลบข้อมูลสำเร็จ');
        fetchVaccineAlerts();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error Deleting Data: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.kanit(color: Colors.white70, fontSize: 15),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.kanit(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showVaccineDetailDialog(Map<String, dynamic> alert) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E2730),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "ข้อมูลวัคซีน",
                  style: GoogleFonts.kanit(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(
                color: Color(0xFF62A199),
                thickness: 1.5,
                height: 30,
              ),
              _buildDetailRow(
                "ชื่อวัคซีน:",
                alert['vaccine_name'] ?? 'ไม่ระบุชื่อ',
              ),
              _buildDetailRow(
                "คอกเป้าหมาย:",
                "คอก ${_coopNames[alert['coop_id']?.toString()] ?? alert['coop_id'] ?? '-'}",
              ),
              _buildDetailRow("อายุไก่:", "${alert['chicken_age'] ?? '-'} วัน"),
              _buildDetailRow("ประเภทการให้:", alert['injection_type'] ?? '-'),
              _buildDetailRow(
                "หมายเหตุ:",
                alert['description'] != null &&
                        alert['description'].toString().isNotEmpty
                    ? alert['description']
                    : 'ไม่มีหมายเหตุ',
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "ปิด",
                        style: GoogleFonts.kanit(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        deleteVaccineAlertData(alert['id']?.toString() ?? '');
                      },
                      child: Text(
                        "ลบข้อมูล",
                        style: GoogleFonts.kanit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
    );
  }

  // ==========================================
  // 🌟 ส่วนของฟังก์ชัน "แก้ไขข้อมูลวัคซีน" 🌟
  // ==========================================
  Future<void> editVaccineAlertData({
    required String oldName,
    required String newName,
    required int age,
    required String type,
    required String note,
  }) async {
    setState(() => _isLoading = true);

    try {
      // ✅ แก้ไข: ใช้ Uri.encodeComponent เพื่อป้องกัน URL พังเวลาชื่อเป็นภาษาไทยหรือมีเว้นวรรค
      String url =
          'http://10.0.2.2:8080/api/vaccines/schedule/update?old_name=${Uri.encodeComponent(oldName)}';

      final response = await http.put(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        // ตรวจสอบในฟังก์ชัน editVaccineAlertData ของ Flutter ว่า body เขียนแบบนี้ไหม
        body: jsonEncode({
          "name": newName,
          "min_age_days": age, // ต้องเขียน min_age_days ตัวพิมพ์เล็ก มีขีดล่าง
          "max_age_days": age, // ต้องเขียน max_age_days ตัวพิมพ์เล็ก มีขีดล่าง
          "method": type,
          "description": note,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ แก้ไขข้อมูลสำเร็จ');
        fetchVaccineAlerts(); // โหลดข้อมูลใหม่มาแสดง
      } else {
        print('❌ แก้ไขข้อมูลไม่สำเร็จ: Status Code ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error Editing Data: $e');
      setState(() => _isLoading = false);
    }
  }

  void showEditVaccineDialog(Map<String, dynamic> alert) {
    TextEditingController nameController = TextEditingController(
      text: alert['vaccine_name'],
    );
    TextEditingController ageController = TextEditingController(
      text: alert['chicken_age']?.toString(),
    );
    TextEditingController typeController = TextEditingController(
      text: alert['injection_type'],
    );
    TextEditingController noteController = TextEditingController(
      text: alert['description'],
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2730),
        title: Text(
          "แก้ไขข้อมูลวัคซีน",
          style: GoogleFonts.kanit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: GoogleFonts.kanit(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "ชื่อวัคซีน",
                  labelStyle: GoogleFonts.kanit(color: Colors.grey),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF62A199)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.kanit(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "อายุไก่ (วัน)",
                  labelStyle: GoogleFonts.kanit(color: Colors.grey),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF62A199)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: typeController,
                style: GoogleFonts.kanit(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "ประเภทการให้",
                  labelStyle: GoogleFonts.kanit(color: Colors.grey),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF62A199)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteController,
                style: GoogleFonts.kanit(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "หมายเหตุ",
                  labelStyle: GoogleFonts.kanit(color: Colors.grey),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF62A199)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("ยกเลิก", style: GoogleFonts.kanit(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF34C759),
            ),
            onPressed: () {
              Navigator.pop(context);

              // 🌟 1. ดึงข้อความออกมาแล้วตัดช่องว่างรอบๆ ทิ้ง
              String rawAgeText = ageController.text.trim();

              // 🌟 2. ลบตัวอักษรอื่นๆ ออกให้เหลือแค่ตัวเลข 0-9 เท่านั้น (ป้องกัน user พิมพ์คำว่า 'วัน' ติดมา)
              String numericString = rawAgeText.replaceAll(
                RegExp(r'[^0-9]'),
                '',
              );

              // 🌟 3. ค่อยแปลงเป็น int (ถ้าว่างเปล่าให้ค่าเริ่มต้นเป็น 0)
              int parsedAge = int.tryParse(numericString) ?? 0;

              // เช็คเพื่อความชัวร์ใน Debug Console ของ Flutter
              print("อายุที่จะส่งไปอัปเดต: $parsedAge");

              editVaccineAlertData(
                oldName: alert['vaccine_name'] ?? '',
                newName: nameController.text.trim(),
                age: parsedAge, // ส่งตัวเลขที่แปลงสำเร็จแล้ว
                type: typeController.text.trim(),
                note: noteController.text.trim(),
              );
            },
            child: Text(
              "บันทึก",
              style: GoogleFonts.kanit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
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

    List<dynamic> alertsForSelectedDay = _coopFilteredAlerts.where((alert) {
      if (alert['date'] == null) return false;
      DateTime alertDate = DateTime.parse(alert['date']).toLocal();
      return alertDate.year == _selectedDay.year &&
          alertDate.month == _selectedDay.month &&
          alertDate.day == _selectedDay.day;
    }).toList();

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
          Container(
            height: screenHeight,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Vaccine.png'),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          Positioned(
            top: 45,
            right: 25,
            child: IconButton(
              icon: const Icon(
                Icons.calendar_today_outlined,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {
                setState(() {
                  _selectedDay = DateTime.now();
                });
              },
            ),
          ),
          Positioned(
            top: 90,
            left: 0,
            right: 0,
            bottom: 90,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 160),
                  if (widget.initialCoopId != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'ตารางวัคซีนคอก ${_coopNames[widget.initialCoopId] ?? widget.initialCoopId}',
                        style: GoogleFonts.kanit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  CustomCalendar(
                    key: ValueKey(
                      _selectedDay.toString() + _markedDates.length.toString(),
                    ),
                    initialDate: _selectedDay,
                    markedDates: _markedDates,
                    onDateSelected: (selectedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                      });
                    },
                  ),
                  const SizedBox(height: 25),
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : alertsForSelectedDay.isEmpty
                      ? Text(
                          "ไม่มีคิวฉีดวัคซีนในวันนี้",
                          style: GoogleFonts.kanit(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        )
                      : Column(
                          children: alertsForSelectedDay.map((alert) {
                            return buildAlertCard(alert);
                          }).toList(),
                        ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0, right: 5.0),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShowDatavaccine(
                  vaccineTypeFilter: "ทั้งหมด",
                  initialCoopId: widget.initialCoopId,
                ),
              ),
            );
          },
          backgroundColor: const Color(0xFFE53935),
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 36),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected,
      ),
    );
  }

  Widget buildAlertCard(Map<String, dynamic> alert) {
    bool isCompleted = alert['is_completed'] ?? false;
    String rawCoopId = alert['coop_id']?.toString() ?? '-';
    String coopId = _coopNames[rawCoopId] ?? rawCoopId;
    String vaccineName = alert['vaccine_name'] ?? 'ไม่ระบุชื่อวัคซีน';
    String injectionType = alert['injection_type'] ?? '-';
    String chickenAge = alert['chicken_age']?.toString() ?? '-';
    String remark = alert['description'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2730),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🌟 แถวสำหรับแสดงชื่อวัคซีน + ปุ่มแก้ไข + ปุ่มดูข้อมูล
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 72), // ชดเชยพื้นที่เพื่อให้ Title ตรงกลาง
              Expanded(
                child: Center(
                  child: Text(
                    "แจ้งเตือน: $vaccineName",
                    style: GoogleFonts.kanit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.edit,
                      color: Colors.orangeAccent,
                      size: 24,
                    ),
                    onPressed: () =>
                        showEditVaccineDialog(alert), // 🌟 เปิดหน้าแก้ไข
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.info_outline,
                      color: Colors.blueAccent,
                      size: 26,
                    ),
                    onPressed: () => showVaccineDetailDialog(
                      alert,
                    ), // เปิดหน้าดูข้อมูลแบบเดิม
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.only(bottom: 6),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF62A199), width: 1.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "คอก",
                    style: GoogleFonts.kanit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ),
                Expanded(
                  child: Text(
                    "อายุไก่",
                    style: GoogleFonts.kanit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    "ประเภทการให้",
                    style: GoogleFonts.kanit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF62A199), width: 1.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    coopId,
                    style: GoogleFonts.kanit(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ),
                Expanded(
                  child: Text(
                    "$chickenAge วัน",
                    style: GoogleFonts.kanit(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    injectionType,
                    style: GoogleFonts.kanit(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),

          if (remark.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF131D2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "หมายเหตุ: $remark",
                style: GoogleFonts.kanit(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (remark.isEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF131D2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "หมายเหตุ: ไม่มีหมายเหตุ",
                style: GoogleFonts.kanit(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          InkWell(
            onTap: () {
              bool newValue = !isCompleted;
              setState(() {
                alert['is_completed'] = newValue;
                _updateMarkedDates();
              });
              updateCompletionStatus(alert, newValue);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.grey.shade700
                    : const Color(0xFF34C759),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle : Icons.vaccines,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCompleted ? "ให้วัคซีนแล้ว" : "เสร็จสิ้น (ให้วัคซีน)",
                    style: GoogleFonts.kanit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
