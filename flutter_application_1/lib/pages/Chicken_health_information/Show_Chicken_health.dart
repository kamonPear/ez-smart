import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/calendar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
// import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bottombar.dart';
import 'Edit_Datachicken_health.dart';
import 'Add_Datachicken_health.dart';
import '../../widgets/ez_header.dart';
import '../../services/backend_config.dart';

class Chickenhealth extends StatefulWidget {
  final String? initialCoopId;

  const Chickenhealth({super.key, this.initialCoopId});

  @override
  State<Chickenhealth> createState() => _ChickenhealthState();
}

class _ChickenhealthState extends State<Chickenhealth> {
  int selectedIndex = 0;

  List<dynamic> allHealthDataList = [];
  List<dynamic> displayedHealthDataList = [];
  bool isLoading = true;

  DateTime _selectedDate = DateTime.now();
  bool isFilteringByDate =
      false; // ✅ เพิ่มตัวแปรสำหรับเช็คว่ากำลังกรองด้วยวันที่อยู่หรือไม่

  Map<String, String> _coopNames =
      {}; // ✅ แผนที่ coop_id -> ชื่อคอก สำหรับแสดงผล

  @override
  void initState() {
    super.initState();
    fetchHealthData();
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

  List<DateTime> _getMarkedDates() {
    List<DateTime> dates = [];
    for (var data in allHealthDataList) {
      if (data['record_date'] != null) {
        try {
          DateTime parsedDate = DateTime.parse(data['record_date']).toLocal();
          dates.add(
            DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
          );
        } catch (e) {
          print('Error parsing date for marker: $e');
        }
      }
    }
    return dates;
  }

  Future<void> _selectDate(BuildContext context) async {
    List<DateTime> markedDates = _getMarkedDates();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          child: CustomCalendar(
            initialDate: _selectedDate,
            markedDates: markedDates,
            onDateSelected: (DateTime newSelected) {
              setState(() {
                _selectedDate = newSelected;
                isFilteringByDate = true; // ✅ เมื่อเลือกวัน ให้เปิดโหมดกรอง
                _filterDataByDate();
              });
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  // ✅ ฟังก์ชันกรองข้อมูลที่ถูกปรับแก้
  void _filterDataByDate() {
    setState(() {
      // ✅ ถ้าเปิดหน้านี้มาจากคอกใดคอกหนึ่งโดยเฉพาะ ให้กรองเหลือแค่คอกนั้นก่อน
      List<dynamic> base = widget.initialCoopId != null
          ? allHealthDataList.where((data) {
              String coopId =
                  data['coop_id']?.toString() ??
                  data['coop_number']?.toString() ??
                  '';
              return coopId == widget.initialCoopId;
            }).toList()
          : List.from(allHealthDataList);

      if (!isFilteringByDate) {
        // ถ้าไม่ได้อยู่ในโหมดกรองวันที่ ให้แสดงข้อมูลทั้งหมด (ของคอกที่เลือกถ้ามี)
        displayedHealthDataList = base;
      } else {
        // ถ้าอยู่ในโหมดกรอง ให้ดึงเฉพาะข้อมูลของวันที่เลือก
        displayedHealthDataList = base.where((data) {
          if (data['record_date'] == null) return false;
          try {
            DateTime recordDate = DateTime.parse(data['record_date']).toLocal();
            return recordDate.year == _selectedDate.year &&
                recordDate.month == _selectedDate.month &&
                recordDate.day == _selectedDate.day;
          } catch (e) {
            return false;
          }
        }).toList();
      }
    });
  }

  // ✅ เช็คว่ารายการนี้เป็น "นัดหมายตรวจล่วงหน้า" หรือไม่ (วันที่ตรวจยังมาไม่ถึง)
  bool _isAppointmentRecord(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return false;
    try {
      final recordDate = DateTime.parse(dateStr).toLocal();
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      final dateOnly = DateTime(
        recordDate.year,
        recordDate.month,
        recordDate.day,
      );
      return dateOnly.isAfter(todayOnly);
    } catch (e) {
      return false;
    }
  }

  Map<String, String> _formatDateForCard(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty)
      return {'day': '-', 'monthYear': '-'};
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      final day = dateTime.day.toString().padLeft(2, '0');
      const months = [
        'JAN',
        'FEB',
        'MAR',
        'APR',
        'MAY',
        'JUN',
        'JUL',
        'AUG',
        'SEP',
        'OCT',
        'NOV',
        'DEC',
      ];
      final month = months[dateTime.month - 1];
      return {'day': day, 'monthYear': '$month ${dateTime.year}'};
    } catch (e) {
      return {'day': '??', 'monthYear': '??'};
    }
  }

  Future<void> fetchHealthData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse('$backendBaseUrl/api/healths');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          allHealthDataList = json.decode(response.body);
          _filterDataByDate(); // จะแสดงข้อมูลทั้งหมดในครั้งแรก เพราะ isFilteringByDate เป็น false
          isLoading = false;
        });
      } else {
        print('โหลดข้อมูลไม่สำเร็จ: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการดึงข้อมูล: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<bool> _executeDeleteAPI(String id) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: Colors.red)),
    );

    try {
      final url = Uri.parse('$backendBaseUrl/api/healths?id=$id');
      print('==== URL ที่ส่งไป: $url ====');

      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (!context.mounted) return false;
      Navigator.of(context, rootNavigator: true).pop();

      print('==== Status Code จาก Backend: ${response.statusCode} ====');
      print('==== ข้อความจาก Backend: ${response.body} ====');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ลบข้อมูลสำเร็จ', style: GoogleFonts.kanit()),
            backgroundColor: Colors.green,
          ),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'เกิดข้อผิดพลาดในการลบ: ${response.statusCode}',
              style: GoogleFonts.kanit(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      if (!context.mounted) return false;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $e',
            style: GoogleFonts.kanit(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  void onTabSelected(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CloseOpenDoor()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Mainchicken()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainShowDataFood()),
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

  void _showHealthDataBottomSheet(
    BuildContext context, {
    Map<String, dynamic>? existingData,
  }) {
    String healthy = '0';
    String sick = '0';
    String total = '0';
    String coopNumber = '-';
    DateTime targetDate = DateTime.now();

    if (existingData != null) {
      healthy = existingData['healthy']?.toString() ?? '0';
      sick = existingData['poor_health']?.toString() ?? '0';

      String rawCoopId =
          existingData['coop_id']?.toString() ??
          existingData['coop_number']?.toString() ??
          '-';
      coopNumber = _coopNames[rawCoopId] ?? rawCoopId;

      int h = int.tryParse(healthy) ?? 0;
      int s = int.tryParse(sick) ?? 0;
      total = (h + s).toString();

      if (existingData['record_date'] != null) {
        try {
          targetDate = DateTime.parse(existingData['record_date']).toLocal();
        } catch (e) {
          print('Error parsing date: $e');
        }
      }
    }

    final dayStr = targetDate.day.toString().padLeft(2, '0');
    final yearStr = targetDate.year.toString();

    const monthsEN = [
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
    const monthsTH = [
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];

    String displayDateEN = '$dayStr ${monthsEN[targetDate.month - 1]} $yearStr';
    String displayDateTH = '$dayStr ${monthsTH[targetDate.month - 1]} $yearStr';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: const BoxDecoration(
            color: Color(0xFF1B242D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A3644),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.monitor_heart,
                  color: Colors.white70,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'ตรวจสุขภาพประจำวัน',
                style: GoogleFonts.kanit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (existingData != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'คอกที่: $coopNumber',
                    style: GoogleFonts.kanit(
                      color: const Color(0xFFFF6E5C),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.white70,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Center(
                        child: Text(
                          displayDateEN,
                          style: GoogleFonts.kanit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.greenAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ข้อมูลประจำวันที่',
                    style: GoogleFonts.kanit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                displayDateTH,
                style: GoogleFonts.kanit(
                  color: Colors.greenAccent,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              const Divider(color: Colors.white10, thickness: 1),
              const SizedBox(height: 16),

              Row(
                children: [
                  _buildSummaryCard(
                    'จำนวนทั้งหมด',
                    total,
                    'ตัว',
                    const Color(0xFF26323D),
                    Colors.white,
                  ),
                  const SizedBox(width: 10),
                  _buildSummaryCard(
                    'สุขภาพดี',
                    healthy,
                    'ตัว',
                    const Color(0xFF1E3A2F),
                    Colors.greenAccent,
                  ),
                  const SizedBox(width: 10),
                  _buildSummaryCard(
                    'สุขภาพไม่ดี',
                    sick,
                    'ตัว',
                    const Color(0xFF402528),
                    const Color(0xFFFF6E5C),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6E5C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);

                    dynamic result;
                    if (existingData != null) {
                      result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              Editckickenhealth(initialData: existingData),
                        ),
                      );
                    } else {
                      result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddDatachickenHealth(
                            initialCoopId: widget.initialCoopId,
                          ),
                        ),
                      );
                    }

                    if (result == true || result != null) {
                      fetchHealthData();
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        existingData != null ? 'แก้ไขข้อมูล' : 'บันทึกข้อมูล',
                        style: GoogleFonts.kanit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String count,
    String unit,
    Color bgColor,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.kanit(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 8),
            Text(
              count,
              style: GoogleFonts.kanit(
                color: textColor,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              unit,
              style: GoogleFonts.kanit(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    const Color highlightColor = Color(0xFFFF6E5C);
    const Color cardColor = ezCardColor;
    const Color greenTextColor = Color(0xFF4ADE80);
    const Color bgDarkColor = ezBackgroundColor;

    const monthsEN = [
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
    String displayMonth = monthsEN[_selectedDate.month - 1];
    String displayYear = _selectedDate.year.toString();

    return Scaffold(
      extendBody: true,
      backgroundColor: bgDarkColor,

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AddDatachickenHealth(initialCoopId: widget.initialCoopId),
              ),
            );

            if (result == true || result != null) {
              fetchHealthData();
            }
          },
          backgroundColor: highlightColor,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          icon: const Icon(Icons.add, color: Colors.white, size: 28),
          label: Text(
            'ตรวจสุขภาพ',
            style: GoogleFonts.kanit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          constraints: BoxConstraints(minHeight: screenHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EzHeader(pageTitle: widget.initialCoopId != null ? 'ตรวจสุขภาพไก่' : 'สุขภาพไก่ทั้งหมด'),
                const SizedBox(height: 20),

                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151D24),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              displayMonth,
                              style: GoogleFonts.kanit(
                                fontSize: 16,
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
                              displayYear,
                              style: GoogleFonts.kanit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                border: Border.all(color: highlightColor),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.calendar_today_outlined,
                                color: highlightColor,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ✅ เปลี่ยนข้อความหัวข้อตามโหมด (ดูทั้งหมด / ดูกรองวัน)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isFilteringByDate
                          ? 'ประวัติวันที่ ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'
                          : widget.initialCoopId != null
                          ? 'ประวัติการตรวจสุขภาพคอก ${_coopNames[widget.initialCoopId] ?? widget.initialCoopId}'
                          : 'ประวัติการตรวจสุขภาพทั้งหมด',
                      style: GoogleFonts.kanit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    // ✅ ถ้ากำลังกรองวันอยู่ ให้มีปุ่มกดเพื่อกลับไป "ดูทั้งหมด"
                    if (isFilteringByDate)
                      InkWell(
                        onTap: () {
                          setState(() {
                            isFilteringByDate = false;
                            _filterDataByDate(); // เคลียร์ฟิลเตอร์
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.clear,
                                color: Color(0xFFFF6E5C),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ดูทั้งหมด',
                                style: GoogleFonts.kanit(
                                  color: const Color(0xFFFF6E5C),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(color: Colors.green),
                        ),
                      )
                    : displayedHealthDataList.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Text(
                            isFilteringByDate
                                ? 'ไม่พบข้อมูลการตรวจสุขภาพในวันนี้'
                                : 'ยังไม่มีประวัติการตรวจสุขภาพเลย',
                            style: GoogleFonts.kanit(
                              fontSize: 16,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: displayedHealthDataList.asMap().entries.map((
                          entry,
                        ) {
                          int index = entry.key;
                          var data = entry.value;

                          bool isLatest = (index == 0 && !isFilteringByDate);
                          var dateInfo = _formatDateForCard(
                            data['record_date']?.toString(),
                          );
                          String healthy = data['healthy']?.toString() ?? '0';
                          String sick = data['poor_health']?.toString() ?? '0';

                          String rawCoopId =
                              data['coop_id']?.toString() ??
                              data['coop_number']?.toString() ??
                              '-';
                          String coopNumber =
                              _coopNames[rawCoopId] ?? rawCoopId;
                          String noteRaw = data['note']?.toString() ?? '';
                          String note = noteRaw.trim().isEmpty
                              ? 'ปกติ'
                              : noteRaw;

                          String uniqueKey =
                              data['id']?.toString() ??
                              data['ID']?.toString() ??
                              data['health_id']?.toString() ??
                              UniqueKey().toString();
                          bool isAppointment = _isAppointmentRecord(
                            data['record_date']?.toString(),
                          );

                          return Dismissible(
                            key: Key(uniqueKey),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12.0),
                              decoration: BoxDecoration(
                                color: Colors.red.shade700,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              bool? confirm = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext dialogContext) {
                                  return AlertDialog(
                                    backgroundColor: const Color(0xFF2A3644),
                                    title: Text(
                                      'ยืนยันการลบ',
                                      style: GoogleFonts.kanit(
                                        color: Colors.white,
                                      ),
                                    ),
                                    content: Text(
                                      'คุณต้องการลบข้อมูลการตรวจสุขภาพนี้ใช่หรือไม่?',
                                      style: GoogleFonts.kanit(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(
                                          dialogContext,
                                        ).pop(false),
                                        child: Text(
                                          'ยกเลิก',
                                          style: GoogleFonts.kanit(
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(
                                          dialogContext,
                                        ).pop(true),
                                        child: Text(
                                          'ลบ',
                                          style: GoogleFonts.kanit(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirm == true) {
                                var rawId =
                                    data['id'] ??
                                    data['ID'] ??
                                    data['health_id'];

                                if (rawId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'เกิดข้อผิดพลาด: ไม่พบ ID ของข้อมูล',
                                        style: GoogleFonts.kanit(),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return false;
                                }

                                String idToDelete = rawId.toString();
                                bool isDeleted = await _executeDeleteAPI(
                                  idToDelete,
                                );
                                return isDeleted;
                              }
                              return false;
                            },
                            onDismissed: (direction) {
                              setState(() {
                                allHealthDataList.removeWhere(
                                  (item) =>
                                      (item['id']?.toString() ??
                                          item['ID']?.toString()) ==
                                      uniqueKey,
                                );
                                displayedHealthDataList.removeAt(index);
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  _showHealthDataBottomSheet(
                                    context,
                                    existingData: data,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: isLatest
                                        ? Border.all(
                                            color: highlightColor,
                                            width: 1.5,
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 75,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              dateInfo['day']!,
                                              style: GoogleFonts.kanit(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                height: 1.1,
                                              ),
                                            ),
                                            Text(
                                              dateInfo['monthYear']!,
                                              style: GoogleFonts.kanit(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 12.0,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (isAppointment)
                                                Container(
                                                  margin: const EdgeInsets
                                                      .only(bottom: 8),
                                                  padding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFF42A5F5,
                                                    ).withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      6,
                                                    ),
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFF42A5F5,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.event_available,
                                                        size: 12,
                                                        color: Color(
                                                          0xFF42A5F5,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width: 4,
                                                      ),
                                                      Text(
                                                        'นัดหมายล่วงหน้า',
                                                        style:
                                                            GoogleFonts.kanit(
                                                          fontSize: 11,
                                                          color: const Color(
                                                            0xFF42A5F5,
                                                          ),
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    width: 85,
                                                    child: Text(
                                                      'คอกที่',
                                                      style: GoogleFonts.kanit(
                                                        fontSize: 14,
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    coopNumber,
                                                    style: GoogleFonts.kanit(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: highlightColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    width: 85,
                                                    child: Text(
                                                      'สุขภาพดี',
                                                      style: GoogleFonts.kanit(
                                                        fontSize: 14,
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    '$healthy ตัว',
                                                    style: GoogleFonts.kanit(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: greenTextColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    width: 85,
                                                    child: Text(
                                                      'สุขภาพไม่ดี',
                                                      style: GoogleFonts.kanit(
                                                        fontSize: 14,
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    '$sick ตัว',
                                                    style: GoogleFonts.kanit(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: const Color(
                                                        0xFFFF6E5C,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'หมายเหตุ: $note',
                                                style: GoogleFonts.kanit(
                                                  fontSize: 13,
                                                  color: Colors.white70,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      const Padding(
                                        padding: EdgeInsets.only(left: 8.0),
                                        child: Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.white54,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
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
}
