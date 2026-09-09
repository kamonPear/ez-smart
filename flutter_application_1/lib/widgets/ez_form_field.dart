import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ez_header.dart';

const double kEzFormLabelWidth = 104;

/// แถวฟอร์มมาตรฐาน: label ทางซ้าย + กล่องกรอกข้อมูลทางขวาในกรอบธีมเดียวกัน
/// ใช้เป็นฐานให้ [EzFormTextField] และ [EzFormDropdown] เพื่อให้ทุกช่องกรอก
/// ในแอปหน้าตาเหมือนกัน เรียกใช้ซ้ำได้หลายหน้า (วัคซีน, อาหาร, สุขภาพไก่ ฯลฯ)
class EzFormRow extends StatelessWidget {
  final String label;
  final Widget child;
  final double height;

  /// ใส่ดอกจันสีแดงหลัง label เพื่อบอกว่าเป็นช่องที่ต้องกรอก
  final bool isRequired;

  /// ไฮไลต์กรอบเป็นสีทองตอนช่องนั้นถูกโฟกัส
  final bool focused;

  const EzFormRow({
    super.key,
    required this.label,
    required this.child,
    this.height = 46,
    this.isRequired = false,
    this.focused = false,
  });

  @override
  Widget build(BuildContext context) {
    final ez = ezColors(context);
    return Row(
      children: [
        SizedBox(
          width: kEzFormLabelWidth,
          child: Text.rich(
            TextSpan(
              text: label,
              children: [
                if (isRequired)
                  TextSpan(
                    text: ' *',
                    style: GoogleFonts.kanit(
                      color: ez.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            style: GoogleFonts.kanit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ez.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: ez.inputFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: focused ? ez.gold : ez.border,
                width: focused ? 1.6 : 1.2,
              ),
            ),
            alignment: Alignment.centerLeft,
            child: child,
          ),
        ),
      ],
    );
  }
}

/// ช่องกรอกข้อความมาตรฐานพร้อม label ด้านซ้าย ดีไซน์เดียวกันทุกช่องในฟอร์ม
class EzFormTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? hintText;
  final bool isRequired;

  /// หน่วยที่แสดงชิดขวาในช่อง เช่น "วัน", "กก." (ไม่ใช่ค่าที่ผู้ใช้กรอก)
  final String? suffixText;

  const EzFormTextField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.hintText,
    this.isRequired = false,
    this.suffixText,
  });

  @override
  State<EzFormTextField> createState() => _EzFormTextFieldState();
}

class _EzFormTextFieldState extends State<EzFormTextField> {
  late final FocusNode _focusNode = FocusNode()..addListener(_onFocusChange);
  bool _focused = false;

  void _onFocusChange() {
    if (_focusNode.hasFocus != _focused) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ez = ezColors(context);
    return EzFormRow(
      label: widget.label,
      isRequired: widget.isRequired,
      focused: _focused,
      child: Row(
        children: [
          // ปิดพื้นหลัง/กรอบของ TextField เอง ไม่งั้นจะเห็นเป็นกล่องซ้อนอยู่ข้างใน
          // (ธีมรวมของแอปตั้ง filled + OutlineInputBorder ไว้)
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: widget.keyboardType,
              cursorColor: ez.gold,
              style: GoogleFonts.kanit(color: ez.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                filled: false,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: widget.hintText,
                hintStyle: GoogleFonts.kanit(
                  color: ez.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          if (widget.suffixText != null)
            Text(
              widget.suffixText!,
              style: GoogleFonts.kanit(color: ez.textSecondary, fontSize: 13),
            ),
        ],
      ),
    );
  }
}

/// ดรอปดาวน์มาตรฐานพร้อม label ด้านซ้าย ดีไซน์เดียวกับ [EzFormTextField]
class EzFormDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool isRequired;

  const EzFormDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final ez = ezColors(context);
    return EzFormRow(
      label: label,
      isRequired: isRequired,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          dropdownColor: ezCardColor(context),
          hint: Text(
            hint,
            style: GoogleFonts.kanit(color: ez.textSecondary, fontSize: 13),
          ),
          style: GoogleFonts.kanit(color: ez.textPrimary, fontSize: 14),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: ez.textSecondary,
            size: 22,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
