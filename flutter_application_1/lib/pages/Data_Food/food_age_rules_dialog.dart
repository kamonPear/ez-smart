import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_client.dart';
import '../../services/backend_config.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ez_header.dart';
import '../../widgets/ez_top_banner.dart';
import 'Main_DataAdd_Food1.dart' show kFoodTypeSmallPellet, kFoodTypeLargePellet;
import '../../widgets/ez_confirm_dialog.dart';

/// เปิดป็อบอัพ "เงื่อนไขอายุไก่กับประเภทอาหาร" (เหมือนในเว็บ) - เจ้าของกรอกตารางว่าไก่อายุ
/// กี่สัปดาห์ให้กินอาหารประเภทไหน และไก่ 1 ตัวกินกี่กรัมต่อวัน คืน true ถ้าบันทึกสำเร็จ
Future<bool?> showFoodAgeRulesDialog(BuildContext context) async {
  List<dynamic> rules;
  try {
    final response = await ApiClient.get(
      Uri.parse('$backendBaseUrl/api/food-age-rules'),
    );
    if (response.statusCode != 200) throw Exception(response.statusCode);
    final decoded = response.body.isNotEmpty && response.body != 'null'
        ? jsonDecode(response.body)
        : [];
    rules = decoded is List ? decoded : [];
  } catch (_) {
    if (context.mounted) {
      showEzTopBanner(
        context,
        'โหลดเงื่อนไขไม่สำเร็จ กรุณาลองใหม่อีกครั้ง',
        type: EzBannerType.error,
      );
    }
    return null;
  }
  if (!context.mounted) return null;
  return showDialog<bool>(
    context: context,
    builder: (_) => _FoodAgeRulesDialog(initialRules: rules),
  );
}

class _RuleRow {
  String foodType;
  final TextEditingController min;
  final TextEditingController max;
  final TextEditingController grams;

  _RuleRow({
    required this.foodType,
    String min = '',
    String max = '',
    String grams = '',
  }) : min = TextEditingController(text: min),
       max = TextEditingController(text: max),
       grams = TextEditingController(text: grams);

  void dispose() {
    min.dispose();
    max.dispose();
    grams.dispose();
  }
}

String _numText(dynamic v) {
  if (v is! num) return '';
  return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

class _FoodAgeRulesDialog extends StatefulWidget {
  final List<dynamic> initialRules;
  const _FoodAgeRulesDialog({required this.initialRules});

  @override
  State<_FoodAgeRulesDialog> createState() => _FoodAgeRulesDialogState();
}

class _FoodAgeRulesDialogState extends State<_FoodAgeRulesDialog> {
  final List<_RuleRow> _rows = [];
  String _error = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final r in widget.initialRules) {
      if (r is! Map<String, dynamic>) continue;
      _rows.add(
        _RuleRow(
          foodType: r['food_type']?.toString() ?? kFoodTypeSmallPellet,
          min: _numText(r['min_weeks']),
          max: _numText(r['max_weeks']),
          grams: _numText(r['grams_per_bird']),
        ),
      );
    }
    // ยังไม่เคยกรอก -> เริ่มด้วยแถวว่าง 1 แถว (ไม่เติมค่าให้)
    if (_rows.isEmpty) _rows.add(_RuleRow(foodType: kFoodTypeSmallPellet));
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _addRow() => setState(() {
    _rows.add(_RuleRow(foodType: kFoodTypeSmallPellet));
    _error = '';
  });

  void _removeRow(int i) => setState(() {
    _rows.removeAt(i).dispose();
    _error = '';
  });

  Future<void> _save() async {
    if (_rows.isEmpty) {
      setState(() => _error = 'กรุณาเพิ่มช่วงอายุอย่างน้อย 1 แถว');
      return;
    }
    final rules = <Map<String, dynamic>>[];
    for (var i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      final n = i + 1;
      final minT = row.min.text.trim();
      final maxT = row.max.text.trim();
      final gramsT = row.grams.text.trim();
      if (minT.isEmpty || maxT.isEmpty || gramsT.isEmpty) {
        setState(() => _error = 'แถวที่ $n: กรุณากรอกให้ครบทุกช่อง');
        return;
      }
      final min = int.tryParse(minT);
      final max = int.tryParse(maxT);
      final grams = double.tryParse(gramsT);
      if (min == null || max == null || min < 0 || max < 0) {
        setState(
          () => _error = 'แถวที่ $n: อายุต้องเป็นจำนวนเต็ม (สัปดาห์) ที่ไม่ติดลบ',
        );
        return;
      }
      if (max != 0 && max <= min) {
        setState(
          () => _error =
              'แถวที่ $n: อายุสิ้นสุดต้องมากกว่าอายุเริ่มต้น (หรือใส่ 0 = ไม่จำกัด)',
        );
        return;
      }
      if (grams == null || !(grams > 0)) {
        setState(
          () => _error =
              'แถวที่ $n: ปริมาณอาหารต่อตัวต่อวัน (กรัม) ต้องมากกว่า 0',
        );
        return;
      }
      rules.add({
        'food_type': row.foodType,
        'min_weeks': min,
        'max_weeks': max,
        'grams_per_bird': grams,
      });
    }
    final sorted = [...rules]
      ..sort((a, b) => (a['min_weeks'] as int).compareTo(b['min_weeks'] as int));
    for (var i = 1; i < sorted.length; i++) {
      final prevMax = sorted[i - 1]['max_weeks'] as int;
      if (prevMax == 0 || prevMax > (sorted[i]['min_weeks'] as int)) {
        setState(() => _error = 'ช่วงอายุของแต่ละแถวต้องไม่ซ้อนทับกัน');
        return;
      }
    }

    // ให้เจ้าของฟาร์มทวนข้อมูลอีกรอบก่อนบันทึกจริง (ป็อบอัพกลาง widgets/ez_confirm_dialog.dart)
    if (!await showEzConfirm(context, message: 'บันทึกเงื่อนไขอายุไก่กับประเภทอาหารใช่ไหม? ระบบจะใช้ตารางนี้คำนวณการตัดสต็อกอัตโนมัติ', details: [
      for (final r in rules)
        '${r['food_type']}: อายุ ${r['min_weeks']} - ${r['max_weeks'] == 0 ? 'ไม่จำกัด' : r['max_weeks']} สัปดาห์, ตัวละ ${r['grams_per_bird']} กรัม/วัน',
    ])) return;
    if (!mounted) return;
    setState(() {
      _error = '';
      _saving = true;
    });
    try {
      final response = await ApiClient.put(
        Uri.parse('$backendBaseUrl/api/food-age-rules'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: json.encode({'rules': rules}),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        Navigator.of(context).pop(true);
        return;
      }
      final msg = utf8.decode(response.bodyBytes).trim();
      setState(() {
        _saving = false;
        _error = msg.isNotEmpty && !msg.startsWith('{') && !msg.startsWith('<')
            ? msg
            : 'บันทึกไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'เชื่อมต่อ backend ไม่สำเร็จ';
      });
    }
  }

  InputDecoration _numDecoration(EzColors ez) => InputDecoration(
    isDense: true,
    filled: true,
    fillColor: ez.inputFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: ez.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: ez.border),
    ),
  );

  Widget _numField(
    EzColors ez,
    TextEditingController c, {
    required bool decimal,
  }) {
    return SizedBox(
      width: 72,
      child: TextField(
        controller: c,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            decimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'),
          ),
        ],
        style: GoogleFonts.kanit(fontSize: 14, color: ez.inputText),
        decoration: _numDecoration(ez),
        onChanged: (_) {
          if (_error.isNotEmpty) setState(() => _error = '');
        },
      ),
    );
  }

  Widget _label(EzColors ez, String text) => Text(
    text,
    style: GoogleFonts.kanit(fontSize: 13, color: ez.textSecondary),
  );

  /// เปลี่ยนประเภทของแถว: ถ้าเลือก "เม็ดใหญ่" ในแถวที่ช่วงอายุยังว่างอยู่ ให้เริ่มต่อจากที่
  /// "เม็ดเล็ก" จบ (เช่น เม็ดเล็ก 0-6 -> เม็ดใหญ่ เริ่ม 6) และใส่ "ถึง" = 0 (ไม่จำกัด)
  /// ไม่ทับค่าที่กรอกไว้แล้ว และถ้าเม็ดเล็กไม่มีอายุสิ้นสุด (0 = ไม่จำกัด) ก็ไม่เติมให้
  void _changeType(_RuleRow row, String foodType) {
    setState(() {
      row.foodType = foodType;
      _error = '';
      if (foodType != kFoodTypeLargePellet) return;
      if (row.min.text.trim().isNotEmpty || row.max.text.trim().isNotEmpty) {
        return;
      }
      var smallEnd = 0;
      for (final r in _rows) {
        if (r.foodType != kFoodTypeSmallPellet) continue;
        final end = int.tryParse(r.max.text.trim()) ?? 0;
        if (end > smallEnd) smallEnd = end;
      }
      if (smallEnd == 0) return;
      row.min.text = smallEnd.toString();
      row.max.text = '0';
    });
  }

  /// เมนูเลือกประเภทอาหาร: ปุ่มมุมโค้งพร้อมลูกศร เปิดเป็นการ์ดที่ตัวที่เลือกไฮไลต์พร้อมเครื่องหมายถูก
  Widget _buildTypeMenu(EzColors ez, _RuleRow row) {
    return PopupMenuButton<String>(
      tooltip: 'ประเภทอาหาร',
      initialValue: row.foodType,
      onSelected: (v) => _changeType(row, v),
      color: ez.card,
      elevation: 8,
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: ez.border),
      ),
      itemBuilder: (_) => [
        for (final t in const [kFoodTypeSmallPellet, kFoodTypeLargePellet])
          PopupMenuItem<String>(
            value: t,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    t,
                    style: GoogleFonts.kanit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: t == row.foodType ? ez.gold : ez.textPrimary,
                    ),
                  ),
                ),
                if (t == row.foodType)
                  Icon(Icons.check_rounded, size: 18, color: ez.gold),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
        decoration: BoxDecoration(
          color: ez.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ez.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              row.foodType,
              style: GoogleFonts.kanit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ez.inputText,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: ez.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(EzColors ez, int i) {
    final row = _rows[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ez.cardAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ez.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTypeMenu(ez, row),
              const Spacer(),
              IconButton(
                tooltip: 'ลบแถวนี้',
                icon: Icon(Icons.close, size: 18, color: ez.textSecondary),
                onPressed: () => _removeRow(i),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _label(ez, 'อายุ'),
              _numField(ez, row.min, decimal: false),
              _label(ez, 'ถึง'),
              _numField(ez, row.max, decimal: false),
              _label(ez, 'สัปดาห์'),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _label(ez, 'ไก่ 1 ตัวกินวันละ'),
              _numField(ez, row.grams, decimal: true),
              _label(ez, 'กรัม'),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ez = ezColors(context);
    return Dialog(
      backgroundColor: ez.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'เงื่อนไขอายุไก่กับประเภทอาหาร',
                style: GoogleFonts.kanit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: ez.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'กรอกตารางว่าไก่อายุกี่สัปดาห์ (นับจากวันเกิดของแต่ละคอก) '
                        'ให้กินอาหารประเภทไหน และไก่ 1 ตัวกินกี่กรัมต่อวัน เพิ่มได้หลายแถว '
                        'ระบบจะนำไปคำนวณว่าแต่ละคอกกินอาหารอะไรและกินวันละเท่าไร '
                        'ช่วงอายุนับรวมค่าเริ่มต้น ไม่รวมค่าสิ้นสุด',
                        style: GoogleFonts.kanit(
                          fontSize: 12,
                          color: ez.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (var i = 0; i < _rows.length; i++) _buildRow(ez, i),
                      OutlinedButton(
                        onPressed: _addRow,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ez.gold,
                          side: BorderSide(color: ez.gold),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          '+ เพิ่มช่วงอายุ',
                          style: GoogleFonts.kanit(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ใส่ 0 ที่ช่อง "ถึง" = ไม่จำกัดอายุ',
                        style: GoogleFonts.kanit(
                          fontSize: 11,
                          color: ez.textSecondary,
                        ),
                      ),
                      if (_error.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error,
                          style: GoogleFonts.kanit(
                            fontSize: 12,
                            color: ez.danger,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ez.textSecondary,
                        side: BorderSide(color: ez.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        'ยกเลิก',
                        style: GoogleFonts.kanit(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ez.accentGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        _saving ? 'กำลังบันทึก...' : 'บันทึก',
                        style: GoogleFonts.kanit(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
