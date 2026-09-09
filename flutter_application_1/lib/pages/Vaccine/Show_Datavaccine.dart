import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/calendar.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../bottombar.dart';
import '../main_dash.dart';
import '../../widgets/ez_header.dart';
import '../../widgets/ez_form_field.dart';
import '../../widgets/ez_top_banner.dart';
import '../../utils/thai_date.dart';
import '../../services/backend_config.dart';

class ShowDatavaccine extends StatefulWidget {
  final String vaccineTypeFilter;
  final String? initialCoopId;

  const ShowDatavaccine({
    super.key,
    required this.vaccineTypeFilter,
    this.initialCoopId,
  });

  @override
  State<ShowDatavaccine> createState() => _ShowDatavaccineState();
}

class _ShowDatavaccineState extends State<ShowDatavaccine> {
  int selectedIndex = 0;
  String selectedCoop = "เลือกคอก";

  List<Map<String, dynamic>> allVaccineData = [];
  bool isLoading = true;
  bool isSaving = false;

  List<String> coopList = ["ทั้งหมด"];
  Map<String, String> coopChickenCounts = {};
  Map<String, String> coopNames =
      {}; // ✅ แผนที่ coop_id -> ชื่อคอก สำหรับแสดงผล

  DateTime _selectedDate = DateTime.now();

  // Controllers สำหรับช่องกรอกข้อมูล
  TextEditingController medNameCtrl = TextEditingController(text: "");
  String? selectedMethod;
  static const List<String> methodOptions = [
    'พ่น',
    'ฉีด',
    'หยอดปาก',
    'ผสมน้ำ',
    'ผสมอาหาร',
  ];
  TextEditingController minAgeCtrl = TextEditingController(text: "");
  TextEditingController maxAgeCtrl = TextEditingController(text: "");
  TextEditingController remarkCtrl = TextEditingController(text: "");

  // ค่าที่ผู้ใช้เลือกจากไดอะล็อก "ตั้งค่าการแจ้งเตือน" (ยังไม่ได้ผูกกับ backend จริง
  // แค่เก็บไว้แสดงผลในหน้านี้)
  bool _hasReminder = false;
  bool _reminderAllDay = false;
  DateTime _reminderStartDate = DateTime.now();
  TimeOfDay _reminderStartTime = const TimeOfDay(hour: 8, minute: 0);
  DateTime _reminderEndDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _reminderEndTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    if (widget.initialCoopId != null) {
      selectedCoop =
          widget.initialCoopId!; // ✅ เปิดมาจากคอกไหน ให้เลือกคอกนั้นไว้ล่วงหน้า
    }
    fetchCoops();
    fetchVaccineData();
  }

  // 🌟 ฟังก์ชันบันทึกข้อมูลวัคซีน/ยาลง Backend (เพิ่มเงื่อนไขตรวจเช็คหมายเหตุแล้ว)
  Future<void> saveVaccineData() async {
    // 1. เช็คว่ากรอกข้อมูลครบไหม (เพิ่มตรวจสอบ remarkCtrl.text.isEmpty เข้าไป)
    if (medNameCtrl.text.isEmpty ||
        selectedMethod == null ||
        minAgeCtrl.text.isEmpty ||
        maxAgeCtrl.text.isEmpty ||
        remarkCtrl.text.isEmpty) {
      showEzTopBanner(
        context,
        'กรุณากรอกข้อมูล ชื่อยา, วิธีการให้, เงื่อนไขอายุ และ "หมายเหตุ" ให้ครบถ้วนก่อนบันทึก',
      );
      return; // สั่งหยุดการทำงานตรงนี้ ไม่ให้รันโค้ดบันทึกด้านล่างต่อ
    }

    setState(() {
      isSaving = true;
    });

    // 2. แปลงอายุต่ำสุด/สูงสุดที่กรอกเป็นตัวเลข
    int minDays = int.tryParse(minAgeCtrl.text.trim()) ?? 1;
    int maxDays = int.tryParse(maxAgeCtrl.text.trim()) ?? minDays;

    // โครงสร้างข้อมูลที่ Backend ต้องการ
    final Map<String, dynamic> requestBody = {
      "name": medNameCtrl.text,
      "method": selectedMethod ?? "",
      "min_age_days": minDays,
      "max_age_days": maxDays,
      "description": remarkCtrl.text,
    };

    final String apiUrl = '$backendBaseUrl/api/vaccines/schedule';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        showEzTopBanner(
          context,
          'บันทึกกำหนดการยา/วัคซีนสำเร็จ!',
          isError: false,
        );

        // ล้างข้อมูลช่องกรอก
        medNameCtrl.clear();
        minAgeCtrl.clear();
        maxAgeCtrl.clear();
        remarkCtrl.clear();
        setState(() {
          selectedMethod = null;
          _hasReminder = false;
        });

        // รีเฟรชตารางข้อมูล
        fetchVaccineData();
      } else {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      showEzTopBanner(context, 'เกิดข้อผิดพลาดในการบันทึกข้อมูล: $e');
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  Future<void> fetchCoops() async {
    final String apiUrl = '$backendBaseUrl/api/coops';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        var decoded = json.decode(response.body);
        List<dynamic> dataList = [];

        if (decoded is List) {
          dataList = decoded;
        } else if (decoded is Map && decoded.containsKey('data')) {
          dataList = decoded['data'];
        }

        setState(() {
          coopList = ["ทั้งหมด"];
          coopChickenCounts.clear();
          coopNames.clear();

          for (var item in dataList) {
            String id =
                item['coop_id']?.toString() ?? item['id']?.toString() ?? "";
            String count =
                item['chicken_count']?.toString() ??
                item['amount']?.toString() ??
                item['quantity']?.toString() ??
                "-";
            String name = item['name_coop']?.toString() ?? "";

            if (id.isNotEmpty) {
              coopList.add(id);
              coopChickenCounts[id] = count;
              coopNames[id] = name.trim().isNotEmpty ? name : id;
            }
          }
        });
      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการดึงรหัสคอก: $e');
    }
  }

  Future<void> fetchVaccineData() async {
    setState(() {
      isLoading = true;
    });

    String apiUrl = '$backendBaseUrl/api/vaccines/recommended';
    if (selectedCoop != "ทั้งหมด" && selectedCoop != "เลือกคอก") {
      apiUrl =
          '$backendBaseUrl/api/vaccines/recommended?coop_id=$selectedCoop';
    }

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        List<dynamic> schedules = [];
        String displayCoopId = "ตารางแนะนำ (ทั้งหมด)";
        String displayBirthday = "-";
        String displayChickenCount = "-";

        if (selectedCoop != "ทั้งหมด" &&
            coopChickenCounts.containsKey(selectedCoop)) {
          if (coopChickenCounts[selectedCoop] != "-") {
            displayChickenCount = "${coopChickenCounts[selectedCoop]} ตัว";
          }
        }

        if (jsonResponse.containsKey('recommended_vaccines')) {
          schedules = jsonResponse['recommended_vaccines'] ?? [];
          displayCoopId = jsonResponse['coop_id']?.toString() ?? selectedCoop;

          if (jsonResponse['birthday'] != null) {
            displayBirthday = thaiDateFromIso(
              jsonResponse['birthday'].toString(),
            );
          }
        } else {
          schedules = jsonResponse['schedules'] ?? [];
        }

        setState(() {
          allVaccineData = List<Map<String, dynamic>>.from(
            schedules.map(
              (item) => {
                "coopId": displayCoopId,
                "chickenCount": displayChickenCount,
                "birthDate": displayBirthday,
                "vaccineDate":
                    "อายุ ${item['min_age_days'] ?? ""}-${item['max_age_days'] ?? ""} วัน",
                "vaccineType": widget.vaccineTypeFilter,
                "medName": item['name'] ?? "",
                "healthyCount": "",
                "unhealthyCount": "",
                "remark": item['description'] ?? "",
              },
            ),
          );
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการดึงข้อมูล API: $e');
      setState(() {
        isLoading = false;
      });
    }
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

  Future<void> _openReminderDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _VaccineReminderDialog(
        initialAllDay: _reminderAllDay,
        initialStartDate: _reminderStartDate,
        initialStartTime: _reminderStartTime,
        initialEndDate: _reminderEndDate,
        initialEndTime: _reminderEndTime,
      ),
    );
    if (result == null) return; // กดยกเลิก หรือแตะพื้นหลังปิดไดอะล็อก
    setState(() {
      _hasReminder = true;
      _reminderAllDay = result['isAllDay'] as bool;
      _reminderStartDate = result['startDate'] as DateTime;
      _reminderStartTime = result['startTime'] as TimeOfDay;
      _reminderEndDate = result['endDate'] as DateTime;
      _reminderEndTime = result['endTime'] as TimeOfDay;
    });
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String get _reminderSummaryText {
    if (_reminderAllDay) {
      return 'ตลอดวัน · ${thaiDate(_reminderStartDate)} – ${thaiDate(_reminderEndDate)}';
    }
    return '${thaiDate(_reminderStartDate)} ${_formatTime(_reminderStartTime)} – ${thaiDate(_reminderEndDate)} ${_formatTime(_reminderEndTime)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: ezBackgroundColor(context),
      body: Stack(
        children: [
          // เนื้อหา UI
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const EzHeader(pageTitle: 'บันทึกวัคซีน'),
                  const SizedBox(height: 20),

                  // UI ฟอร์มข้อมูลวัคซีน
                  _buildVaccineFormWidget(),

                  const SizedBox(height: 100),
                ],
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

  Widget _buildVaccineFormWidget() {
    final ez = ezColors(context);
    String formattedDate = thaiDate(_selectedDate);
    final bool coopSelected = coopList.contains(selectedCoop);

    return Container(
      decoration: BoxDecoration(
        color: ezCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ez.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.vaccines_outlined,
                        color: ez.gold,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'กรอกข้อมูลการให้วัคซีน/ยา',
                            style: GoogleFonts.kanit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ez.textPrimary,
                            ),
                          ),
                          Text(
                            'ช่องที่มี * ต้องกรอกให้ครบก่อนบันทึก',
                            style: GoogleFonts.kanit(
                              fontSize: 10,
                              color: ez.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ez.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: ez.gold,
                            size: 13,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formattedDate,
                            style: GoogleFonts.kanit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ez.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ฟอร์มกรอกข้อมูล — ดีไซน์เดียวกันทุกช่อง
                EzFormDropdown<String>(
                  label: "เลือกคอก",
                  isRequired: true,
                  value: coopSelected ? selectedCoop : null,
                  hint: "เลือกคอก",
                  items: coopList
                      .map(
                        (id) => DropdownMenuItem(
                          value: id,
                          child: Text(
                            coopNames[id] ?? id,
                            style: GoogleFonts.kanit(),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      selectedCoop = val;
                    });
                    fetchVaccineData();
                  },
                ),
                const SizedBox(height: 12),
                EzFormTextField(
                  label: "ชื่อยา",
                  isRequired: true,
                  controller: medNameCtrl,
                  hintText: "เช่น นิวคาสเซิล",
                ),
                const SizedBox(height: 12),
                EzFormDropdown<String>(
                  label: "วิธีการให้",
                  isRequired: true,
                  value: selectedMethod,
                  hint: "เลือกวิธีการให้",
                  items: methodOptions
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedMethod = val;
                    });
                  },
                ),
                const SizedBox(height: 12),
                EzFormTextField(
                  label: "อายุต่ำสุด",
                  isRequired: true,
                  controller: minAgeCtrl,
                  keyboardType: TextInputType.number,
                  hintText: "เช่น 1",
                  suffixText: "วัน",
                ),
                const SizedBox(height: 12),
                EzFormTextField(
                  label: "อายุสูงสุด",
                  isRequired: true,
                  controller: maxAgeCtrl,
                  keyboardType: TextInputType.number,
                  hintText: "เช่น 7",
                  suffixText: "วัน",
                ),
                const SizedBox(height: 12),
                EzFormTextField(
                  label: "หมายเหตุ",
                  isRequired: true,
                  controller: remarkCtrl,
                  hintText: "รายละเอียดเพิ่มเติม",
                ),

                const SizedBox(height: 18),

                // ปุ่มรอง: ตั้งเตือน — ทำเป็นปุ่มมีกรอบให้เห็นชัดว่ากดได้
                SizedBox(
                  width: double.infinity,
                  child: InkWell(
                    onTap: _openReminderDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: ez.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ez.danger.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_active_outlined,
                            color: ez.danger,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'ตั้งเตือนการให้วัคซีน',
                              style: GoogleFonts.kanit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: ez.danger,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: ez.danger,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_hasReminder)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: ez.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_active,
                            size: 16,
                            color: ez.gold,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _reminderSummaryText,
                              style: GoogleFonts.kanit(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: ez.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
              ],
            ),
          ),

          InkWell(
            onTap: isSaving ? null : saveVaccineData,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSaving ? Colors.grey : const Color(0xFF55C759),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                  const SizedBox(width: 8),
                  Text(
                    isSaving ? "กำลังบันทึก..." : "บันทึกการให้วัคซีน",
                    style: GoogleFonts.kanit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

/// ไดอะล็อกตั้งค่าการแจ้งเตือนการให้วัคซีน — กึ่งกลางจอ เลือกช่วงวันและเวลา
/// เริ่มต้น/สิ้นสุดได้จริง (หรือตั้งเป็น "ตลอดวัน") พร้อมตรวจว่าวันเริ่มต้อง
/// น้อยกว่าวันสิ้นสุดก่อนกดยืนยัน
class _VaccineReminderDialog extends StatefulWidget {
  final bool initialAllDay;
  final DateTime initialStartDate;
  final TimeOfDay initialStartTime;
  final DateTime initialEndDate;
  final TimeOfDay initialEndTime;

  const _VaccineReminderDialog({
    required this.initialAllDay,
    required this.initialStartDate,
    required this.initialStartTime,
    required this.initialEndDate,
    required this.initialEndTime,
  });

  @override
  State<_VaccineReminderDialog> createState() =>
      _VaccineReminderDialogState();
}

class _VaccineReminderDialogState extends State<_VaccineReminderDialog> {
  late bool isAllDay = widget.initialAllDay;
  late DateTime startDate = widget.initialStartDate;
  late TimeOfDay startTime = widget.initialStartTime;
  late DateTime endDate = widget.initialEndDate;
  late TimeOfDay endTime = widget.initialEndTime;
  String? errorText;

  DateTime get _startDateTime => DateTime(
    startDate.year,
    startDate.month,
    startDate.day,
    startTime.hour,
    startTime.minute,
  );

  DateTime get _endDateTime => DateTime(
    endDate.year,
    endDate.month,
    endDate.day,
    endTime.hour,
    endTime.minute,
  );

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        startDate = picked;
      } else {
        endDate = picked;
      }
      errorText = null;
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? startTime : endTime,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        startTime = picked;
      } else {
        endTime = picked;
      }
      errorText = null;
    });
  }

  void _confirm() {
    final isValid = isAllDay
        ? !endDate.isBefore(startDate)
        : _endDateTime.isAfter(_startDateTime);
    if (!isValid) {
      setState(
        () => errorText = 'วันและเวลาเริ่มต้นต้องน้อยกว่าวันและเวลาสิ้นสุด',
      );
      return;
    }
    Navigator.pop(context, {
      'isAllDay': isAllDay,
      'startDate': startDate,
      'startTime': startTime,
      'endDate': endDate,
      'endTime': endTime,
    });
  }

  @override
  Widget build(BuildContext context) {
    final ez = ezColors(context);
    return Dialog(
      backgroundColor: ezCardColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  color: Colors.redAccent,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ตั้งค่าการแจ้งเตือน',
                    style: GoogleFonts.kanit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ez.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "ตลอดวัน",
                  style: GoogleFonts.kanit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ez.textPrimary,
                  ),
                ),
                Switch(
                  value: isAllDay,
                  onChanged: (val) => setState(() {
                    isAllDay = val;
                    errorText = null;
                  }),
                  activeThumbColor: Colors.white,
                  activeTrackColor: ez.gold,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: ez.border,
                ),
              ],
            ),
            Divider(color: ez.border, height: 24),
            _buildDateTimeSection(
              label: 'วันและเวลาเริ่มต้น',
              date: startDate,
              time: startTime,
              onDateTap: () => _pickDate(isStart: true),
              onTimeTap: () => _pickTime(isStart: true),
            ),
            const SizedBox(height: 16),
            _buildDateTimeSection(
              label: 'วันและเวลาสิ้นสุด',
              date: endDate,
              time: endTime,
              onDateTap: () => _pickDate(isStart: false),
              onTimeTap: () => _pickTime(isStart: false),
            ),
            if (errorText != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: ez.danger),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      errorText!,
                      style: GoogleFonts.kanit(fontSize: 12, color: ez.danger),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(color: ez.border, width: 1.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'ยกเลิก',
                      style: GoogleFonts.kanit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ez.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF55C759),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'ยืนยัน',
                      style: GoogleFonts.kanit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection({
    required String label,
    required DateTime date,
    required TimeOfDay time,
    required VoidCallback onDateTap,
    required VoidCallback onTimeTap,
  }) {
    final ez = ezColors(context);
    final timeText =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.kanit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ez.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _pickerBox(
                icon: Icons.calendar_today_outlined,
                text: thaiDate(date),
                onTap: onDateTap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _pickerBox(
                icon: Icons.access_time_rounded,
                text: isAllDay ? 'ทั้งวัน' : timeText,
                onTap: isAllDay ? null : onTimeTap,
                dimmed: isAllDay,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pickerBox({
    required IconData icon,
    required String text,
    required VoidCallback? onTap,
    bool dimmed = false,
  }) {
    final ez = ezColors(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: ez.inputFill.withValues(alpha: dimmed ? 0.5 : 1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ez.border, width: 1.2),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: dimmed ? ez.textSecondary : ez.gold,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.kanit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: dimmed ? ez.textSecondary : ez.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
