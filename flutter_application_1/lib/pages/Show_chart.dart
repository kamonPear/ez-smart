import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Main_SenSor/Main_DeviceSummary.dart';
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

  bool isLoading = true;

  int todayTotalEggs = 0;
  int yesterdayTotalEggs = 0;

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

    for (var item in _rawEggData) {
      if (item['date_collect_egg'] == null) continue;

      DateTime date = DateTime.parse(item['date_collect_egg']).toLocal();
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
    });
  }

  List<dynamic> _recordsForCoop(String coopId) {
    return _rawEggData
        .where((item) => item['coop_id']?.toString() == coopId)
        .toList();
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
        MaterialPageRoute(builder: (context) => const MainDeviceSummary()),
      );
    } else {
      setState(() {
        selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    double minContentHeight =
        mediaQuery.size.height - mediaQuery.viewInsets.bottom;

    return Scaffold(
      extendBody: true,
      backgroundColor: ezBackgroundColor(context),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(minHeight: minContentHeight),
            child: Column(
              children: [
                const EzHeader(pageTitle: 'กราฟข้อมูลการเก็บไข่'),
                const SizedBox(height: 20),

                if (isLoading && _rawEggData.isEmpty)
                  Skeletonizer(
                    enabled: true,
                    child: Column(
                      children: [
                        _buildSummaryCard(),
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

  Widget _buildCoopChartCard(String coopId) {
    String coopLabel = _coopNames[coopId] ?? coopId;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: EzEggMultiChart(
        coopLabel: coopLabel,
        records: _recordsForCoop(coopId),
      ),
    );
  }
}
