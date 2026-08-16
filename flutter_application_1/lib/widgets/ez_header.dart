import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// สีมาตรฐานของแอป (ใช้แทนภาพพื้นหลังเดิม)
const Color ezBackgroundColor = Color(0xFF0F1621);
const Color ezCardColor = Color(0xFF19232F);
const Color ezGoldColor = Color(0xFFE5BA93);
const Color ezAccentGreen = Color(0xFF66E07A);

BoxDecoration ezCardDecoration({double radius = 20}) {
  return BoxDecoration(
    color: ezCardColor,
    borderRadius: BorderRadius.circular(radius),
  );
}

/// หัวหน้าจอมาตรฐาน: โลโก้ตัวอักษร "EZ - SMART FARM" + แถวปุ่มย้อนกลับ/ชื่อหน้า
/// ใช้แทนพื้นหลังรูปภาพ + AppBar แบบเดิมที่แต่ละหน้าเคยเขียนซ้ำกันเอง
class EzHeader extends StatelessWidget {
  final String pageTitle;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? trailing;

  const EzHeader({
    super.key,
    required this.pageTitle,
    this.showBackButton = true,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 15),
        Text(
          'EZ - SMART FARM',
          style: GoogleFonts.oswald(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: ezGoldColor,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            showBackButton
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: onBack ?? () => Navigator.pop(context),
                  )
                : const SizedBox(width: 48),
            Text(
              pageTitle,
              style: GoogleFonts.kanit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ezGoldColor,
              ),
            ),
            trailing ?? const SizedBox(width: 48),
          ],
        ),
      ],
    );
  }
}
