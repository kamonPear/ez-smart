import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'bottombar.dart';
import '../widgets/ez_header.dart';
import '../widgets/ez_skeleton.dart';
import '../widgets/ez_egg_chart.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../services/backend_config.dart';

class ShowChart extends StatefulWidget {
  const ShowChart({super.key});

  @override
  State<ShowChart> createState() => _ShowChartState();
}

class _ShowChartState extends State<ShowChart> {
  int selectedIndex = 2;

  bool isMonthly = true;
  String selectedYear = DateTime.now().year.toString();

  bool isLoading = true;

  int todayTotalEggs = 0;
  int yesterdayTotalEggs = 0;

  List<String> availableYears = [];
  List<dynamic> _rawEggData = [];

  List<String> availableCoops = [];
  Map<String, String> _coopNames =
      {}; // ✅ แผนที่ coop_id -> ชื่อคอก สำหรับแสดงผล

  @override
  void initState() {
    super.initState();
    _fetchCoops().then((_) {
      _fetchEggData();
    });
  }

  Future<void> _fetchCoops() async {
    try {
      final response = await http.get(Uri.parse('$backendBaseUrl/api/coops'));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        setState(() {
          availableCoops =
              data.map((item) => item['coop_id'].toString()).toSet().toList()
                ..sort(
                  (a, b) =>
                      (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0),
                );

          _coopNames = {
            for (var item in data)
              item['coop_id'].toString():
                  (item['name_coop']?.toString().trim().isNotEmpty == true)
                  ? item['name_coop'].toString()
                  : item['coop_id'].toString(),
          };
        });
      } else {
        debugPrint("Error fetching coops: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Connection error (coops): $e");
    }
  }

  Future<void> _fetchEggData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('$backendBaseUrl/api/eggs'));

      if (response.statusCode == 200) {
        _rawEggData = jsonDecode(response.body);
        _recalculateStats();
      } else {
        debugPrint("Error fetching eggs: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Connection error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _recalculateStats() {
    int tempTodayTotal = 0;
    int tempYesterdayTotal = 0;
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));

    Set<String> years = {};

    for (var item in _rawEggData) {
      if (item['date_collect_egg'] == null) continue;

      DateTime date = DateTime.parse(item['date_collect_egg']).toLocal();
      years.add(date.year.toString());
      double amount = (item['number_egg'] as num?)?.toDouble() ?? 0;

      DateTime itemDate = DateTime(date.year, date.month, date.day);
      if (itemDate == today) {
        tempTodayTotal += amount.toInt();
      } else if (itemDate == yesterday) {
        tempYesterdayTotal += amount.toInt();
      }
    }

    setState(() {
      todayTotalEggs = tempTodayTotal;
      yesterdayTotalEggs = tempYesterdayTotal;

      availableYears = years.toList()..sort();
      if (availableYears.isNotEmpty) {
        selectedYear = availableYears.last;
      } else {
        selectedYear = DateTime.now().year.toString();
        availableYears = [selectedYear];
      }
    });
  }

  double _calculateMaxYForData(List<double> data) {
    double max = 0;
    for (var val in data) {
      if (val > max) max = val;
    }
    return max > 0 ? max * 1.2 : 100;
  }

  Map<String, List<double>> _monthlyDataForCoop(String coopId) {
    Map<String, List<double>> temp = {};
    for (var item in _rawEggData) {
      if (item['coop_id']?.toString() != coopId) continue;
      if (item['date_collect_egg'] == null) continue;

      DateTime date = DateTime.parse(item['date_collect_egg']).toLocal();
      String yearStr = date.year.toString();
      double amount = (item['number_egg'] as num?)?.toDouble() ?? 0;

      temp.putIfAbsent(yearStr, () => List.filled(12, 0.0));
      temp[yearStr]![date.month - 1] += amount;
    }
    return temp;
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
    } else {
      setState(() {
        selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBody: true,
      backgroundColor: ezBackgroundColor(context),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(minHeight: screenHeight),
            child: Column(
              children: [
                const EzHeader(pageTitle: 'กราฟข้อมูล'),
                const SizedBox(height: 20),

                if (isLoading && _rawEggData.isEmpty)
                  Skeletonizer(
                    enabled: true,
                    child: Column(
                      children: [
                        _buildSummaryCard(),
                        _buildToggleSwitch(),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: EzSkeletonCard(height: 220),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      _buildSummaryCard(),
                      _buildToggleSwitch(),
                      ...availableCoops.map(
                        (coopId) => _buildCoopChartCard(coopId),
                      ),
                    ],
                  ),

                const SizedBox(height: 100),
              ],
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

  Widget _buildSummaryCard() {
    String formatNum(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

    bool isUp = todayTotalEggs > yesterdayTotalEggs;
    bool isEqual = todayTotalEggs == yesterdayTotalEggs;

    IconData trendIcon = isEqual
        ? Icons.remove
        : (isUp ? Icons.arrow_upward : Icons.arrow_downward);
    Color trendColor = isEqual
        ? ezColors(context).textSecondary
        : (isUp ? const Color(0xFF4ADE80) : Colors.redAccent);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ezCardColor(context),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const Icon(Icons.egg_outlined, color: Color(0xFFFDE68A), size: 50),
          const SizedBox(height: 10),
          Text(
            'วันนี้ : ${formatNum(todayTotalEggs)} ฟอง',
            style: GoogleFonts.kanit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: ezColors(context).textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(trendIcon, color: trendColor, size: 18),
              const SizedBox(width: 5),
              Text(
                'เมื่อวาน : ${formatNum(yesterdayTotalEggs)} ฟอง',
                style: GoogleFonts.kanit(fontSize: 14, color: trendColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => isMonthly = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isMonthly
                          ? const Color(0xFFFF7B7B)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'เดือน',
                      style: GoogleFonts.kanit(
                        fontSize: 14,
                        color: isMonthly ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => isMonthly = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: !isMonthly
                          ? const Color(0xFFFF7B7B)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ปี',
                      style: GoogleFonts.kanit(
                        fontSize: 14,
                        color: !isMonthly ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoopChartCard(String coopId) {
    Map<String, List<double>> monthlyData = _monthlyDataForCoop(coopId);
    String coopLabel = _coopNames[coopId] ?? coopId;

    if (isMonthly) {
      // 📊 มุมมองรายเดือน: ใช้ widget กราฟกลางที่แชร์กับหน้ารายละเอียดคอก
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: EzEggYearChart(coopLabel: coopLabel, eggData: monthlyData),
      );
    }

    List<double> currentData = availableYears
        .map(
          (y) =>
              (monthlyData[y] ?? List.filled(12, 0.0)).reduce((a, b) => a + b),
        )
        .toList();

    double minVal = currentData.where((v) => v > 0).isEmpty
        ? 0
        : currentData.where((v) => v > 0).reduce((a, b) => a < b ? a : b);
    double chartMaxY = _calculateMaxYForData(currentData);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: ezCardColor(context),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            'บันทึกการเก็บไข่รายปีของคอกที่ $coopLabel',
            textAlign: TextAlign.center,
            style: GoogleFonts.kanit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: ezColors(context).textPrimary,
            ),
          ),
          const SizedBox(height: 15),

          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: chartMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.3),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.kanit(
                            color: ezColors(context).textSecondary,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.right,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        String text = '';
                        if (value >= 0 && value < availableYears.length) {
                          final year = int.tryParse(
                            availableYears[value.toInt()],
                          );
                          text = year != null
                              ? '${year + 543}'
                              : availableYears[value.toInt()];
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            text,
                            style: GoogleFonts.kanit(
                              color: ezColors(context).textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      currentData.length,
                      (index) => FlSpot(index.toDouble(), currentData[index]),
                    ),
                    isCurved: false,
                    color: ezColors(context).textPrimary,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        bool isLowest = spot.y == minVal && spot.y > 0;
                        return FlDotCirclePainter(
                          radius: 4,
                          color: isLowest ? Colors.red : Colors.greenAccent,
                          strokeWidth: 0,
                        );
                      },
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                      return LineTooltipItem(
                        '${spot.y.toInt()} ฟอง',
                        GoogleFonts.kanit(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
