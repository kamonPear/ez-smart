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
  // เดือนที่กำลังดูอยู่ในปฏิทิน (เลื่อนลูกศรเปลี่ยนได้) - ใช้กำหนดจุดเริ่มของรายการ
  // สรุปด้านล่างแทนการยึดติดกับ "วันนี้" เสมอ เพื่อให้เลื่อนไปเดือนไหนก็เห็นรายการ
  // ของเดือนนั้นจริงๆ
  DateTime _viewedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
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

    // ปิดวงล้อโหลดได้ครั้งเดียวเท่านั้น - ถ้าปิดไปแล้วแต่โค้ดหลังจากนั้นพัง
    // catch จะไม่ pop ซ้ำจนปิดหน้าทั้งหน้าไปด้วย
    var dialogOpen = true;
    void closeLoadingDialog() {
      if (!dialogOpen) return;
      dialogOpen = false;
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }

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

      closeLoadingDialog();
      if (!mounted) return;

      if (coopRaw == null) {
        debugPrint('❌ ไม่พบข้อมูลคอก $coopId');
        return;
      }
      final coop = coopRaw;

      int healthy = 0;
      int poor = 0;
      if (results[1].statusCode == 200) {
        final List<dynamic> healths = jsonDecode(results[1].body);
        // เทียบ record_date หาแถวที่ใหม่ที่สุดจริงๆ แทนการเชื่อว่าแถวหลังสุดใน
        // response คือผลตรวจล่าสุด (backend ไม่ได้การันตีลำดับ) - ถ้าวันไหนยังไม่มี
        // การตรวจใหม่ ค่าที่ตรวจล่าสุดเดิมจะยังค้างแสดงต่อไปเรื่อยๆ ไม่รีเซ็ตเป็น 0
        DateTime? latestDate;
        for (final h in healths) {
          if (h['coop_id']?.toString() != coopId) continue;
          final recordDate = DateTime.tryParse(
            h['record_date']?.toString() ?? '',
          );
          if (recordDate == null) continue;
          if (latestDate != null && !recordDate.isAfter(latestDate)) continue;
          latestDate = recordDate;
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
              'age_text': chickenAgeFromIso(coop['birthday']?.toString()),
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
      closeLoadingDialog();
      debugPrint('❌ โหลดข้อมูลคอกไม่สำเร็จ: $e');
    }
  }

  // รายการสรุป "ของเดือนที่กำลังดูอยู่เป็นต้นไป" - อิงตามเดือนที่เลื่อนปฏิทินไปดูจริงๆ
  // (_viewedMonth) ไม่ใช่ "วันนี้" ตายตัว เพื่อให้เลื่อนไปเดือนไหนก็เห็นรายการของ
  // เดือนนั้นด้วย ไม่ใช่โดนกรองทิ้งเพราะผ่านไปแล้วเทียบกับวันนี้
  List<MapEntry<DateTime, DayMarkerInfo>> get _upcomingEntries {
    final monthStart = DateTime(_viewedMonth.year, _viewedMonth.month, 1);
    final entries = _dayMarkers.entries
        .where((e) => !e.key.isBefore(monthStart) && e.value.details.isNotEmpty)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

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
                child: Column(
                  children: [
                    // 1. ปฏิทินรวม (แทนตารางคอกรวมเดิม)
                    CustomCalendar(
                      key: ValueKey(
                        _selectedDay.toString() + _dayMarkers.length.toString(),
                      ),
                      initialDate: _selectedDay,
                      dayMarkers: _dayMarkers,
                      onDateSelected: (day) {
                        setState(() => _selectedDay = day);
                        final dayOnly = DateTime(day.year, day.month, day.day);
                        final m = _dayMarkers[dayOnly];
                        if (m != null && m.details.isNotEmpty) {
                          _showDayPopup(day, m);
                        }
                      },
                      onDayLongPress: (day, m) => _showDayPopup(day, m),
                      onMonthChanged: (month) =>
                          setState(() => _viewedMonth = month),
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

                    // กล่องรายการสรุป แยกออกจากกล่องปฏิทินด้านบนชัดเจน (เป็น
                    // ezCardDecoration ของตัวเอง) - กดวันไหนในปฏิทินแล้วเป็นป๊อบอัพ
                    // ของวันนั้นแทน (ดูด้านบน onDateSelected/onDayLongPress) ส่วน
                    // กล่องนี้เป็นสรุปรวมของเดือนที่กำลังดูอยู่เป็นต้นไปตลอดเวลา
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: ezCardDecoration(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'รายการเดือน${thaiMonthYear(_viewedMonth)}เป็นต้นไป',
                            style: GoogleFonts.kanit(
                              color: ez.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),

                          if (_isLoading)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: CircularProgressIndicator(color: ez.gold),
                              ),
                            )
                          else if (_upcomingEntries.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'ไม่มีรายการในเดือนนี้เป็นต้นไป',
                                style: GoogleFonts.kanit(
                                  color: ez.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          else
                            ..._upcomingEntries.expand(
                              (entry) => [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 6,
                                    top: 4,
                                  ),
                                  child: Text(
                                    thaiDate(entry.key),
                                    style: GoogleFonts.kanit(
                                      color: ez.textSecondary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                ...entry.value.details.map(
                                  (item) => Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _openCoop(item.coopId),
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: ezBackgroundColor(context),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border:
                                              item.status ==
                                                  CalendarItemStatus.overdue
                                              ? Border.all(
                                                  color: kCalendarRed
                                                      .withValues(alpha: 0.5),
                                                  width: 1.3,
                                                )
                                              : Border.all(
                                                  color: ez.border,
                                                  width: 1,
                                                ),
                                        ),
                                        child: _detailRow(
                                          item,
                                          rowContext: context,
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
