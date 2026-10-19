import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ez_header.dart';

/// ป็อบอัพ "ยืนยันก่อนบันทึก" ตัวกลางของทั้งแอป - ทุกหน้าที่มีปุ่มบันทึกเรียกก่อนส่งข้อมูล
/// ไป backend เพื่อให้เจ้าของฟาร์มทวนข้อมูลอีกรอบ (ตัวเดียวกับเว็บ: src/app/services/confirm.service.ts)
///
/// [details] = รายการข้อมูลที่กำลังจะบันทึก แสดงเป็นบรรทัด ๆ ให้ทวน
/// คืน true เมื่อกด "ยืนยัน บันทึก" / false เมื่อกด "กลับไปแก้ไข" หรือแตะนอกกล่อง
///
/// วิธีใช้:  if (!await showEzConfirm(context, message: 'บันทึกคอก A ใช่ไหม?')) return;
Future<bool> showEzConfirm(
  BuildContext context, {
  String title = 'ยืนยันการบันทึก',
  required String message,
  List<String> details = const [],
  String confirmText = 'ยืนยัน บันทึก',
  String cancelText = 'กลับไปแก้ไข',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final ez = ezColors(dialogContext);
      return AlertDialog(
        backgroundColor: ezCardColor(dialogContext),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        title: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: ez.accentGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.help_outline_rounded,
                color: ez.accentGreen,
                size: 28,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ez.textPrimary,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.kanit(
                  fontSize: 14,
                  color: ez.textSecondary,
                  height: 1.5,
                ),
              ),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: ez.textPrimary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final d in details)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            d,
                            style: GoogleFonts.kanit(
                              fontSize: 13.5,
                              color: ez.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ez.textSecondary,
                    side: BorderSide(color: ez.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    cancelText,
                    style: GoogleFonts.kanit(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ez.accentGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    confirmText,
                    style: GoogleFonts.kanit(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
  return ok == true;
}

/// วันที่แบบไทยสั้น ๆ ไว้แสดงในรายละเอียดของป็อบอัพ เช่น 19 ต.ค. 2569
String ezConfirmDate(DateTime? d) {
  if (d == null) return '-';
  const m = [
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
  return '${d.day} ${m[d.month - 1]} ${d.year + 543}';
}

/// สร้างรายการ "สิ่งที่แก้ไข" สำหรับหน้าแก้ไขข้อมูล - เอาเฉพาะช่องที่ค่าเปลี่ยนจริง
/// แต่ละแถว: [ชื่อช่อง, ค่าเดิม, ค่าใหม่] ได้ผลเช่น "จำนวนไก่: 50 ตัว → 55 ตัว"
/// คืน [] ถ้าไม่มีอะไรเปลี่ยน (เหมือน changedLines ของเว็บ)
List<String> ezChangedLines(List<List<String?>> rows) {
  String show(String? v) {
    final t = (v ?? '').replaceAll(RegExp(r'\s*/\s*'), '/').trim();
    return t.isEmpty ? '(ว่าง)' : t;
  }

  return [
    for (final r in rows)
      if (show(r[1]) != show(r[2])) '${r[0]}: ${show(r[1])} → ${show(r[2])}',
  ];
}
