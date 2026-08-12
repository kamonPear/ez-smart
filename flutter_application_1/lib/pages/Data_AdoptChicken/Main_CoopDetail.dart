import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:percent_indicator/percent_indicator.dart';
import '../../services/backend_config.dart';
import '../Chicken_health_information/Show_Chicken_health.dart'
    hide backendBaseUrl;
import '../Main_SenSor/Data_System.dart';
import '../Vaccine/Main_Vaccine.dart';
import '../number_for_Egg/Add_egg.dart';
import '../number_for_Egg/Edit_NumberEggchicken_3.dart';

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
      backgroundColor: const Color(0xFF0F1621),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1621),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'คอกไก่ ${data["name"]}',
          style: GoogleFonts.kanit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
              decoration: BoxDecoration(
                color: const Color(0xFF19232F),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildGauge(
                    title: "อุณหภูมิ",
                    value: data["temp"].toString(),
                    unit: "°",
                    subTitle: "อุณหภูมิที่ตั้งไว้คงที่",
                    color: Colors.cyan,
                    percent: tempPercent,
                  ),
                  _buildGauge(
                    title: "ปริมาณแอมโมเนีย",
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
              decoration: BoxDecoration(
                color: const Color(0xFF19232F),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'คอกไก่ ${data["name"]}',
                              style: GoogleFonts.kanit(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text('🐔', style: TextStyle(fontSize: 60)),
                            const SizedBox(height: 5),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
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
                                    color: Colors.white,
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
                            Text(
                              "สุขภาพไก่",
                              style: GoogleFonts.kanit(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: Row(
                                    children: [
                                      if (healthyCount > 0)
                                        Expanded(
                                          flex: healthyCount,
                                          child: Container(
                                            color: const Color(0xFF4ADE80),
                                            height: 18,
                                            alignment: Alignment.center,
                                            child: Text(
                                              "$healthyCount",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (poorCount > 0)
                                        Expanded(
                                          flex: poorCount,
                                          child: Container(
                                            color: const Color(0xFFEF4444),
                                            height: 18,
                                            alignment: Alignment.center,
                                            child: Text(
                                              "$poorCount",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (healthyCount == 0 && poorCount == 0)
                                        Expanded(
                                          flex: 1,
                                          child: Container(
                                            color: Colors.grey.shade700,
                                            height: 18,
                                            alignment: Alignment.center,
                                            child: const Text(
                                              "0",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
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
                                            style: TextStyle(fontSize: 14),
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
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ),
                                    if (healthyCount == 0 && poorCount == 0)
                                      Expanded(
                                        flex: 1,
                                        child: const Align(
                                          alignment: Alignment.center,
                                          child: Text(
                                            "➖",
                                            style: TextStyle(fontSize: 14),
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
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "วันเกิดไก่ : ${data["birth_date"]}",
                              style: GoogleFonts.kanit(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _EggCollectionLineChart(
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
                        builder: (_) =>
                            Chickenhealth(initialCoopId: data["id"].toString()),
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
                        builder: (_) =>
                            DataSystem(initialCoopId: data["id"].toString()),
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
                        builder: (_) =>
                            MainVaccine(initialCoopId: data["id"].toString()),
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
                        builder: (_) =>
                            AddEgg(initialCoopId: data["id"].toString()),
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
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: CircularProgressIndicator(),
              )
            else if (dailyEggRecords.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Text(
                  "ยังไม่มีบันทึกการเก็บไข่ประจำวัน",
                  style: GoogleFonts.kanit(fontSize: 15, color: Colors.grey),
                ),
              )
            else
              ...dailyEggRecords.map((item) => _buildDailyEggItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildGauge({
    required String title,
    required String value,
    required String unit,
    required String subTitle,
    required Color color,
    required double percent,
  }) {
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 55.0,
          lineWidth: 12.0,
          animation: true,
          percent: percent,
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (unit == "PPM")
                Text(
                  "PPM",
                  style: GoogleFonts.kanit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.kanit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (unit == "°")
                    Text(
                      "°",
                      style: GoogleFonts.kanit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
              Text(
                title,
                style: GoogleFonts.kanit(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
          circularStrokeCap: CircularStrokeCap.round,
          backgroundColor: Colors.grey.shade800,
          progressColor: color,
        ),
        const SizedBox(height: 10),
        Text(
          subTitle,
          style: GoogleFonts.kanit(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
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
        decoration: BoxDecoration(
          color: const Color(0xFF19232F),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
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
        decoration: BoxDecoration(
          color: const Color(0xFF19232F),
          borderRadius: BorderRadius.circular(16),
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
                      color: const Color(0xFFE5BA93),
                    ),
                  ),
                  Text(
                    '$month $thaiYear',
                    style: GoogleFonts.kanit(
                      fontSize: 10,
                      color: Colors.white70,
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
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _EggCollectionLineChart extends StatelessWidget {
  final String coopLabel;
  final Map<String, List<double>> eggData;

  const _EggCollectionLineChart({
    required this.coopLabel,
    required this.eggData,
  });

  @override
  Widget build(BuildContext context) {
    List<String> sortedYears = eggData.keys.toList()..sort();
    String activeYear = sortedYears.isNotEmpty ? sortedYears.last : '2026';
    int thaiYear = int.parse(activeYear) + 543;

    List<double> values = eggData[activeYear] ?? List.filled(12, 0.0);

    Iterable<double> nonZeroValues = values.where((v) => v > 0);
    double minVal = nonZeroValues.isNotEmpty
        ? nonZeroValues.reduce((a, b) => a < b ? a : b)
        : 0;
    int minIndex = minVal > 0 ? values.indexOf(minVal) : -1;

    double maxVal = values.isNotEmpty
        ? values.reduce((a, b) => a > b ? a : b)
        : 100;
    double chartMaxY = maxVal > 0 ? maxVal * 1.2 : 100;

    List<FlSpot> spots = [];
    for (int i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i]));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'บันทึกการเก็บไข่รายปีของไก่คอก $coopLabel ปี $thaiYear',
          style: GoogleFonts.kanit(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: Colors.white12, strokeWidth: 1);
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 9,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
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
                      int index = value.toInt();
                      if (index >= 0 && index < months.length) {
                        return Text(
                          months[index],
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 9,
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 11,
              minY: 0,
              maxY: chartMaxY,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  color: Colors.white,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      bool isLowestPoint = (index == minIndex);
                      return FlDotCirclePainter(
                        radius: 4,
                        color: isLowestPoint
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF22C55E),
                        strokeWidth: 0,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
