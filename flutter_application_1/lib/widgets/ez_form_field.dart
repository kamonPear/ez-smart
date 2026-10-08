import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ez_header.dart';

const double kEzFormLabelWidth = 104;

/// รับเฉพาะตัวเลขจำนวนเต็ม (0-9) - ตัวอักษร/สัญลักษณ์ที่พิมพ์หรือวางเข้ามาจะถูก
/// ตัดทิ้ง และเรียก [onRejected] เพื่อให้หน้าที่ใช้แจ้งเตือนผู้ใช้
class IntegerOnlyFormatter extends TextInputFormatter {
  final VoidCallback onRejected;

  const IntegerOnlyFormatter({required this.onRejected});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final result = FilteringTextInputFormatter.digitsOnly.formatEditUpdate(
      oldValue,
      newValue,
    );
    if (result.text != newValue.text) onRejected();
    return result;
  }
}

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

/// ไม่รับอิโมจิ (พิมพ์ตัวอักษร/สัญลักษณ์อื่นได้ตามปกติ) - อิโมจิที่พิมพ์หรือวาง
/// เข้ามาจะถูกตัดทิ้ง และเรียก [onRejected] เพื่อให้หน้าที่ใช้แจ้งเตือนผู้ใช้
class NoEmojiFormatter extends TextInputFormatter {
  final VoidCallback onRejected;

  const NoEmojiFormatter({required this.onRejected});

  // ช่วงรหัสของอิโมจิ/พิกโตกราฟ รวมธงชาติ, variation selector และตัวเชื่อม ZWJ
  // (ที่ใช้ประกอบอิโมจิหลายตัวเป็นตัวเดียว)
  static final _emoji = RegExp(
    r'[\u{1F000}-\u{1FAFF}\u{2190}-\u{21FF}\u{2300}-\u{23FF}\u{2460}-\u{24FF}'
    r'\u{25A0}-\u{27BF}\u{2900}-\u{297F}\u{2B00}-\u{2BFF}\u{3030}\u{303D}'
    r'\u{3297}\u{3299}\u{FE00}-\u{FE0F}\u{200D}\u{20E3}\u{E0020}-\u{E007F}]',
    unicode: true,
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!_emoji.hasMatch(newValue.text)) return newValue;
    onRejected();
    // กรองทีละส่วน (ก่อน/หลังเคอร์เซอร์) เพื่อให้ตำแหน่งเคอร์เซอร์ยังถูกต้อง
    final sel = newValue.selection;
    if (!sel.isValid) {
      return TextEditingValue(text: newValue.text.replaceAll(_emoji, ''));
    }
    final before = newValue.text.substring(0, sel.start).replaceAll(_emoji, '');
    final selected = newValue.text
        .substring(sel.start, sel.end)
        .replaceAll(_emoji, '');
    final after = newValue.text.substring(sel.end).replaceAll(_emoji, '');
    return TextEditingValue(
      text: '$before$selected$after',
      selection: TextSelection(
        baseOffset: before.length,
        extentOffset: before.length + selected.length,
      ),
    );
  }
}

/// ช่องกรอกข้อความมาตรฐานพร้อม label ด้านซ้าย ดีไซน์เดียวกันทุกช่องในฟอร์ม
class EzFormTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? hintText;
  final bool isRequired;

  /// หน่วยที่แสดงชิดขวาในช่อง เช่น "วัน", "กก." (ไม่ใช่ค่าที่ผู้ใช้กรอก)
  final String? suffixText;

  const EzFormTextField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
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
              inputFormatters: widget.inputFormatters,
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

/// ช่องเลือกวันที่พร้อม label ด้านซ้าย ดีไซน์เดียวกับ [EzFormTextField]
/// ตัวช่องไม่ให้พิมพ์เอง แตะแล้วให้หน้าที่เรียกใช้เปิดปฏิทินผ่าน [onTap]
/// (ปล่อยให้แต่ละหน้าคุมรูปแบบวันที่ที่เก็บใน controller เอง เช่น พ.ศ.)
class EzFormDateField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onTap;
  final bool isRequired;
  final String hintText;

  const EzFormDateField({
    super.key,
    required this.label,
    required this.controller,
    required this.onTap,
    this.isRequired = false,
    this.hintText = 'เลือกวันที่',
  });

  @override
  Widget build(BuildContext context) {
    final ez = ezColors(context);
    return EzFormRow(
      label: label,
      isRequired: isRequired,
      child: InkWell(
        onTap: onTap,
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final hasValue = value.text.isNotEmpty;
            return Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? value.text : hintText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.kanit(
                      fontSize: hasValue ? 14 : 13,
                      color: hasValue ? ez.textPrimary : ez.textSecondary,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today_outlined, size: 16, color: ez.gold),
              ],
            );
          },
        ),
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
