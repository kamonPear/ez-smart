import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Main_SenSor/Data_System.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/Vaccine/Main_Vaccine.dart';
import 'package:flutter_application_1/pages/calendar.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Chicken_health_information/Show_Chicken_health.dart';
import '../bottombar.dart';
import '../main_dash.dart';
import '../../widgets/ez_header.dart';
import '../../services/calendar_overview_service.dart';

class Mainchicken extends StatefulWidget {
  const Mainchicken({super.key});

  @override
  State<Mainchicken> createState() => _MainchickenState();
}

class _MainchickenState extends State<Mainchicken> {
  int selectedIndex = 3;

  DateTime _selectedDay = DateTime.now();
  Map<DateTime, DayMarkerInfo> _dayMarkers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMarkers();
  }

  Future<void> _fetchMarkers() async {
    setState(() => _isLoading = true);
    try {
      final markers = await loadCalendarOverviewMarkers();
      if (!mounted) return;
      setState(() {
        _dayMarkers = markers;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ โหลดข้อมูลปฏิทินรวมไม่สำเร็จ: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  DateTime get _selectedDayOnly =>
      DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);

  void _showDayPopup(DateTime day, DayMarkerInfo marker) {
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
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: marker.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.event_note_rounded,
                        color: marker.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${day.day}/${day.month}/${day.year}',
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
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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

  void onTabSelected(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainShowDataFood()),
      );
    } else if (index == 1) {
      Navigator.push(
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

  // --- ฟังก์ชันสร้างปุ่มเมนูสี่เหลี่ยม ---
  Widget _buildSquareMenu(
    IconData icon,
    String title,
    VoidCallback onTap, {
    double? width,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 110,
        decoration: BoxDecoration(
          color: ezCardColor(context), // สีพื้นหลังปุ่มแบบในรูป
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: ezColors(context).textPrimary, size: 45),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.kanit(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: ezColors(context).textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    final ez = ezColors(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.kanit(color: ez.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ez = ezColors(context);
    final marker = _dayMarkers[_selectedDayOnly];

    return Scaffold(
      extendBody: true,
      backgroundColor: ezBackgroundColor(context),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: EzHeader(pageTitle: 'ปฏิทินรวม'),
              ),
            ),
          ),

          // --- เนื้อหา ---
          Positioned(
            top: 110,
            left: 0,
            right: 0,
            bottom: 80,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // 1. ปฏิทินรวม (แทนตารางคอกรวมเดิม)
                  CustomCalendar(
                    key: ValueKey(
                      _selectedDay.toString() + _dayMarkers.length.toString(),
                    ),
                    initialDate: _selectedDay,
                    dayMarkers: _dayMarkers,
                    onDateSelected: (day) =>
                        setState(() => _selectedDay = day),
                    onDayLongPress: (day, m) => _showDayPopup(day, m),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legendDot(kCalendarGreen, 'แจ้งให้ทราบ / ทำแล้ว'),
                      const SizedBox(width: 16),
                      _legendDot(kCalendarRed, 'ยังไม่ทำ - เตือน'),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'รายการวันที่ ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                      style: GoogleFonts.kanit(
                        color: ez.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(color: ez.gold),
                    )
                  else if (marker == null || marker.details.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'ไม่มีรายการในวันนี้',
                        style: GoogleFonts.kanit(
                          color: ez.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    )
                  else
                    ...marker.details.map(
                      (item) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: ez.card,
                          borderRadius: BorderRadius.circular(14),
                          border: item.isPending
                              ? Border.all(
                                  color: kCalendarRed.withValues(alpha: 0.5),
                                  width: 1.3,
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          item.text,
                          style: GoogleFonts.kanit(
                            color: item.isPending
                                ? kCalendarRed
                                : ez.textPrimary,
                            fontWeight: item.isPending
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 25),

                  // 2. เมนูปุ่มด้านล่าง
                  Row(
                    children: [
                      // ปุ่มตรวจสุขภาพ
                      Expanded(
                        child: _buildSquareMenu(
                          Icons.medical_information_outlined,
                          "ตรวจสุขภาพ",
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Chickenhealth(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      // ปุ่มการให้วัคซีน
                      Expanded(
                        child: _buildSquareMenu(
                          Icons.vaccines_outlined,
                          "การให้วัคซีน",
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MainVaccine(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // ปุ่มอุปกรณ์และเซนเซอร์
                  _buildSquareMenu(
                    Icons.cell_tower,
                    "อุปกรณ์ และ เซนเซอร์",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DataSystem(),
                        ),
                      );
                    },
                    width: MediaQuery.of(context).size.width * 0.65,
                  ),

                  const SizedBox(height: 50),
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
}
