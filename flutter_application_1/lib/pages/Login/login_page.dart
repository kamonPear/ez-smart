import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/farm_settings.dart';
import '../../widgets/ez_header.dart';

/// หน้าเข้าสู่ระบบ — ไม่มีลิงก์สมัครสมาชิก เพราะบัญชีผู้ใช้ถูกสร้างโดยแอดมิน
/// นอกระบบ (ผ่าน API /api/auth/register โดยตรง) เท่านั้น
///
/// ดีไซน์ตั้งใจให้เหมือนหน้า login ฝั่งเว็บ (การ์ดสีขาวลอยกลางจอ, โลโก้ในกรอบ
/// มน, ช่องกรอกทรงแคปซูล, ปุ่มเขียวทรงแคปซูล) แทนที่จะใช้ธีม input ปกติของแอป
/// มือถือ เพื่อให้ผู้ใช้ที่สลับไปมาระหว่างเว็บ/มือถือรู้สึกว่าเป็นระบบเดียวกัน
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'กรุณากรอกชื่อผู้ใช้และรหัสผ่านให้ครบถ้วน');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _authService.login(username, password);
      // ✅ ตอนแอปเพิ่งเปิด (ยังไม่เคยล็อกอิน) main() จะยังไม่มี token ให้
      // farmThresholdController.load() ใช้ ค่าที่โชว์เลยยังเป็นค่า default ตายตัว
      // อยู่ - พอล็อกอินสำเร็จแล้วมี token จริง ต้องโหลดค่าจาก backend ซ้ำอีกรอบ
      // ตรงนี้ ไม่ต้องรอ (fire-and-forget) กันหน่วงการนำทางเข้าแอป
      farmThresholdController.load();
      // ✅ เช่นเดียวกัน โหลดธีมที่จำไว้ "ของ username นี้โดยเฉพาะ" ซ้ำอีกรอบ
      // (ตอน main() เรียกไปตอนแรกยังไม่รู้ว่าใคร login เลยใช้ default ไปก่อน)
      // กันธีมของบัญชีอื่นที่เคยล็อกอินบนเครื่องนี้ติดตามมาโชว์ผิดบัญชี
      themeController.load(username: username);
      if (!mounted) return;
      // ล้าง stack ทั้งหมดตอนเข้าสู่ระบบสำเร็จ กันปุ่มย้อนกลับพากลับมาหน้า Login
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/main', (route) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ez = ezColors(context);

    return Scaffold(
      backgroundColor: ez.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.symmetric(
                horizontal: 34,
                vertical: 40,
              ),
              decoration: BoxDecoration(
                color: ez.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ez.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Brand(ez: ez),
                  const SizedBox(height: 32),
                  _PillField(
                    ez: ez,
                    controller: _usernameController,
                    hintText: 'ชื่อผู้ใช้',
                    icon: Icons.person_outline,
                    enabled: !_isSubmitting,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                  ),
                  const SizedBox(height: 16),
                  _PillField(
                    ez: ez,
                    controller: _passwordController,
                    hintText: 'รหัสผ่าน',
                    icon: Icons.lock_outline,
                    enabled: !_isSubmitting,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _submit(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: ez.textSecondary,
                      ),
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.kanit(
                        color: ez.danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _SubmitButton(
                    ez: ez,
                    isSubmitting: _isSubmitting,
                    onPressed: _submit,
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

class _Brand extends StatelessWidget {
  const _Brand({required this.ez});

  final EzColors ez;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: ez.inputFill,
            border: Border.all(color: ez.border),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
        ),
        const SizedBox(height: 14),
        Text(
          'EZ-SmartFarm',
          style: GoogleFonts.kanit(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: ez.accentGreen,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'เข้าสู่ระบบเพื่อจัดการฟาร์มของคุณ',
          textAlign: TextAlign.center,
          style: GoogleFonts.kanit(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: ez.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// ช่องกรอกทรงแคปซูล (bo-radius สูงมาก) พร้อมไอคอนนำหน้า - เลียนแบบ .input-pill
/// ของฝั่งเว็บ ไม่ใช้ InputDecorationTheme ปกติของแอปเพราะทรงนั้นเป็นกล่องเหลี่ยม
class _PillField extends StatelessWidget {
  const _PillField({
    required this.ez,
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.enabled,
    this.obscureText = false,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.suffixIcon,
  });

  final EzColors ez;
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool enabled;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final List<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ez.inputFill,
        border: Border.all(color: ez.border),
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(icon, size: 20, color: ez.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              obscureText: obscureText,
              textInputAction: textInputAction,
              autofillHints: autofillHints,
              onSubmitted: onSubmitted,
              style: GoogleFonts.kanit(
                color: ez.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.kanit(
                  color: ez.textSecondary.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w400,
                ),
                // ต้องปิดทุกสถานะของ border เอง (ไม่ใช่แค่ border เฉยๆ) เพราะ
                // InputDecorationTheme ของทั้งแอป (app_theme.dart) ตั้ง
                // enabledBorder/focusedBorder เป็น OutlineInputBorder ไว้ตายตัว
                // ซึ่งมีลำดับความสำคัญเหนือกว่า border เฉยๆ ตอน field ยังไม่โฟกัส/
                // โฟกัสอยู่ - ถ้าไม่ปิดครบจะเห็นเป็นกรอบเหลี่ยมเล็กซ้อนอยู่ในเม็ดแคปซูล
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (suffixIcon != null) suffixIcon!,
        ],
      ),
    );
  }
}

/// ปุ่มยืนยันทรงแคปซูลสีเขียว พร้อมไอคอนลูกศร - เลียนแบบ .btn-confirm ของเว็บ
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.ez,
    required this.isSubmitting,
    required this.onPressed,
  });

  final EzColors ez;
  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ez.accentGreen,
          disabledBackgroundColor: ez.accentGreen.withValues(alpha: 0.6),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
        child: isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.login_rounded, size: 20),
                  const SizedBox(width: 9),
                  Text(
                    'เข้าสู่ระบบ',
                    style: GoogleFonts.kanit(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
