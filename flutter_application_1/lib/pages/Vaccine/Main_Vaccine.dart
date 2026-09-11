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
import '../../widgets/ez_header.dart';
import '../../widgets/ez_form_field.dart';
import '../../widgets/ez_top_banner.dart';
import '../../theme/app_theme.dart';
import '../../utils/vaccine_methods.dart';
import '../../services/backend_config.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MainVaccine extends StatefulWidget {
  final String? initialCoopId;

  const MainVaccine({super.key, this.initialCoopId});

  @override
  State<MainVaccine> createState() => _MainVaccineState();
}

class _MainVaccineState extends State<MainVaccine> {
  int? selectedIndex; // ไม่ใช่หน้าในแถบเมนูล่าง จึงไม่ไฮไลต์เมนูไหน

  DateTime _selectedDay = DateTime.now();
  Map<DateTime, DayMarkerInfo> _dayMarkers = {};
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
      final response = await http.get(Uri.parse('$backendBaseUrl/api/coops'));
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

  // 🌟 มาร์คสีเขียว = ให้วัคซีนแล้ว, สีแดง = ยังไม่ให้ (ถึงกำหนด/เกินกำหนด) ต้องรีบเตือน
  void _updateDayMarkers() {
    final Map<DateTime, List<DayDetailItem>> byDate = {};
    final Map<DateTime, bool> hasPending = {};

    for (var alert in _coopFilteredAlerts) {
      if (alert['date'] == null) continue;
      DateTime d;
      try {
        d = DateTime.parse(alert['date']).toLocal();
      } catch (e) {
        continue;
      }
      final dateOnly = DateTime(d.year, d.month, d.day);
      final bool isCompleted = alert['is_completed'] ?? false;
      final bool isOverdue = alert['is_overdue'] ?? false;
      final String vaccineName = alert['vaccine_name'] ?? 'วัคซีน';
      final String coopId = alert['coop_id']?.toString() ?? '-';
      final String coopName = _coopNames[coopId] ?? 'คอก $coopId';
      final String status = isCompleted
          ? 'ให้แล้ว'
          : (isOverdue ? 'เกินกำหนด' : 'ถึงกำหนด');

      byDate
          .putIfAbsent(dateOnly, () => [])
          .add(
            DayDetailItem(
              text: '💉 $vaccineName – $coopName ($status)',
              isPending: !isCompleted,
            ),
          );
      if (!isCompleted) hasPending[dateOnly] = true;
    }

    _dayMarkers = {
      for (final entry in byDate.entries)
        entry.key: DayMarkerInfo(
          color: hasPending[entry.key] == true ? kCalendarRed : kCalendarGreen,
          details: entry.value,
        ),
    };
  }

  void _showDayMarkerPopup(DateTime day, DayMarkerInfo marker) {
    final ez = ezColors(context);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: ezCardColor(dialogContext),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${day.day}/${day.month}/${day.year}',
                  style: GoogleFonts.kanit(
                    color: ez.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Divider(color: ez.border, thickness: 1, height: 1),
                ),
                ...marker.details.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      item.text,
                      style: GoogleFonts.kanit(
                        color: item.isPending ? kCalendarRed : ez.textPrimary,
                        fontWeight: item.isPending
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: ez.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      'ปิด',
                      style: GoogleFonts.kanit(
                        color: ez.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> fetchVaccineAlerts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$backendBaseUrl/api/vaccines/alerts'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          _vaccineAlerts = data;
          _updateDayMarkers();
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
        Uri.parse('$backendBaseUrl/api/vaccines/alerts?id=$id'),
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
              style: GoogleFonts.kanit(
                color: ezColors(context).textSecondary,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.kanit(
                color: ezColors(context).textPrimary,
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
      builder: (dialogContext) {
        final ez = ezColors(dialogContext);
        return Dialog(
          backgroundColor: ezCardColor(dialogContext),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        Icons.vaccines_rounded,
                        color: ez.gold,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "ข้อมูลวัคซีน",
                        style: GoogleFonts.kanit(
                          color: ez.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: ez.border, thickness: 1, height: 1),
                ),
                _buildDetailRow(
                  "ชื่อวัคซีน:",
                  alert['vaccine_name'] ?? 'ไม่ระบุชื่อ',
                ),
                _buildDetailRow(
                  "คอกเป้าหมาย:",
                  "คอก ${_coopNames[alert['coop_id']?.toString()] ?? alert['coop_id'] ?? '-'}",
                ),
                _buildDetailRow(
                  "อายุไก่:",
                  "${alert['chicken_age'] ?? '-'} วัน",
                ),
                _buildDetailRow(
                  "ประเภทการให้:",
                  alert['injection_type'] ?? '-',
                ),
                _buildDetailRow(
                  "หมายเหตุ:",
                  alert['description'] != null &&
                          alert['description'].toString().isNotEmpty
                      ? alert['description']
                      : 'ไม่มีหมายเหตุ',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: ez.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      "ปิด",
                      style: GoogleFonts.kanit(
                        color: ez.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
          '$backendBaseUrl/api/vaccines/schedule/update?old_name=${Uri.encodeComponent(oldName)}';

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
      text: alert['vaccine_name']?.toString() ?? '',
    );
    TextEditingController ageController = TextEditingController(
      text: alert['chicken_age']?.toString() ?? '',
    );
    TextEditingController noteController = TextEditingController(
      text: alert['description']?.toString() ?? '',
    );
    // ถ้าค่าเดิมไม่ตรงกับตัวเลือกมาตรฐาน (เช่น ข้อมูลเก่าที่กรอกแบบอิสระ) ให้เริ่มจากยังไม่เลือก
    String? selectedMethod = alert['injection_type']?.toString();
    if (selectedMethod == null ||
        !kVaccineMethodOptions.contains(selectedMethod)) {
      selectedMethod = null;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        final ez = ezColors(dialogContext);
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
              backgroundColor: ezCardColor(dialogContext),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                              Icons.edit_note_rounded,
                              color: ez.gold,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "แก้ไขข้อมูลวัคซีน",
                              style: GoogleFonts.kanit(
                                color: ez.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      EzFormTextField(
                        label: 'ชื่อวัคซีน',
                        isRequired: true,
                        controller: nameController,
                        hintText: 'เช่น นิวคาสเซิล',
                      ),
                      const SizedBox(height: 12),
                      EzFormTextField(
                        label: 'อายุไก่',
                        isRequired: true,
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        hintText: 'เช่น 7',
                        suffixText: 'วัน',
                      ),
                      const SizedBox(height: 12),
                      EzFormDropdown<String>(
                        label: 'วิธีการให้',
                        isRequired: true,
                        value: selectedMethod,
                        hint: 'เลือกวิธีการให้',
                        items: kVaccineMethodOptions
                            .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setDialogState(() => selectedMethod = val),
                      ),
                      const SizedBox(height: 12),
                      EzFormTextField(
                        label: 'หมายเหตุ',
                        controller: noteController,
                        hintText: 'ไม่บังคับ',
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                side: BorderSide(color: ez.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Text(
                                "ยกเลิก",
                                style: GoogleFonts.kanit(
                                  color: ez.textSecondary,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ez.accentGreen,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                if (nameController.text.trim().isEmpty) {
                                  showEzTopBanner(
                                    dialogContext,
                                    'กรุณากรอกชื่อวัคซีน',
                                    type: EzBannerType.warning,
                                  );
                                  return;
                                }
                                if (selectedMethod == null) {
                                  showEzTopBanner(
                                    dialogContext,
                                    'กรุณาเลือกวิธีการให้',
                                    type: EzBannerType.warning,
                                  );
                                  return;
                                }

                                // ลบตัวอักษรอื่นออก เหลือแต่ตัวเลข ป้องกัน user พิมพ์คำว่า 'วัน' ติดมา
                                String numericString = ageController.text
                                    .trim()
                                    .replaceAll(RegExp(r'[^0-9]'), '');
                                int parsedAge =
                                    int.tryParse(numericString) ?? 0;

                                Navigator.pop(dialogContext);
                                editVaccineAlertData(
                                  oldName: alert['vaccine_name'] ?? '',
                                  newName: nameController.text.trim(),
                                  age: parsedAge,
                                  type: selectedMethod!,
                                  note: noteController.text.trim(),
                                );
                              },
                              child: Text(
                                "บันทึก",
                                style: GoogleFonts.kanit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
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
          },
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
    List<dynamic> alertsForSelectedDay = _coopFilteredAlerts.where((alert) {
      if (alert['date'] == null) return false;
      DateTime alertDate = DateTime.parse(alert['date']).toLocal();
      return alertDate.year == _selectedDay.year &&
          alertDate.month == _selectedDay.month &&
          alertDate.day == _selectedDay.day;
    }).toList();

    return Scaffold(
      extendBody: true,
      backgroundColor: ezBackgroundColor(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: EzHeader(
                pageTitle: widget.initialCoopId != null
                    ? 'วัคซีนคอก ${_coopNames[widget.initialCoopId] ?? widget.initialCoopId}'
                    : 'ตารางวัคซีน',
                trailing: IconButton(
                  icon: Icon(
                    Icons.calendar_today_outlined,
                    color: ezColors(context).textPrimary,
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedDay = DateTime.now();
                    });
                  },
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    CustomCalendar(
                      key: ValueKey(
                        _selectedDay.toString() +
                            _dayMarkers.length.toString(),
                      ),
                      initialDate: _selectedDay,
                      dayMarkers: _dayMarkers,
                      onDateSelected: (selectedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                        });
                      },
                      onDayLongPress: (day, marker) =>
                          _showDayMarkerPopup(day, marker),
                    ),
                    const SizedBox(height: 25),
                    _isLoading
                        ? Skeletonizer(
                            enabled: true,
                            child: Column(
                              children: List.generate(
                                2,
                                (_) => buildAlertCard({
                                  'vaccine_name': 'วัคซีนตัวอย่าง',
                                  'coop_id': '1',
                                  'injection_type': 'หยอดตา',
                                  'chicken_age': '7',
                                  'description': '-',
                                  'is_completed': false,
                                  'is_overdue': false,
                                }),
                              ),
                            ),
                          )
                        : alertsForSelectedDay.isEmpty
                        ? Text(
                            "ไม่มีคิวฉีดวัคซีนในวันนี้",
                            style: GoogleFonts.kanit(
                              color: ezColors(context).textPrimary,
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
          child: Icon(Icons.add, color: Colors.white, size: 36),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected,
      ),
    );
  }

  Widget _buildMiniInfo(
    EzColors ez, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: ez.textSecondary),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.kanit(fontSize: 10.5, color: ez.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.kanit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: ez.textPrimary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget buildAlertCard(Map<String, dynamic> alert) {
    final ez = ezColors(context);
    bool isCompleted = alert['is_completed'] ?? false;
    bool isOverdue = alert['is_overdue'] ?? false;
    String rawCoopId = alert['coop_id']?.toString() ?? '-';
    String coopId = _coopNames[rawCoopId] ?? rawCoopId;
    String vaccineName = alert['vaccine_name'] ?? 'ไม่ระบุชื่อวัคซีน';
    String injectionType =
        (alert['injection_type']?.toString().isNotEmpty ?? false)
        ? alert['injection_type']
        : '-';
    String chickenAge = alert['chicken_age']?.toString() ?? '-';
    String remark = alert['description']?.toString() ?? '';

    late final Color statusBg;
    late final Color statusFg;
    late final String statusLabel;
    late final IconData statusIcon;
    if (isCompleted) {
      statusBg = ez.chipGreenBg;
      statusFg = ez.chipGreenText;
      statusLabel = 'ให้วัคซีนแล้ว';
      statusIcon = Icons.check_circle_rounded;
    } else if (isOverdue) {
      statusBg = ez.danger.withValues(alpha: 0.15);
      statusFg = ez.danger;
      statusLabel = 'เลยกำหนดฉีด';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusBg = ez.chipOrangeBg;
      statusFg = ez.chipOrangeText;
      statusLabel = 'รอฉีดวัคซีน';
      statusIcon = Icons.schedule_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: ezCardDecoration(context, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.vaccines_rounded, color: statusFg, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vaccineName,
                      style: GoogleFonts.kanit(
                        color: ez.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusFg),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: GoogleFonts.kanit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusFg,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.edit_outlined,
                  color: ez.textSecondary,
                  size: 20,
                ),
                tooltip: 'แก้ไข',
                onPressed: () => showEditVaccineDialog(alert),
              ),
              const SizedBox(width: 4),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.info_outline,
                  color: ez.textSecondary,
                  size: 20,
                ),
                tooltip: 'ดูรายละเอียด',
                onPressed: () => showVaccineDetailDialog(alert),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: ez.inputFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildMiniInfo(
                    ez,
                    icon: Icons.home_work_outlined,
                    label: 'คอก',
                    value: coopId,
                  ),
                ),
                Container(width: 1, height: 32, color: ez.border),
                Expanded(
                  child: _buildMiniInfo(
                    ez,
                    icon: Icons.cake_outlined,
                    label: 'อายุไก่',
                    value: '$chickenAge วัน',
                  ),
                ),
                Container(width: 1, height: 32, color: ez.border),
                Expanded(
                  child: _buildMiniInfo(
                    ez,
                    icon: Icons.medical_services_outlined,
                    label: 'วิธีให้',
                    value: injectionType,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.sticky_note_2_outlined,
                size: 14,
                color: ez.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  remark.isNotEmpty ? remark : 'ไม่มีหมายเหตุ',
                  style: GoogleFonts.kanit(
                    color: ez.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                    fontStyle: remark.isNotEmpty
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          InkWell(
            onTap: () {
              bool newValue = !isCompleted;
              setState(() {
                alert['is_completed'] = newValue;
                _updateDayMarkers();
              });
              updateCompletionStatus(alert, newValue);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isCompleted ? ez.cardAlt : ez.accentGreen,
                borderRadius: BorderRadius.circular(10),
                border: isCompleted ? Border.all(color: ez.border) : null,
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle : Icons.vaccines,
                    color: isCompleted ? ez.textSecondary : Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCompleted
                        ? "ให้วัคซีนแล้ว (แตะเพื่อยกเลิก)"
                        : "เสร็จสิ้น (ให้วัคซีน)",
                    style: GoogleFonts.kanit(
                      color: isCompleted ? ez.textSecondary : Colors.white,
                      fontSize: 14.5,
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
