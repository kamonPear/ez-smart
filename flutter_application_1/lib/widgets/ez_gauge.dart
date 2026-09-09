import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'ez_header.dart';

/// การ์ดวงกลมแสดงค่าตัวเลขพร้อมหลอดเปอร์เซ็นต์ (เช่น อุณหภูมิ, ปริมาณแอมโมเนีย)
/// ใช้ร่วมกันได้ทุกหน้าที่ต้องโชว์ค่าเซนเซอร์แบบวงกลม
class EzGaugeCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String subTitle;
  final Color color;
  final double percent;

  const EzGaugeCard({
    super.key,
    required this.icon,
    required this.value,
    required this.unit,
    required this.subTitle,
    required this.color,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final ez = ezColors(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularPercentIndicator(
          radius: 55.0,
          lineWidth: 12.0,
          animation: true,
          percent: percent,
          center: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                value,
                style: GoogleFonts.kanit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: ez.textPrimary,
                ),
              ),
              if (unit == "°")
                Text(
                  "°",
                  style: GoogleFonts.kanit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: ez.textPrimary,
                  ),
                )
              else if (unit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4),
                  child: Text(
                    unit,
                    style: GoogleFonts.kanit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: ez.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
          circularStrokeCap: CircularStrokeCap.round,
          backgroundColor: ez.textSecondary.withValues(alpha: 0.2),
          progressColor: color,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: ez.textSecondary),
            const SizedBox(width: 4),
            Text(
              subTitle,
              textAlign: TextAlign.center,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: GoogleFonts.kanit(
                fontSize: 12,
                color: ez.textPrimary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
