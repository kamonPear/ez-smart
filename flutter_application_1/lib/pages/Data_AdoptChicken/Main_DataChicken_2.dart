import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Main_SenSor/Main_DeviceSummary.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bottombar.dart';
import '../main_dash.dart';
import '../../widgets/ez_header.dart';
import '../../services/api_client.dart';
import '../../services/calendar_overview_service.dart';
import '../../services/backend_config.dart';
import '../../utils/thai_date.dart';
import 'Main_CoopDetail.dart';

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

  // กดรายการในปฏิทินรวมแล้วพาไปหน้ารายละเอียดของคอกนั้น (ต้องมี coopId ผูกมากับรายการ)
  // CoopDetailPage ไม่ได้ดึงข้อมูลพื้นฐานของคอก (ชื่อ/จำนวน/อุณหภูมิ/PPM/สุขภาพ/ไข่) เอง
  // ต้องประกอบให้ครบก่อนส่งไป ไม่งั้นจะโชว์เป็น "null" เต็มหน้า (เหมือนหน้าคอกไก่รวมที่ทำไว้)
  Future<void> _openCoop(String? coopId) async {
    if (coopId == null || coopId.isEmpty || coopId == '-') return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: CircularProgressIndicator(color: ezColors(context).gold),
      ),
    );

    try {
      final results = await Future.wait([
        ApiClient.get(Uri.parse('$backendBaseUrl/api/coops')),
        ApiClient.get(Uri.parse('$backendBaseUrl/api/healths')),
        ApiClient.get(Uri.parse('$backendBaseUrl/api/devices')),
        ApiClient.get(Uri.parse('$backendBaseUrl/api/eggs')),
      ]);

      Map<String, dynamic>? coopRaw;
      if (results[0].statusCode == 200) {
        final List<dynamic> coops = jsonDecode(results[0].body);
        for (final c in coops) {
          if ((c['coop_id'] ?? c['id']).toString() == coopId) {
            coopRaw = c;
            break;
          }
        }
      }

      if (!mounted) return;
      Navigator.pop(context); // ปิด dialog โหลด

      if (coopRaw == null) {
        debugPrint('❌ ไม่พบข้อมูลคอก $coopId');
        return;
      }
      final coop = coopRaw;

      int healthy = 0;
      int poor = 0;
      if (results[1].statusCode == 200) {
        final List<dynamic> healths = jsonDecode(results[1].body);
        for (final h in healths) {
          if (h['coop_id']?.toString() != coopId) continue;
          healthy = int.tryParse(h['healthy']?.toString() ?? '') ?? 0;
          poor = int.tryParse(h['poor_health']?.toString() ?? '') ?? 0;
        }
      }

      String temp = '0';
      String ppm = '0';
      if (results[2].statusCode == 200) {
        final List<dynamic> devices = jsonDecode(results[2].body);
        for (final d in devices) {
          if (d['coop_id']?.toString() != coopId) continue;
          final name = (d['name'] ?? '').toString().toLowerCase();
          final value = d['value']?.toString() ?? '';
          if (name.contains('อุณหภูมิ') || name.contains('dht')) {
            temp = value;
          } else if (name.contains('แอมโมเนีย') || name.contains('mq')) {
            ppm = value;
          }
        }
      }

      final Map<String, List<double>> eggByYear = {};
      if (results[3].statusCode == 200) {
        final List<dynamic> eggs = jsonDecode(results[3].body);
        for (final egg in eggs) {
          if (egg['coop_id']?.toString() != coopId) continue;
          String year = DateTime.now().year.toString();
          int month = DateTime.now().month;
          if (egg['date_collect_egg'] != null) {
            try {
              final parsed = DateTime.parse(
                egg['date_collect_egg'].toString(),
              ).toLocal();
              year = parsed.year.toString();
              month = parsed.month;
            } catch (_) {
              // ใช้วันที่ปัจจุบันแทนถ้าพาร์สไม่ได้
            }
          }
          final amount =
              double.tryParse((egg['number_egg'] ?? '0').toString()) ?? 0.0;
          eggByYear.putIfAbsent(year, () => List.filled(12, 0.0));
          if (month >= 1 && month <= 12) {
            eggByYear[year]![month - 1] += amount;
          }
        }
      }

      final name = (coop['name_coop']?.toString().trim().isNotEmpty == true)
          ? coop['name_coop'].toString()
          : coopId;

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CoopDetailPage(
            coop: {
              'id': coopId,
              'name': name,
              'amount': coop['amount']?.toString() ?? '0',
              'import_date': thaiDateFromIso(
                coop['date_adopt_animals']?.toString(),
              ),
              'birth_date': thaiDateFromIso(coop['birthday']?.toString()),
              'healthy': healthy.toString(),
              'poor_health': poor.toString(),
              'temp': temp,
              'ppm': ppm,
              'egg_data': eggByYear,
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context); // ปิด dialog โหลดถ้าพลาด
      debugPrint('❌ โหลดข้อมูลคอกไม่สำเร็จ: $e');
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
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: item.coopId == null
                          ? null
                          : () {
                              Navigator.pop(dialogContext);
                              _openCoop(item.coopId);
                            },
                      borderRadius: BorderRadius.circular(10),
                      child: _detailRow(item, rowContext: dialogContext),
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
        MaterialPageRoute(builder: (context) => const MainDeviceSummary()),
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

  Widget _statusBadge(CalendarItemStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: GoogleFonts.kanit(
          color: status.color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _detailRow(DayDetailItem item, {required BuildContext rowContext}) {
    final ez = ezColors(rowContext);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: item.status.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.category.icon, color: item.status.color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.category.label,
                      style: GoogleFonts.kanit(
                        color: ez.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _statusBadge(item.status),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                item.text,
                style: GoogleFonts.kanit(
                  color: ez.textPrimary,
                  fontWeight: FontWeight.normal,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: EzHeader(pageTitle: 'ปฏิทินรวม'),
            ),
            const SizedBox(height: 10),

            // --- เนื้อหา ---
            Expanded(
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
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        _legendDot(kCalendarGreen, 'แจ้งให้ทราบ / ทำแล้ว'),
                        _legendDot(
                          kCalendarAmber,
                          'นัดล่วงหน้า - ยังไม่ถึงกำหนด',
                        ),
                        _legendDot(kCalendarRed, 'เกินกำหนด - ยังไม่ทำ'),
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
                        (item) => Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _openCoop(item.coopId),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: ez.card,
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    item.status == CalendarItemStatus.overdue
                                    ? Border.all(
                                        color: kCalendarRed.withValues(
                                          alpha: 0.5,
                                        ),
                                        width: 1.3,
                                      )
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.15,
                                    ),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: _detailRow(item, rowContext: context),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected,
      ),
    );
  }
}
