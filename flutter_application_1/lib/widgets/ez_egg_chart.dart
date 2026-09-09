import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ez_header.dart';

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
