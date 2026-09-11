import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../services/backend_config.dart';
import '../Chicken_health_information/Show_Chicken_health.dart'
    hide backendBaseUrl;
import '../Main_SenSor/Data_System.dart';
import '../Vaccine/Main_Vaccine.dart';
import '../number_for_Egg/Add_egg.dart';
import '../number_for_Egg/Edit_NumberEggchicken_3.dart';
import '../../widgets/ez_header.dart';
import '../../widgets/ez_gauge.dart';
import '../../widgets/ez_egg_chart.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CoopDetailPage extends StatefulWidget {
  final Map<String, dynamic> coop;

  const CoopDetailPage({super.key, required this.coop});

  @override
  State<CoopDetailPage> createState() => _CoopDetailPageState();
}

class _CoopDetailPageState extends State<CoopDetailPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> dailyActivity = [];

  @override
  void initState() {
    super.initState();
    _fetchDailyActivity();
  }

  // 🌟 รวมกิจกรรมของคอกนี้ทั้งหมดเป็นรายการเดียว: ไข่ที่เก็บ, ตรวจสุขภาพที่บันทึกแล้ว,
  //    วัคซีนที่ให้แล้ว/ใกล้ถึงกำหนด (ภายใน 3 วัน เหมือนหน้าแจ้งเตือน) และคำนวณเพิ่ม
  //    "ควรตรวจสุขภาพ" ก่อนวันฉีดวัคซีน 1 วัน เพราะจะฉีดวัคซีนแค่ไก่ที่แข็งแรง
  //    รายการที่ "ยังไม่ทำ" (pending) จะมาร์คสีแดงไว้เตือน - ทำหน้าที่เป็นการแจ้งเตือนในตัว
  Future<void> _fetchDailyActivity() async {
    setState(() => isLoading = true);

    final coopId = widget.coop["id"].toString();
    List<Map<String, dynamic>> merged = [];
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    try {
      final results = await Future.wait([
        http.get(Uri.parse('$backendBaseUrl/api/eggs')),
        http.get(Uri.parse('$backendBaseUrl/api/healths')),
        http.get(Uri.parse('$backendBaseUrl/api/vaccines/alerts')),
      ]);

      // ไข่ที่เก็บแล้ว
      if (results[0].statusCode == 200) {
        final List<dynamic> eggs = jsonDecode(results[0].body);
        for (final e in eggs) {
          if (e['coop_id']?.toString() != coopId) continue;
          final date = DateTime.tryParse(
            e['date_collect_egg']?.toString() ?? '',
          );
          if (date == null) continue;
          merged.add({
            'type': 'egg',
            'date': DateTime(date.year, date.month, date.day),
            'text': '🥚 เก็บไข่ประจำวัน : ${e['number_egg'] ?? 0} ฟอง',
            'pending': false,
            'raw': e,
          });
        }
      }

      // ตรวจสุขภาพที่บันทึกแล้ว
      if (results[1].statusCode == 200) {
        final List<dynamic> healths = jsonDecode(results[1].body);
        for (final h in healths) {
          if (h['coop_id']?.toString() != coopId) continue;
          final date = DateTime.tryParse(h['record_date']?.toString() ?? '');
          if (date == null) continue;
          merged.add({
            'type': 'health',
            'date': DateTime(date.year, date.month, date.day),
            'text':
                '🩺 ตรวจสุขภาพ : สุขภาพดี ${h['healthy'] ?? 0} / ป่วย ${h['poor_health'] ?? 0} ตัว',
            'pending': false,
          });
        }
      }

      // วัคซีน (ให้แล้ว / ใกล้ถึงกำหนด) + ตรวจสุขภาพที่ "ควรทำ" ก่อนวันฉีด 1 วัน
      if (results[2].statusCode == 200) {
        final List<dynamic> alerts = jsonDecode(results[2].body);
        for (final a in alerts) {
          if (a['coop_id']?.toString() != coopId) continue;
          final dueDate = DateTime.tryParse(a['date']?.toString() ?? '');
          if (dueDate == null) continue;
          final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
          final vaccineName = a['vaccine_name']?.toString() ?? 'วัคซีน';
          final isCompleted = a['is_completed'] == true;

          if (isCompleted) {
            merged.add({
              'type': 'vaccine',
              'date': dueOnly,
              'text': '💉 ให้$vaccineNameแล้ว',
              'pending': false,
            });
            continue;
          }

          final daysUntil = dueOnly.difference(todayOnly).inDays;
          if (daysUntil > 3) continue; // เตือนล่วงหน้าแค่ 3 วัน เหมือนหน้าแจ้งเตือน

          merged.add({
            'type': 'vaccine',
            'date': dueOnly,
            'text': daysUntil < 0
                ? '💉 เลยกำหนดให้$vaccineNameมา ${-daysUntil} วันแล้ว'
                : daysUntil == 0
                ? '💉 วันนี้ถึงกำหนดให้$vaccineName'
                : '💉 อีก $daysUntil วันถึงกำหนดให้$vaccineName',
            'pending': true,
          });

          // ตรวจสุขภาพก่อนฉีดวัคซีน 1 วัน (คัดเอาแต่ไก่แข็งแรงไปฉีด)
          final healthDueOnly = dueOnly.subtract(const Duration(days: 1));
          final healthDaysUntil = healthDueOnly
              .difference(todayOnly)
              .inDays;
          if (healthDaysUntil <= 3) {
            merged.add({
              'type': 'health_due',
              'date': healthDueOnly,
              'text': healthDaysUntil < 0
                  ? '🩺 ควรตรวจสุขภาพก่อนให้$vaccineName (เลยกำหนดมา ${-healthDaysUntil} วัน)'
                  : healthDaysUntil == 0
                  ? '🩺 วันนี้ควรตรวจสุขภาพ เตรียมให้$vaccineNameวันพรุ่งนี้'
                  : '🩺 อีก $healthDaysUntil วันควรตรวจสุขภาพ เตรียมให้$vaccineNameวันที่ ${dueOnly.day}/${dueOnly.month}',
              'pending': true,
            });
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Connection/Parsing error: $e");
    }

    merged.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );

    setState(() {
      dailyActivity = merged;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.coop;

    int healthyCount = int.tryParse(data["healthy"].toString()) ?? 0;
    int poorCount = int.tryParse(data["poor_health"].toString()) ?? 0;

    double tempValue = double.tryParse(data["temp"].toString()) ?? 0.0;
    double ppmValue = double.tryParse(data["ppm"].toString()) ?? 0.0;
    double tempPercent = (tempValue / 50.0).clamp(0.0, 1.0);
    double ppmPercent = (ppmValue / 100.0).clamp(0.0, 1.0);

    String cleanAmount = data["amount"].toString().replaceAll(
      RegExp(r'ตัว|\s'),
      '',
    );

    return Scaffold(
      backgroundColor: ezBackgroundColor(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: EzHeader(pageTitle: 'คอกไก่ ${data["name"]}'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 15,
                      ),
                      decoration: ezCardDecoration(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          EzGaugeCard(
                            icon: Icons.thermostat_outlined,
                            value: data["temp"].toString(),
                            unit: "°",
                            subTitle: "อุณหภูมิที่ตั้งไว้คงที่",
                            color: Colors.cyan,
                            percent: tempPercent,
                          ),
                          EzGaugeCard(
                            icon: Icons.air_outlined,
                            value: data["ppm"].toString(),
                            unit: "PPM",
                            subTitle: "ปริมาณแอมโมเนียที่ตั้งไว้คงที่",
                            color: Colors.orange.shade800,
                            percent: ppmPercent,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: ezCardDecoration(context, radius: 25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'คอกไก่ ${data["name"]}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.kanit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: ezColors(context).textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: ezColors(
                                          context,
                                        ).textPrimary.withValues(alpha: 0.06),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '🐔',
                                        style: TextStyle(fontSize: 40),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          cleanAmount,
                                          style: GoogleFonts.kanit(
                                            color: const Color(0xFFFCA5A5),
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                            height: 1,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          "ตัว",
                                          style: GoogleFonts.kanit(
                                            color: ezColors(
                                              context,
                                            ).textPrimary,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 14),
                                    Text(
                                      "สุขภาพไก่",
                                      style: GoogleFonts.kanit(
                                        color: ezColors(context).textPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Row(
                                            children: [
                                              if (healthyCount > 0)
                                                Expanded(
                                                  flex: healthyCount,
                                                  child: Container(
                                                    color: const Color(
                                                      0xFF4ADE80,
                                                    ),
                                                    height: 22,
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      "$healthyCount",
                                                      style: TextStyle(
                                                        color: ezColors(
                                                          context,
                                                        ).textPrimary,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              if (poorCount > 0)
                                                Expanded(
                                                  flex: poorCount,
                                                  child: Container(
                                                    color: const Color(
                                                      0xFFEF4444,
                                                    ),
                                                    height: 22,
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      "$poorCount",
                                                      style: TextStyle(
                                                        color: ezColors(
                                                          context,
                                                        ).textPrimary,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              if (healthyCount == 0 &&
                                                  poorCount == 0)
                                                Expanded(
                                                  flex: 1,
                                                  child: Container(
                                                    color: Colors.grey.shade700,
                                                    height: 22,
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      "0",
                                                      style: TextStyle(
                                                        color: ezColors(
                                                          context,
                                                        ).textPrimary,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            if (healthyCount > 0)
                                              Expanded(
                                                flex: healthyCount,
                                                child: const Align(
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    "😊",
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            if (poorCount > 0)
                                              Expanded(
                                                flex: poorCount,
                                                child: const Align(
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    "☹️",
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            if (healthyCount == 0 &&
                                                poorCount == 0)
                                              Expanded(
                                                flex: 1,
                                                child: const Align(
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    "➖",
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      "วันที่นำเข้า : ${data["import_date"]}",
                                      style: GoogleFonts.kanit(
                                        color: ezColors(context).textPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "วันเกิดไก่ : ${data["birth_date"]}",
                                      style: GoogleFonts.kanit(
                                        color: ezColors(context).textPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          EzEggYearChart(
                            coopLabel: "${data["name"]}",
                            eggData: data["egg_data"] ?? {},
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: _buildMenuButton(
                            icon: Icons.medical_information_outlined,
                            label: "ตรวจสุขภาพ",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Chickenhealth(
                                  initialCoopId: data["id"].toString(),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMenuButton(
                            icon: Icons.cell_tower,
                            label: "อุปกรณ์,เซนเซอร์",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DataSystem(
                                  initialCoopId: data["id"].toString(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMenuButton(
                            icon: Icons.vaccines_outlined,
                            label: "การให้วัคซีน",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MainVaccine(
                                  initialCoopId: data["id"].toString(),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMenuButton(
                            icon: Icons.egg_outlined,
                            label: "เก็บไข่ไก่",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddEgg(
                                  initialCoopId: data["id"].toString(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'รายการประจำวันคอกไก่ ${data["name"]}',
                        style: GoogleFonts.kanit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE5BA93),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (isLoading)
                      Skeletonizer(
                        enabled: true,
                        child: Column(
                          children: List.generate(
                            3,
                            (_) => _buildActivityItem({
                              'type': 'egg',
                              'text': 'เก็บไข่ประจำวัน : 20 ฟอง',
                              'date': DateTime.now(),
                              'pending': false,
                            }),
                          ),
                        ),
                      )
                    else if (dailyActivity.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Text(
                          "ยังไม่มีรายการของคอกนี้",
                          style: GoogleFonts.kanit(
                            fontSize: 15,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    else
                      ...dailyActivity.map(
                        (item) => _buildActivityItem(item),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: ezCardDecoration(context, radius: 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: ezColors(context).textPrimary, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ezColors(context).textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _thaiMonths = [
    'ม.ค.',
    'ก.พ.',
    'มี.ค.',
    'เม.ย.',
    'พ.ค.',
    'มิ.ย.',
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.',
  ];

  // 🌟 การ์ดกิจกรรมของคอกนี้ - รองรับทั้งไข่/ตรวจสุขภาพ/วัคซีน
  // รายการที่ pending=true (ยังไม่ทำ) จะมาร์คสีแดงไว้เตือน ส่วนที่ทำแล้ว/เป็นแค่บันทึกจะเป็นสีปกติ
  // เฉพาะรายการไข่เท่านั้นที่กดแก้ไขได้ (รายการอื่นเป็นข้อมูลสรุป/แจ้งเตือนเท่านั้น)
  Widget _buildActivityItem(Map<String, dynamic> item) {
    final ez = ezColors(context);
    final DateTime date = item['date'] is DateTime
        ? item['date'] as DateTime
        : DateTime.now();
    final String day = date.day.toString().padLeft(2, '0');
    final String month = _thaiMonths[date.month - 1];
    final String thaiYear = (date.year + 543).toString();
    final bool pending = item['pending'] == true;
    final String text = item['text']?.toString() ?? '';
    final bool isEgg = item['type'] == 'egg' && item['raw'] != null;

    final card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: ezCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: pending
            ? Border.all(color: ez.danger.withValues(alpha: 0.5), width: 1.3)
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Text(
                  day,
                  style: GoogleFonts.kanit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: pending ? ez.danger : const Color(0xFFE5BA93),
                  ),
                ),
                Text(
                  '$month $thaiYear',
                  style: GoogleFonts.kanit(
                    fontSize: 10,
                    color: ez.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.kanit(
                color: pending ? ez.danger : ez.textPrimary,
                fontSize: 14,
                fontWeight: pending ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (isEgg)
            Icon(Icons.arrow_forward_ios, color: ez.textSecondary, size: 16),
        ],
      ),
    );

    if (!isEgg) return card;

    final raw = item['raw'] as Map;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditNumbereggchicken(
              initialData: {
                'id': raw['egg_id'] ?? raw['id'],
                'date': raw['date_collect_egg'],
                'count': raw['number_egg'],
                'note': raw['note'],
                'coop_id': raw['coop_id'],
              },
            ),
          ),
        ).then((_) => _fetchDailyActivity());
      },
      child: card,
    );
  }
}
