import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ระดับความสำคัญของข้อความแจ้งเตือน
/// - [success] เขียว: ทำรายการสำเร็จ
/// - [warning] ส้ม: เตือนให้กรอก/แก้ข้อมูลก่อนไปต่อ (ใช้บ่อยที่สุด)
/// - [error] แดง: เก็บไว้ใช้กับเรื่องที่ผิดพลาดจริงๆ เท่านั้น เช่น ต่อเซิร์ฟเวอร์ไม่ได้
enum EzBannerType { success, warning, error }

/// แสดงข้อความแจ้งเตือนแบบเลื่อนลงมาจากด้านบนจอ (แทน SnackBar ปกติที่โผล่จากขอบล่าง
/// ซึ่งมักโดนแถบเมนูด้านล่างบังในหน้าที่มี bottom navigation)
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
    duration: const Duration(milliseconds: 250),
  );
  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(0, -1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
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
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offset,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: switch (widget.type) {
                  EzBannerType.success => const Color(0xFF55C759),
                  EzBannerType.warning => const Color(0xFFF57C00),
                  EzBannerType.error => const Color(0xFFD32F2F),
                },
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(switch (widget.type) {
                    EzBannerType.success => Icons.check_circle_outline,
                    EzBannerType.warning => Icons.warning_amber_rounded,
                    EzBannerType.error => Icons.error_outline,
                  }, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: GoogleFonts.kanit(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
