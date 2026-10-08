import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ez_header.dart';
import '../theme/app_theme.dart';

/// เปิดปฏิทินเลือกวันที่แบบเดียวกันทั้งแอป — ปั้นเองให้หน้าตาตรงกับปฏิทินฝั่งเว็บ
/// (DatePickerCalendar, src/app/shared/date-picker-calendar) แทนที่จะใช้ปฏิทิน
/// Material ดีฟอลต์ของ Flutter ซึ่งเป็นปุ่ม/เลย์เอาต์คนละแบบ (มีปุ่มยืนยัน/ยกเลิก,
/// ตัวเลือกปีแบบลิสต์) ทำให้ผู้ใช้ที่สลับไปมาระหว่างเว็บ/มือถือรู้สึกว่าเป็นระบบ
/// เดียวกัน - ใช้แทน showDatePicker ตรงๆ ทุกจุดในแอป
///
/// ต่างจากปฏิทิน Material ตรงที่แตะวันที่แล้วเลือกและปิดทันที ไม่มีปุ่ม "ตกลง"
/// แยกต่างหาก (พฤติกรรมเดียวกับฝั่งเว็บ)
Future<DateTime?> showEzDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String? helpText,
}) {
  return showDialog<DateTime>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (context) => _EzCalendarDialog(
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2101),
      title: helpText ?? 'เลือกวันที่',
    ),
  );
}

// ป้ายกำกับวันในสัปดาห์ตัดคำแบบเดียวกับฝั่งเว็บเป๊ะๆ (MON/TUES/WEDNES/...) ไม่ใช่
// อังกฤษเต็มคำหรือไทยย่อ เพื่อให้เหมือนกันทั้งสองแพลตฟอร์มจริงๆ ไม่ใช่แค่สีเดียวกัน
const List<String> _kWeekdayLabels = [
  'MON',
  'TUES',
  'WEDNES',
  'THURS',
  'FRI',
  'SATUR',
  'SUN',
];

class _EzCalendarDialog extends StatefulWidget {
  const _EzCalendarDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.title,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;

  @override
  State<_EzCalendarDialog> createState() => _EzCalendarDialogState();
}

class _EzCalendarDialogState extends State<_EzCalendarDialog> {
  late DateTime _month; // วันที่ 1 ของเดือนที่กำลังดูอยู่

  @override
  void initState() {
    super.initState();
    _month = DateTime(widget.initialDate.year, widget.initialDate.month, 1);
  }

  void _prevMonth() => setState(() => _month = DateTime(_month.year, _month.month - 1, 1));
  void _nextMonth() => setState(() => _month = DateTime(_month.year, _month.month + 1, 1));

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _inRange(DateTime day) =>
      !day.isBefore(DateTime(widget.firstDate.year, widget.firstDate.month, widget.firstDate.day)) &&
      !day.isAfter(DateTime(widget.lastDate.year, widget.lastDate.month, widget.lastDate.day));

  // แบ่งเป็นสัปดาห์ๆ ละ 7 ช่อง จันทร์เป็นคอลัมน์แรก (เหมือนฝั่งเว็บ) ช่องว่างก่อน/
  // หลังเดือนเป็น null
  List<List<DateTime?>> _buildWeeks() {
    final firstDay = DateTime(_month.year, _month.month, 1);
    final startOffset = (firstDay.weekday - 1) % 7; // Monday=1 -> 0
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;

    final cells = <DateTime?>[
      ...List.filled(startOffset, null),
      ...List.generate(daysInMonth, (i) => DateTime(_month.year, _month.month, i + 1)),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return [for (var i = 0; i < cells.length; i += 7) cells.sublist(i, i + 7)];
  }

  @override
  Widget build(BuildContext context) {
    final ez = ezColors(context);
    final today = DateTime.now();
    final monthLabel =
        '${_kMonthNames[_month.month - 1]} ${_month.year}'.toUpperCase();
    final successStart = Color.lerp(ez.accentGreen, Colors.white, 0.35)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          decoration: BoxDecoration(
            color: ez.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: ez.accentGreen, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 45,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // แถบไล่สีบางๆ ด้านบนสุด เหมือนฝั่งเว็บ
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [successStart, ez.accentGreen],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 22, 26, 26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // หัวข้อ: ไอคอนปฏิทินในวงกลม + ชื่อหัวข้อ + ปุ่มปิด
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: ez.accentGreen.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            size: 20,
                            color: ez.accentGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: GoogleFonts.kanit(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: ez.textPrimary,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: ez.textSecondary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, size: 15, color: ez.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // แถบเปลี่ยนเดือน
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _NavButton(icon: Icons.chevron_left, onTap: _prevMonth, ez: ez),
                        Text(
                          monthLabel,
                          style: GoogleFonts.kanit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: ez.textPrimary,
                          ),
                        ),
                        _NavButton(icon: Icons.chevron_right, onTap: _nextMonth, ez: ez),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // หัวแถวชื่อวัน
                    Row(
                      children: _kWeekdayLabels
                          .map(
                            (d) => Expanded(
                              child: Center(
                                child: Text(
                                  d,
                                  style: GoogleFonts.kanit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                    color: ez.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 4),

                    // ตารางวันที่
                    ..._buildWeeks().map(
                      (week) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: week.map((day) {
                            if (day == null) {
                              return const Expanded(child: SizedBox(height: 40));
                            }
                            final isSelected = _isSameDay(day, widget.initialDate);
                            final isToday = _isSameDay(day, today);
                            final enabled = _inRange(day);

                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: InkWell(
                                  onTap: enabled
                                      ? () => Navigator.of(context).pop(day)
                                      : null,
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    height: 40,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      gradient: isSelected
                                          ? LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [successStart, ez.accentGreen],
                                            )
                                          : null,
                                      border: !isSelected && isToday
                                          ? Border.all(color: ez.accentGreen, width: 1.5)
                                          : null,
                                    ),
                                    child: Text(
                                      '${day.day}',
                                      style: GoogleFonts.kanit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : (enabled
                                                  ? ez.textPrimary
                                                  : ez.textSecondary.withValues(alpha: 0.4)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap, required this.ez});

  final IconData icon;
  final VoidCallback onTap;
  final EzColors ez;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: ez.textSecondary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: ez.textPrimary),
      ),
    );
  }
}

const List<String> _kMonthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
