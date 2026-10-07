import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Main_SenSor/Main_DeviceSummary.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart';
import 'bottombar.dart';
import '../widgets/ez_header.dart';
import '../widgets/ez_skeleton.dart';
import '../widgets/ez_egg_chart.dart';
import '../widgets/ez_form_field.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../services/backend_config.dart';
import '../utils/thai_date.dart';

const String _kAllCoops = '__all__';

enum _ChartMode { day, month, year }

/// แท่งกราฟ 1 แท่ง (1 วัน/เดือน/ปี) ของยอดไข่รวมทั้งฟาร์ม (ทุกคอกบวกกัน)
class _EggChartBar {
  final String key;
  final String label;
  final int value;
  final bool isCurrent;
  final DateTime bucketStart;

  const _EggChartBar({
    required this.key,
    required this.label,
    required this.value,
    required this.isCurrent,
    required this.bucketStart,
  });
}

/// ยอดไข่ของคอกใดคอกหนึ่งในช่วงของแท่งที่เลือก (ใช้แสดงลิสต์แยกคอกตอนกดแท่ง)
class _CoopEggTotal {
  final String coopId;
  final String coopName;
  final int total;

  const _CoopEggTotal({
    required this.coopId,
    required this.coopName,
    required this.total,
  });
}

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

  // เลือกดูคอกใดคอกหนึ่ง แทนการเลื่อนดูทุกคอก (มีประโยชน์มากเวลามีคอกเยอะ)
  String _selectedCoopId = _kAllCoops;

  // กราฟรวมทั้งฟาร์ม (ตอน _selectedCoopId == _kAllCoops) - วัน/เดือน/ปี + กดแท่ง
  // ดูยอดแยกตามคอกได้
  _ChartMode _chartMode = _ChartMode.day;
  String? _selectedBarKey;

  @override
  void initState() {
    super.initState();
    _fetchCoops().then((_) {
      _fetchEggData();
    });
  }

  Future<void> _fetchCoops() async {
    try {
      final response = await ApiClient.get(Uri.parse('$backendBaseUrl/api/coops'));

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

          if (_selectedCoopId != _kAllCoops &&
              !availableCoops.contains(_selectedCoopId)) {
            _selectedCoopId = _kAllCoops;
          }
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
      final response = await ApiClient.get(Uri.parse('$backendBaseUrl/api/eggs'));

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

  List<String> get _coopsToShow =>
      _selectedCoopId == _kAllCoops ? availableCoops : [_selectedCoopId];

  // ---------- กราฟรวมทั้งฟาร์ม (ทุกคอกบวกกัน) ----------

  DateTime? _dateOnlyOf(dynamic item) {
    return thaiDateOnlyFromIso(item['date_collect_egg']?.toString());
  }

  List<dynamic> _recordsForBucket(DateTime bucketStart, _ChartMode mode) {
    return _rawEggData.where((item) {
      final d = _dateOnlyOf(item);
      if (d == null) return false;
      switch (mode) {
        case _ChartMode.day:
          return d.year == bucketStart.year &&
              d.month == bucketStart.month &&
              d.day == bucketStart.day;
        case _ChartMode.month:
          return d.year == bucketStart.year && d.month == bucketStart.month;
        case _ChartMode.year:
          return d.year == bucketStart.year;
      }
    }).toList();
  }

  int _totalInBucket(DateTime bucketStart, _ChartMode mode) {
    return _recordsForBucket(bucketStart, mode).fold<int>(
      0,
      (sum, item) => sum + ((item['number_egg'] as num?)?.toInt() ?? 0),
    );
  }

  List<_EggChartBar> get _dailyBars {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return List.generate(14, (i) {
      final d = todayOnly.subtract(Duration(days: 13 - i));
      return _EggChartBar(
        key: '${d.year}-${d.month}-${d.day}',
        label: '${d.day}',
        value: _totalInBucket(d, _ChartMode.day),
        isCurrent: i == 13,
        bucketStart: d,
      );
    });
  }

  List<_EggChartBar> get _monthlyBars {
    final now = DateTime.now();
    return List.generate(12, (i) {
      final monthsAgo = 11 - i;
      final d = DateTime(now.year, now.month - monthsAgo, 1);
      return _EggChartBar(
        key: '${d.year}-${d.month}',
        label: kThaiMonthsShort[d.month - 1],
        value: _totalInBucket(d, _ChartMode.month),
        isCurrent: i == 11,
        bucketStart: d,
      );
    });
  }

  List<_EggChartBar> get _yearlyBars {
    final now = DateTime.now();
    return List.generate(5, (i) {
      final y = now.year - (4 - i);
      final d = DateTime(y, 1, 1);
      return _EggChartBar(
        key: '$y',
        label: '${y + 543}',
        value: _totalInBucket(d, _ChartMode.year),
        isCurrent: i == 4,
        bucketStart: d,
      );
    });
  }

  List<_EggChartBar> get _farmChartBars {
    switch (_chartMode) {
      case _ChartMode.day:
        return _dailyBars;
      case _ChartMode.month:
        return _monthlyBars;
      case _ChartMode.year:
        return _yearlyBars;
    }
  }

  int get _farmChartMax {
    final values = _farmChartBars.map((b) => b.value);
    final max = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
    return max < 1 ? 1 : max;
  }

  double _farmBarHeightPercent(_EggChartBar bar) {
    if (bar.value <= 0) return 0;
    final pct = (bar.value / _farmChartMax) * 100;
    return pct < 6 ? 6 : pct;
  }

  _EggChartBar? get _selectedFarmBar {
    if (_selectedBarKey == null) return null;
    for (final b in _farmChartBars) {
      if (b.key == _selectedBarKey) return b;
    }
    return null;
  }

  /// ยอดไข่แยกตามคอกของแท่งที่เลือก เรียงมากไปน้อย - ใช้ตอบ "คอกไหนได้เท่าไร"
  /// ของช่วงเวลานั้น (วัน/เดือน/ปี แล้วแต่โหมดที่เลือกอยู่)
  List<_CoopEggTotal> _coopBreakdownForBar(_EggChartBar bar) {
    final records = _recordsForBucket(bar.bucketStart, _chartMode);
    final totals = <String, int>{};
    for (final r in records) {
      final coopId = r['coop_id']?.toString() ?? '';
      if (coopId.isEmpty) continue;
      final amount = (r['number_egg'] as num?)?.toInt() ?? 0;
      totals[coopId] = (totals[coopId] ?? 0) + amount;
    }
    final list = totals.entries
        .map(
          (e) => _CoopEggTotal(
            coopId: e.key,
            coopName: _coopNames[e.key] ?? e.key,
            total: e.value,
          ),
        )
        .toList();
    list.sort((a, b) => b.total.compareTo(a.total));
    return list;
  }

  String _farmBarHeading(_EggChartBar bar) {
    switch (_chartMode) {
      case _ChartMode.day:
        return thaiDate(bar.bucketStart);
      case _ChartMode.month:
        return thaiMonthYear(bar.bucketStart);
      case _ChartMode.year:
        return 'ปี ${bar.bucketStart.year + 543}';
    }
  }

  void _setChartMode(_ChartMode mode) {
    setState(() {
      _chartMode = mode;
      _selectedBarKey = null;
    });
  }

  void _selectFarmBar(_EggChartBar bar) {
    setState(() {
      _selectedBarKey = _selectedBarKey == bar.key ? null : bar.key;
    });
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
                const EzHeader(pageTitle: 'กราฟเก็บไข่'),
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
                      if (availableCoops.length > 1) _buildCoopSelector(),
                      if (_selectedCoopId == _kAllCoops)
                        _buildCombinedFarmChart()
                      else
                        ..._coopsToShow.map(
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

  Widget _buildCoopSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: EzFormDropdown<String>(
        label: 'เลือกคอก',
        value: _selectedCoopId,
        hint: 'ทั้งหมด',
        items: [
          DropdownMenuItem(
            value: _kAllCoops,
            child: Text(
              'ทั้งหมด (${availableCoops.length} คอก)',
              style: GoogleFonts.kanit(fontSize: 14),
            ),
          ),
          ...availableCoops.map(
            (coopId) => DropdownMenuItem(
              value: coopId,
              child: Text(
                _coopNames[coopId] ?? coopId,
                style: GoogleFonts.kanit(fontSize: 14),
              ),
            ),
          ),
        ],
        onChanged: (value) {
          if (value == null) return;
          setState(() => _selectedCoopId = value);
        },
      ),
    );
  }

  /// กราฟรวมทั้งฟาร์ม (ทุกคอกบวกกันเป็นแท่งเดียว) พร้อมแท็บวัน/เดือน/ปี - กดแท่ง
  /// ไหนก็ได้เพื่อดูยอดแยกเป็นรายคอกของช่วงเวลานั้นด้านล่าง
  Widget _buildCombinedFarmChart() {
    final ez = ezColors(context);
    final bars = _farmChartBars;
    final selected = _selectedFarmBar;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ezCardColor(context),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ไข่รวมทั้งฟาร์ม',
            style: GoogleFonts.kanit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: ez.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildModeTab('รายวัน', _ChartMode.day),
              const SizedBox(width: 8),
              _buildModeTab('รายเดือน', _ChartMode.month),
              const SizedBox(width: 8),
              _buildModeTab('รายปี', _ChartMode.year),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: bars.map((bar) {
                  final isSelected = _selectedBarKey == bar.key;
                  return GestureDetector(
                    onTap: () => _selectFarmBar(bar),
                    child: Container(
                      width: 34,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (bar.value > 0)
                            Text(
                              '${bar.value}',
                              style: GoogleFonts.kanit(
                                fontSize: 9,
                                color: ez.textSecondary,
                              ),
                            ),
                          const SizedBox(height: 3),
                          Container(
                            height: 90 * (_farmBarHeightPercent(bar) / 100),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? ez.gold
                                  : (bar.isCurrent
                                        ? ez.accentGreen
                                        : ez.accentGreen.withValues(
                                            alpha: 0.4,
                                          )),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            bar.label,
                            style: GoogleFonts.kanit(
                              fontSize: 10,
                              fontWeight: bar.isCurrent || isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? ez.gold
                                  : ez.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          if (selected != null) ...[
            const Divider(height: 28),
            Text(
              '${_farmBarHeading(selected)} · รวม ${selected.value} ฟอง',
              style: GoogleFonts.kanit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: ez.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ..._coopBreakdownForBar(selected).map(
              (c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      c.coopName,
                      style: GoogleFonts.kanit(
                        fontSize: 13,
                        color: ez.textPrimary,
                      ),
                    ),
                    Text(
                      '${c.total} ฟอง',
                      style: GoogleFonts.kanit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ez.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_coopBreakdownForBar(selected).isEmpty)
              Text(
                'ไม่มีข้อมูลไข่ในช่วงนี้',
                style: GoogleFonts.kanit(
                  fontSize: 13,
                  color: ez.textSecondary,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeTab(String label, _ChartMode mode) {
    final ez = ezColors(context);
    final active = _chartMode == mode;
    return GestureDetector(
      onTap: () => _setChartMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? ez.accentGreen : ez.inputFill,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.kanit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : ez.textSecondary,
          ),
        ),
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
