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
  List<dynamic> dailyEggRecords = [];

  @override
  void initState() {
    super.initState();
    _fetchDailyEggs();
  }

  Future<void> _fetchDailyEggs() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('$backendBaseUrl/api/eggs'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final coopId = widget.coop["id"].toString();
        final filtered = data
            .where((e) => e['coop_id']?.toString() == coopId)
            .toList();
        filtered.sort((a, b) {
          DateTime da =
              DateTime.tryParse(a['date_collect_egg']?.toString() ?? '') ??
              DateTime(1970);
          DateTime db =
              DateTime.tryParse(b['date_collect_egg']?.toString() ?? '') ??
              DateTime(1970);
          return db.compareTo(da);
        });
        setState(() => dailyEggRecords = filtered);
      }
    } catch (e) {
      debugPrint("❌ Connection/Parsing error: $e");
    } finally {
      setState(() => isLoading = false);
    }
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
                            (_) => _buildDailyEggItem({
                              'number_egg': 20,
                              'date_collect_egg': DateTime.now()
                                  .toIso8601String(),
                            }),
                          ),
                        ),
                      )
                    else if (dailyEggRecords.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Text(
                          "ยังไม่มีบันทึกการเก็บไข่ประจำวัน",
                          style: GoogleFonts.kanit(
                            fontSize: 15,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    else
                      ...dailyEggRecords.map(
                        (item) => _buildDailyEggItem(item),
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

  Widget _buildDailyEggItem(dynamic item) {
    final amount = item['number_egg'] ?? 0;
    final dateStr = item['date_collect_egg']?.toString() ?? '';
    DateTime? date = DateTime.tryParse(dateStr);
    const months = [
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
    String day = date != null ? date.day.toString().padLeft(2, '0') : '--';
    String month = date != null ? months[date.month - 1] : '';
    String thaiYear = date != null ? (date.year + 543).toString() : '';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditNumbereggchicken(
              initialData: {
                'id': item['egg_id'] ?? item['id'],
                'date': item['date_collect_egg'],
                'count': item['number_egg'],
                'note': item['note'],
                'coop_id': item['coop_id'],
              },
            ),
          ),
        ).then((_) => _fetchDailyEggs());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: ezCardDecoration(context, radius: 16),
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
                      color: const Color(0xFFE5BA93),
                    ),
                  ),
                  Text(
                    '$month $thaiYear',
                    style: GoogleFonts.kanit(
                      fontSize: 10,
                      color: ezColors(context).textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'บันทึกเก็บไข่ประจำวัน : $amount ฟอง',
                style: GoogleFonts.kanit(
                  color: ezColors(context).textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: ezColors(context).textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
