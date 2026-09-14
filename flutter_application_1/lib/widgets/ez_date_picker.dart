import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ez_header.dart';

/// เปิดปฏิทินเลือกวันที่แบบเดียวกันทั้งแอป — ธีมสีทอง/ฟอนต์ Kanit ให้เข้ากับ
/// หน้าตาแอป (แทนปฏิทิน Material ดีฟอลต์สีน้ำเงิน + ฟอนต์อังกฤษที่ดูหลุดธีม)
/// ใช้แทน showDatePicker ตรงๆ ทุกจุดในแอป เพื่อให้ปฏิทินหน้าตาเหมือนกันหมด
Future<DateTime?> showEzDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String? helpText,
}) {
  final ez = ezColors(context);
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate ?? DateTime(2000),
    lastDate: lastDate ?? DateTime(2101),
    helpText: helpText,
    cancelText: 'ยกเลิก',
    confirmText: 'ตกลง',
    builder: (context, child) {
      final baseTheme = Theme.of(context);
      return Theme(
        data: baseTheme.copyWith(
          colorScheme: baseTheme.colorScheme.copyWith(
            primary: ez.gold,
            onPrimary: Colors.white,
            surface: ez.card,
            onSurface: ez.textPrimary,
          ),
          textTheme: GoogleFonts.kanitTextTheme(baseTheme.textTheme),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: ez.card,
            headerBackgroundColor: ez.gold,
            headerForegroundColor: Colors.white,
            headerHeadlineStyle: GoogleFonts.kanit(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            weekdayStyle: GoogleFonts.kanit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ez.textSecondary,
            ),
            todayForegroundColor: WidgetStatePropertyAll(ez.gold),
            todayBorder: BorderSide(color: ez.gold, width: 1.3),
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              if (states.contains(WidgetState.disabled)) return ez.border;
              return ez.textPrimary;
            }),
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return ez.gold;
              return null;
            }),
            dayOverlayColor: WidgetStatePropertyAll(
              ez.gold.withValues(alpha: 0.12),
            ),
            yearForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              return ez.textPrimary;
            }),
            yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return ez.gold;
              return null;
            }),
            yearOverlayColor: WidgetStatePropertyAll(
              ez.gold.withValues(alpha: 0.12),
            ),
          ),
        ),
        child: child!,
      );
    },
  );
}
