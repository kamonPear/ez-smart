import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ez_header.dart';

/// ไดอะล็อกยืนยันการทำรายการแบบเดียวกันทั้งแอป (ใช้บ่อยที่สุดกับการยืนยันลบข้อมูล)
/// ดีไซน์: การ์ดกึ่งกลางจอ ไอคอนวงกลมด้านบน + หัวข้อ + ข้อความ + ปุ่มเต็มความกว้าง 2 ปุ่ม
/// เรียกผ่าน [showEzConfirmDialog] หรือ [showEzDeleteConfirm] แทนการสร้าง AlertDialog
/// เองในแต่ละหน้า เพื่อให้ทุกจุดในแอปมีหน้าตาเหมือนกันและรองรับธีมมืด/สว่างถูกต้อง
class EzConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final IconData icon;
  final bool isDanger;

  const EzConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'ยืนยัน',
    this.cancelText = 'ยกเลิก',
    this.icon = Icons.help_outline_rounded,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final ez = ezColors(context);
    final Color accent = isDanger ? ez.danger : ez.gold;

    return Dialog(
      backgroundColor: ezCardColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: ez.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(
                fontSize: 13,
                color: ez.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(color: ez.border, width: 1.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      cancelText,
                      style: GoogleFonts.kanit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ez.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      confirmText,
                      style: GoogleFonts.kanit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// เปิดไดอะล็อกยืนยัน คืนค่า true เมื่อกดยืนยัน, false เมื่อยกเลิกหรือปิดไดอะล็อกเฉยๆ
Future<bool> showEzConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'ยืนยัน',
  String cancelText = 'ยกเลิก',
  IconData icon = Icons.help_outline_rounded,
  bool isDanger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => EzConfirmDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      icon: icon,
      isDanger: isDanger,
    ),
  );
  return result ?? false;
}

/// รูปแบบเฉพาะสำหรับยืนยันการลบ (ใช้บ่อยที่สุด) — ไอคอนถังขยะ ปุ่มยืนยันสีแดง
Future<bool> showEzDeleteConfirm(
  BuildContext context, {
  String title = 'ยืนยันการลบ',
  required String message,
  String confirmText = 'ลบ',
}) {
  return showEzConfirmDialog(
    context,
    title: title,
    message: message,
    confirmText: confirmText,
    icon: Icons.delete_outline_rounded,
    isDanger: true,
  );
}
