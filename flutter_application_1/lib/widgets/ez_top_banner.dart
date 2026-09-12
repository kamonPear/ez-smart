import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ez_header.dart';

/// ระดับความสำคัญของข้อความแจ้งเตือน
/// - [success] เขียว: ทำรายการสำเร็จ
/// - [warning] ส้ม: เตือนให้กรอก/แก้ข้อมูลก่อนไปต่อ (ใช้บ่อยที่สุด)
/// - [error] แดง: เก็บไว้ใช้กับเรื่องที่ผิดพลาดจริงๆ เท่านั้น เช่น ต่อเซิร์ฟเวอร์ไม่ได้
enum EzBannerType { success, warning, error }

/// แสดงข้อความแจ้งเตือนแบบเด้งลงมาจากด้านบนจอ (แทน SnackBar ปกติที่โผล่จากขอบล่าง
/// ซึ่งมักโดนแถบเมนูด้านล่างบังในหน้าที่มี bottom navigation)
/// ดีไซน์เป็นการ์ดสีเดียวกับธีมแอป + ไอคอนชิปสี ให้เข้ากับดีไซน์การ์ด/ไดอะล็อกอื่นๆ ในแอป
void showEzTopBanner(
  BuildContext context,
  String message, {
  EzBannerType type = EzBannerType.warning,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _EzTopBanner(
      message: message,
      type: type,
      onDismiss: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _EzTopBanner extends StatefulWidget {
  final String message;
  final EzBannerType type;
  final VoidCallback onDismiss;

  const _EzTopBanner({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_EzTopBanner> createState() => _EzTopBannerState();
}

class _EzTopBannerState extends State<_EzTopBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
    reverseDuration: const Duration(milliseconds: 220),
  );
  // เด้งลงมาแบบมี overshoot เล็กน้อย (easeOutBack) ให้ความรู้สึก "เด้ง" จริงๆ
  // แต่ตอนหุบกลับ (reverse) ใช้ easeInCubic เรียบๆ ไม่เด้งซ้ำตอนปิด
  late final Animation<Offset> _offset =
      Tween<Offset>(begin: const Offset(0, -1.5), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        ),
      );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    reverseCurve: Curves.easeIn,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 0.9,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  Timer? _timer;
  bool _removed = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(const Duration(seconds: 3), _dismiss);
  }

  Future<void> _dismiss() async {
    if (_removed) return;
    _removed = true;
    _timer?.cancel();
    if (mounted) {
      await _controller.reverse();
    }
    widget.onDismiss();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ez = ezColors(context);
    final Color accent = switch (widget.type) {
      EzBannerType.success => ez.accentGreen,
      EzBannerType.warning => const Color(0xFFF57C00),
      EzBannerType.error => ez.danger,
    };
    final IconData icon = switch (widget.type) {
      EzBannerType.success => Icons.check_circle_rounded,
      EzBannerType.warning => Icons.warning_amber_rounded,
      EzBannerType.error => Icons.error_rounded,
    };

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offset,
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: _dismiss,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                  decoration: BoxDecoration(
                    color: ezCardColor(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.25),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 9),
                          child: Text(
                            widget.message,
                            style: GoogleFonts.kanit(
                              color: ez.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _dismiss,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: ez.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
