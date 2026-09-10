import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ez_header.dart';
import '../pages/calendar.dart';
import '../utils/thai_date.dart';

const _kThaiMonthsShort = [
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

/// การ์ดกราฟบันทึกการเก็บไข่รายปี (รายเดือน 12 เดือน) ใช้ร่วมกันได้ทุกหน้าที่ต้องโชว์
/// สถิติไข่ของคอกไก่ตลอดปี
class EzEggYearChart extends StatelessWidget {
  final String coopLabel;
  final Map<String, List<double>> eggData;

  const EzEggYearChart({
    super.key,
    required this.coopLabel,
    required this.eggData,
  });

  @override
  Widget build(BuildContext context) {
    final ez = ezColors(context);

    final sortedYears = eggData.keys.toList()..sort();
    final activeYear = sortedYears.isNotEmpty
        ? sortedYears.last
        : DateTime.now().year.toString();
    final thaiYear = (int.tryParse(activeYear) ?? DateTime.now().year) + 543;
    final values = eggData[activeYear] ?? List.filled(12, 0.0);

    final nonZero = values.where((v) => v > 0);
    final minVal = nonZero.isNotEmpty
        ? nonZero.reduce((a, b) => a < b ? a : b)
        : 0.0;
    final minIndex = minVal > 0 ? values.indexOf(minVal) : -1;
    final maxVal = values.isNotEmpty
        ? values.reduce((a, b) => a > b ? a : b)
        : 0.0;
    final chartMaxY = maxVal > 0 ? maxVal * 1.35 : 100.0;
    final total = values.fold<double>(0, (sum, v) => sum + v);

    final spots = [
      for (int i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ez.cardAlt,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ez.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.show_chart_rounded, color: ez.gold, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'บันทึกการเก็บไข่รายปี · $coopLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.kanit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ez.textPrimary,
                      ),
                    ),
                    Text(
                      'รวมทั้งปี ${total.toInt()} ฟอง',
                      style: GoogleFonts.kanit(
                        fontSize: 11,
                        color: ez.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ez.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ปี $thaiYear',
                  style: GoogleFonts.kanit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ez.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: 70.0 * 12,
              height: 170,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: ez.border, strokeWidth: 1),
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
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: ez.textSecondary,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.round();
                          if (index < 0 ||
                              index >= _kThaiMonthsShort.length ||
                              (value - index).abs() > 0.01) {
                            return const Text('');
                          }
                          return Text(
                            _kThaiMonthsShort[index],
                            style: TextStyle(
                              color: ez.textSecondary,
                              fontSize: 9,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 11,
                  minY: 0,
                  maxY: chartMaxY,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) =>
                          touchedSpots.map((spot) {
                            final monthIndex = spot.x.round();
                            final monthLabel =
                                monthIndex >= 0 &&
                                    monthIndex < _kThaiMonthsShort.length
                                ? _kThaiMonthsShort[monthIndex]
                                : '';
                            return LineTooltipItem(
                              '$monthLabel: ${spot.y.toInt()} ฟอง',
                              GoogleFonts.kanit(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.25,
                      color: ez.gold,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            ez.gold.withValues(alpha: 0.28),
                            ez.gold.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) {
                          final isLowest = index == minIndex;
                          return FlDotCirclePainter(
                            radius: 4,
                            color: isLowest ? ez.danger : ez.success,
                            strokeWidth: 2,
                            strokeColor: ez.cardAlt,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.swipe_outlined, size: 13, color: ez.textSecondary),
              const SizedBox(width: 4),
              Text(
                'เลื่อนซ้าย-ขวาเพื่อดูข้อมูลเดือนอื่น',
                style: GoogleFonts.kanit(fontSize: 10, color: ez.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _EggChartMode { day, month, year }

class _EggChartAgg {
  final List<String> labels;
  final List<double> values;
  final String subtitle;
  final double pointWidth;

  _EggChartAgg({
    required this.labels,
    required this.values,
    required this.subtitle,
    required this.pointWidth,
  });
}

/// การ์ดกราฟบันทึกการเก็บไข่ สลับดูได้ 3 มุมมอง แบบ "เจาะลึกลงไป" ทีละชั้น:
/// รายวัน = ดูวันที่เลือก แบ่งเป็นรายชั่วโมง, รายเดือน = ดูเดือนที่เลือก แบ่งเป็นรายวัน,
/// รายปี = ดูปีที่เลือก แบ่งเป็นรายเดือน — เลื่อนไปมาด้วยลูกศร หรือกดไอคอนปฏิทินเพื่อเลือกช่วงได้เลย
/// รับข้อมูลดิบ (raw records จาก /api/eggs ที่กรองตามคอกแล้ว) แล้วคำนวณ aggregate เอง
/// ต่างจาก [EzEggYearChart] ที่รับเฉพาะข้อมูลสรุปรายเดือนสำเร็จรูป
class EzEggMultiChart extends StatefulWidget {
  final String coopLabel;
  final List<dynamic> records;

  const EzEggMultiChart({
    super.key,
    required this.coopLabel,
    required this.records,
  });

  @override
  State<EzEggMultiChart> createState() => _EzEggMultiChartState();
}

class _EzEggMultiChartState extends State<EzEggMultiChart> {
  _EggChartMode _mode = _EggChartMode.month;

  late DateTime _focusedDay;
  late DateTime _focusedMonth; // เก็บแค่ปี/เดือน (day เป็น 1 เสมอ)
  late int _focusedYear;

  @override
  void initState() {
    super.initState();
    _resetFocusToLatest();
  }

  @override
  void didUpdateWidget(covariant EzEggMultiChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ถ้าเปลี่ยนคอก (ข้อมูลชุดใหม่) ให้ขยับโฟกัสไปช่วงล่าสุดของคอกนั้นใหม่
    if (oldWidget.coopLabel != widget.coopLabel) {
      _resetFocusToLatest();
    }
  }

  void _resetFocusToLatest() {
    DateTime? latest;
    for (final r in widget.records) {
      final d = _parseDate(r);
      if (d != null && (latest == null || d.isAfter(latest))) latest = d;
    }
    latest ??= DateTime.now();
    _focusedDay = DateTime(latest.year, latest.month, latest.day);
    _focusedMonth = DateTime(latest.year, latest.month, 1);
    _focusedYear = latest.year;
  }

  DateTime? _parseDate(dynamic record) {
    final raw = record['date_collect_egg']?.toString();
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  double _amountOf(dynamic record) =>
      (record['number_egg'] as num?)?.toDouble() ?? 0.0;

  // รายวัน: ชั่วโมงไหนของ "วันที่เลือก" เก็บไข่ได้เท่าไหร่
  _EggChartAgg _buildHourAgg() {
    final values = List<double>.filled(24, 0.0);
    for (final r in widget.records) {
      final d = _parseDate(r);
      if (d == null ||
          d.year != _focusedDay.year ||
          d.month != _focusedDay.month ||
          d.day != _focusedDay.day) {
        continue;
      }
      values[d.hour] += _amountOf(r);
    }
    final labels = List.generate(24, (h) => '$h:00');
    final total = values.fold<double>(0, (s, v) => s + v);
    return _EggChartAgg(
      labels: labels,
      values: values,
      subtitle: 'รวมวันนี้ ${total.toInt()} ฟอง (${thaiDate(_focusedDay)})',
      pointWidth: 40,
    );
  }

  // รายเดือน: วันที่ไหนของ "เดือนที่เลือก" เก็บไข่ได้เท่าไหร่
  _EggChartAgg _buildDayOfMonthAgg() {
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final values = List<double>.filled(daysInMonth, 0.0);
    for (final r in widget.records) {
      final d = _parseDate(r);
      if (d == null ||
          d.year != _focusedMonth.year ||
          d.month != _focusedMonth.month) {
        continue;
      }
      values[d.day - 1] += _amountOf(r);
    }
    final labels = List.generate(daysInMonth, (i) => '${i + 1}');
    final total = values.fold<double>(0, (s, v) => s + v);
    return _EggChartAgg(
      labels: labels,
      values: values,
      subtitle:
          'รวมเดือนนี้ ${total.toInt()} ฟอง (${thaiMonthYear(_focusedMonth)})',
      pointWidth: 32,
    );
  }

  // รายปี: เดือนไหนของ "ปีที่เลือก" เก็บไข่ได้เท่าไหร่
  _EggChartAgg _buildMonthOfYearAgg() {
    final values = List<double>.filled(12, 0.0);
    for (final r in widget.records) {
      final d = _parseDate(r);
      if (d == null || d.year != _focusedYear) continue;
      values[d.month - 1] += _amountOf(r);
    }
    final total = values.fold<double>(0, (s, v) => s + v);
    final thaiYear = _focusedYear + 543;
    return _EggChartAgg(
      labels: _kThaiMonthsShort,
      values: values,
      subtitle: 'รวมทั้งปี ${total.toInt()} ฟอง (ปี $thaiYear)',
      pointWidth: 70,
    );
  }

  List<DateTime> get _datesWithData {
    final dates = <DateTime>{};
    for (final r in widget.records) {
      final d = _parseDate(r);
      if (d != null) dates.add(DateTime(d.year, d.month, d.day));
    }
    return dates.toList();
  }

  (int min, int max) get _yearRangeWithData {
    int? min, max;
    for (final r in widget.records) {
      final d = _parseDate(r);
      if (d == null) continue;
      if (min == null || d.year < min) min = d.year;
      if (max == null || d.year > max) max = d.year;
    }
    final nowYear = DateTime.now().year;
    min ??= nowYear;
    max ??= nowYear;
    if (_focusedYear < min) min = _focusedYear;
    if (_focusedYear > max) max = _focusedYear;
    return (min, max);
  }

  void _shiftPeriod(int delta) {
    setState(() {
      switch (_mode) {
        case _EggChartMode.day:
          _focusedDay = _focusedDay.add(Duration(days: delta));
        case _EggChartMode.month:
          _focusedMonth = DateTime(
            _focusedMonth.year,
            _focusedMonth.month + delta,
            1,
          );
        case _EggChartMode.year:
          _focusedYear += delta;
      }
    });
  }

  String _periodLabel() {
    switch (_mode) {
      case _EggChartMode.day:
        return thaiDate(_focusedDay);
      case _EggChartMode.month:
        return thaiMonthYear(_focusedMonth);
      case _EggChartMode.year:
        return 'ปี ${_focusedYear + 543}';
    }
  }

  Future<void> _openPeriodPicker() async {
    switch (_mode) {
      case _EggChartMode.day:
        await showDialog(
          context: context,
          builder: (dialogContext) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomCalendar(
              initialDate: _focusedDay,
              markedDates: _datesWithData,
              onDateSelected: (d) {
                setState(() => _focusedDay = d);
                Navigator.pop(dialogContext);
              },
            ),
          ),
        );
      case _EggChartMode.month:
        await _openMonthYearPicker();
      case _EggChartMode.year:
        await _openYearListPicker();
    }
  }

  Future<void> _openMonthYearPicker() async {
    int pickerYear = _focusedMonth.year;
    await showDialog(
      context: context,
      builder: (dialogContext) {
        final ez = ezColors(dialogContext);
        return StatefulBuilder(
          builder: (dialogContext, setPickerState) {
            return Dialog(
              backgroundColor: ezCardColor(dialogContext),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.chevron_left, color: ez.textPrimary),
                          onPressed: () =>
                              setPickerState(() => pickerYear -= 1),
                        ),
                        Text(
                          'ปี ${pickerYear + 543}',
                          style: GoogleFonts.kanit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ez.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.chevron_right,
                            color: ez.textPrimary,
                          ),
                          onPressed: () =>
                              setPickerState(() => pickerYear += 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisExtent: 44,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final isSelected =
                            pickerYear == _focusedMonth.year &&
                            index == _focusedMonth.month - 1;
                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            setState(
                              () => _focusedMonth = DateTime(
                                pickerYear,
                                index + 1,
                                1,
                              ),
                            );
                            Navigator.pop(dialogContext);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? ez.gold : ez.inputFill,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: ez.border),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _kThaiMonthsShort[index],
                              style: GoogleFonts.kanit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : ez.textPrimary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openYearListPicker() async {
    final (minYear, maxYear) = _yearRangeWithData;
    final years = [for (int y = minYear - 1; y <= maxYear + 1; y++) y];
    await showDialog(
      context: context,
      builder: (dialogContext) {
        final ez = ezColors(dialogContext);
        return Dialog(
          backgroundColor: ezCardColor(dialogContext),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'เลือกปี',
                    style: GoogleFonts.kanit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ez.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView(
                    shrinkWrap: true,
                    children: years.map((y) {
                      final isSelected = y == _focusedYear;
                      return ListTile(
                        title: Text(
                          '${y + 543}',
                          style: GoogleFonts.kanit(
                            color: isSelected ? ez.gold : ez.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check, color: ez.gold)
                            : null,
                        onTap: () {
                          setState(() => _focusedYear = y);
                          Navigator.pop(dialogContext);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _segButton(String label, _EggChartMode mode, ez) {
    final active = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? ez.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.kanit(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : ez.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ez = ezColors(context);
    final agg = switch (_mode) {
      _EggChartMode.day => _buildHourAgg(),
      _EggChartMode.month => _buildDayOfMonthAgg(),
      _EggChartMode.year => _buildMonthOfYearAgg(),
    };

    final nonZero = agg.values.where((v) => v > 0);
    final minVal = nonZero.isNotEmpty
        ? nonZero.reduce((a, b) => a < b ? a : b)
        : 0.0;
    final minIndex = minVal > 0 ? agg.values.indexOf(minVal) : -1;
    final maxVal = agg.values.isNotEmpty
        ? agg.values.reduce((a, b) => a > b ? a : b)
        : 0.0;
    final chartMaxY = maxVal > 0 ? maxVal * 1.35 : 100.0;
    final spots = [
      for (int i = 0; i < agg.values.length; i++)
        FlSpot(i.toDouble(), agg.values[i]),
    ];
    final labelInterval = agg.values.length > 15
        ? 4.0
        : (agg.values.length > 8 ? 2.0 : 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ez.cardAlt,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ez.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.show_chart_rounded, color: ez.gold, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'บันทึกการเก็บไข่ · ${widget.coopLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.kanit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ez.textPrimary,
                      ),
                    ),
                    Text(
                      agg.subtitle,
                      style: GoogleFonts.kanit(
                        fontSize: 11,
                        color: ez.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: ez.inputFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ez.border),
            ),
            child: Row(
              children: [
                _segButton('รายวัน', _EggChartMode.day, ez),
                _segButton('รายเดือน', _EggChartMode.month, ez),
                _segButton('รายปี', _EggChartMode.year, ez),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _shiftPeriod(-1),
                icon: Icon(Icons.chevron_left, color: ez.textPrimary),
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: InkWell(
                  onTap: _openPeriodPicker,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 14,
                          color: ez.gold,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _periodLabel(),
                          style: GoogleFonts.kanit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: ez.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _shiftPeriod(1),
                icon: Icon(Icons.chevron_right, color: ez.textPrimary),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: agg.pointWidth * agg.values.length,
              height: 170,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: ez.border, strokeWidth: 1),
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
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: ez.textSecondary,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: labelInterval,
                        getTitlesWidget: (value, meta) {
                          final index = value.round();
                          if (index < 0 ||
                              index >= agg.labels.length ||
                              (value - index).abs() > 0.01) {
                            return const Text('');
                          }
                          return Text(
                            agg.labels[index],
                            style: TextStyle(
                              color: ez.textSecondary,
                              fontSize: 9,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (agg.values.length - 1).toDouble().clamp(
                    0.0,
                    double.infinity,
                  ),
                  minY: 0,
                  maxY: chartMaxY,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) =>
                          touchedSpots.map((spot) {
                            final idx = spot.x.round();
                            final label = idx >= 0 && idx < agg.labels.length
                                ? agg.labels[idx]
                                : '';
                            return LineTooltipItem(
                              '$label: ${spot.y.toInt()} ฟอง',
                              GoogleFonts.kanit(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: _mode != _EggChartMode.day,
                      curveSmoothness: 0.25,
                      color: ez.gold,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            ez.gold.withValues(alpha: 0.28),
                            ez.gold.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) {
                          final isLowest = index == minIndex;
                          return FlDotCirclePainter(
                            radius: 4,
                            color: isLowest ? ez.danger : ez.success,
                            strokeWidth: 2,
                            strokeColor: ez.cardAlt,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.swipe_outlined, size: 13, color: ez.textSecondary),
              const SizedBox(width: 4),
              Text(
                'เลื่อนซ้าย-ขวาเพื่อดูข้อมูลช่วงอื่น',
                style: GoogleFonts.kanit(fontSize: 10, color: ez.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
