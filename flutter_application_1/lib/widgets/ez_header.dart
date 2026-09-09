import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// Helper ที่คืนค่าสีตามโหมดปัจจุบัน (มืด/สว่าง) ของแอป
// เดิมเป็นค่าคงที่ ตอนนี้อ่านจาก Theme เพื่อให้สลับสีได้ตามโทน
EzColors ezColors(BuildContext context) =>
    Theme.of(context).extension<EzColors>()!;

Color ezBackgroundColor(BuildContext context) => ezColors(context).background;
Color ezCardColor(BuildContext context) => ezColors(context).card;
Color ezGoldColor(BuildContext context) => ezColors(context).gold;
Color ezAccentGreen(BuildContext context) => ezColors(context).accentGreen;

BoxDecoration ezCardDecoration(BuildContext context, {double radius = 20}) {
  return BoxDecoration(
    color: ezCardColor(context),
    borderRadius: BorderRadius.circular(radius),
  );
}

/// ปุ่มเปิด/ปิดสลับโหมดมืด-สว่างของทั้งแอป ใช้ได้ทุกหน้า
class EzThemeToggleButton extends StatelessWidget {
  const EzThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        final isDark = themeController.isDark;
        return Tooltip(
          message: isDark ? 'สลับเป็นโหมดสว่าง' : 'สลับเป็นโหมดมืด',
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => themeController.toggle(),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  key: ValueKey(isDark),
                  color: ezGoldColor(context),
                  size: 26,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// หัวหน้าจอมาตรฐาน: โลโก้ตัวอักษร "EZ - SMART FARM" + ปุ่มสลับโทนสี
/// และแถวปุ่มย้อนกลับ/ชื่อหน้า
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 40),
            Expanded(
              child: Text(
                'EZ - SMART FARM',
                textAlign: TextAlign.center,
                style: GoogleFonts.kanit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ezGoldColor(context),
                ),
              ),
            ),
            const SizedBox(width: 40, child: EzThemeToggleButton()),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            showBackButton
                ? IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: ezColors(context).textPrimary,
                    ),
                    onPressed: onBack ?? () => Navigator.pop(context),
                  )
                : const SizedBox(width: 48),
            Text(
              pageTitle,
              style: GoogleFonts.kanit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ezGoldColor(context),
              ),
            ),
            trailing ?? const SizedBox(width: 48),
          ],
        ),
      ],
    );
  }
}
