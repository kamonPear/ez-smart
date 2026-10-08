import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/backend_config.dart';
import '../../widgets/ez_header.dart';
import '../../widgets/ez_form_field.dart';
import '../../widgets/ez_top_banner.dart';
import '../../utils/vaccine_methods.dart';
import '../bottombar.dart';
import '../main_dash.dart';
import '../Data_AdoptChicken/Main_DataChicken_2.dart';
import '../Data_Food/Main_DataFood_ShowDataFood1.dart';
import '../Main_SenSor/Main_DeviceSummary.dart';
import '../Show_chart.dart';

/// หน้าเพิ่ม "ประเภทวัคซีน/ยา" ใหม่เข้าไปในระบบ นอกเหนือจากที่ฟิกไว้เดิม
/// เพื่อให้เจ้าของฟาร์มกรอกยาชนิดอื่นที่ยังไม่มีในระบบได้เอง
/// บันทึกลงตาราง medicine_schedules ผ่าน POST /api/vaccines/schedule
class AddVaccineType extends StatefulWidget {
  const AddVaccineType({super.key});

  @override
  State<AddVaccineType> createState() => _AddVaccineTypeState();
}

class _AddVaccineTypeState extends State<AddVaccineType> {
  int? selectedIndex; // ไม่ใช่หน้าในแถบเมนูล่าง จึงไม่ไฮไลต์เมนูไหน
  final TextEditingController _nameController = TextEditingController();
  // _minAgeController/_maxAgeController คือค่าจริงที่ส่งไป backend (int, หน่วยวัน)
  // ส่วน _minAgeWeeksController/_minAgeMonthsController/... เป็นแค่ช่องกรอก/แสดง
  // หน่วยอื่นควบคู่กันไปด้วย (ดู _onMinDaysChanged/_onMinWeeksChanged/... ด้านล่าง)
  // เพื่อให้เจ้าของฟาร์มกรอกเป็นสัปดาห์หรือเดือนก็ได้โดยไม่ต้องแปลงเป็นวันเอง
  final TextEditingController _minAgeController = TextEditingController();
  final TextEditingController _minAgeWeeksController = TextEditingController();
  final TextEditingController _minAgeMonthsController = TextEditingController();
  final TextEditingController _maxAgeController = TextEditingController();
  final TextEditingController _maxAgeWeeksController = TextEditingController();
  final TextEditingController _maxAgeMonthsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedMethod;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _minAgeController.dispose();
    _minAgeWeeksController.dispose();
    _minAgeMonthsController.dispose();
    _maxAgeController.dispose();
    _maxAgeWeeksController.dispose();
    _maxAgeMonthsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  double _round1(double n) => (n * 10).round() / 10;

  String _formatNum(double n) {
    if (n == n.roundToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(1);
  }

  // เดือนโชว์เป็นจำนวนเต็มเสมอ ไม่มีทศนิยม (เช่น 10 วัน = "0 เดือน" ไม่ใช่ "0.3
  // เดือน") - นับเฉพาะเดือนที่ครบจริงๆ เหมือนวิธีนับอายุทั่วไป จึงปัดลง (floor)
  // ไม่ใช่ปัดเข้าใกล้
  int _monthsWhole(int days) => days ~/ 30;

  // กรอกช่อง "วัน" (ต่ำสุด) - วันเป็นค่าหลักอยู่แล้ว แค่คำนวณสัปดาห์/เดือนที่
  // เทียบเท่ากันมาโชว์คู่กัน ไม่แตะช่องวันเอง
  void _onMinDaysChanged() {
    final days = int.tryParse(_minAgeController.text.trim());
    if (days == null) {
      _minAgeWeeksController.text = '';
      _minAgeMonthsController.text = '';
      return;
    }
    _minAgeWeeksController.text = _formatNum(_round1(days / 7));
    _minAgeMonthsController.text = _monthsWhole(days).toString();
  }

  // กรอกช่อง "สัปดาห์" (ต่ำสุด) - แปลงเป็นวันก่อน (ปัดเศษ เพราะ backend รับแค่ int)
  // แล้วคำนวณเดือนที่เทียบเท่าใหม่จากวันนั้น ไม่แตะช่องสัปดาห์เอง กันค่าที่เพิ่งพิมพ์
  // โดนปัดเปลี่ยนขณะพิมพ์อยู่
  void _onMinWeeksChanged() {
    final weeks = double.tryParse(_minAgeWeeksController.text.trim());
    if (weeks == null) {
      _minAgeController.text = '';
      _minAgeMonthsController.text = '';
      return;
    }
    final days = (weeks * 7).round();
    _minAgeController.text = days.toString();
    _minAgeMonthsController.text = _monthsWhole(days).toString();
  }

  // กรอกช่อง "เดือน" (ต่ำสุด) - หลักการเดียวกับ _onMinWeeksChanged
  void _onMinMonthsChanged() {
    final months = int.tryParse(_minAgeMonthsController.text.trim());
    if (months == null) {
      _minAgeController.text = '';
      _minAgeWeeksController.text = '';
      return;
    }
    final days = months * 30;
    _minAgeController.text = days.toString();
    _minAgeWeeksController.text = _formatNum(_round1(days / 7));
  }

  void _onMaxDaysChanged() {
    final days = int.tryParse(_maxAgeController.text.trim());
    if (days == null) {
      _maxAgeWeeksController.text = '';
      _maxAgeMonthsController.text = '';
      return;
    }
    _maxAgeWeeksController.text = _formatNum(_round1(days / 7));
    _maxAgeMonthsController.text = _monthsWhole(days).toString();
  }

  void _onMaxWeeksChanged() {
    final weeks = double.tryParse(_maxAgeWeeksController.text.trim());
    if (weeks == null) {
      _maxAgeController.text = '';
      _maxAgeMonthsController.text = '';
      return;
    }
    final days = (weeks * 7).round();
    _maxAgeController.text = days.toString();
    _maxAgeMonthsController.text = _monthsWhole(days).toString();
  }

  void _onMaxMonthsChanged() {
    final months = int.tryParse(_maxAgeMonthsController.text.trim());
    if (months == null) {
      _maxAgeController.text = '';
      _maxAgeWeeksController.text = '';
      return;
    }
    final days = months * 30;
    _maxAgeController.text = days.toString();
    _maxAgeWeeksController.text = _formatNum(_round1(days / 7));
  }

  // แถวกรอกอายุ 3 ช่อง (วัน/สัปดาห์/เดือน) ที่ sync กันเอง - ไม่ใช้ EzFormTextField
  // ตรงๆ เพราะตัวนั้นออกแบบมาเป็น 1 label + 1 ช่องเต็มแถว ใส่ 3 ช่องเรียงกันจะแคบ
  // เกินไปบนจอมือถือ จึงทำแถวกะทัดรัดเองแต่ใช้โทนสี/กรอบเดียวกับฟอร์มอื่น (ez.inputFill/ez.border)
  Widget _buildAgeInputGroup({
    required String label,
    required TextEditingController daysController,
    required TextEditingController weeksController,
    required TextEditingController monthsController,
    required VoidCallback onDaysChanged,
    required VoidCallback onWeeksChanged,
    required VoidCallback onMonthsChanged,
  }) {
    final ez = ezColors(context);

    Widget smallField(
      TextEditingController controller,
      String suffix,
      VoidCallback onChanged, {
      bool decimal = true,
    }) {
      return Expanded(
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: ez.inputFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ez.border, width: 1.2),
          ),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: decimal,
                  ),
                  onChanged: (_) => onChanged(),
                  style: GoogleFonts.kanit(color: ez.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    filled: false,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                    // border เฉยๆ เป็นแค่ fallback - ต้องปิดทุก state (enabled/
                    // focused) แยกกัน ไม่งั้นตอนแตะช่องนี้ Flutter จะโชว์กรอบ
                    // โฟกัสสีส้มวงรีทับของเดิมที่เราวาดเอง (ของ Container ข้างนอก)
                    // กลายเป็นช่องนี้หน้าตาแปลกกว่าช่องอื่นตอนโฟกัสอยู่
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: '0',
                    hintStyle: GoogleFonts.kanit(
                      color: ez.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                suffix,
                style: GoogleFonts.kanit(color: ez.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            children: [
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
        const SizedBox(height: 6),
        Row(
          children: [
            smallField(daysController, 'วัน', onDaysChanged, decimal: false),
            const SizedBox(width: 8),
            smallField(weeksController, 'สัปดาห์', onWeeksChanged),
            const SizedBox(width: 8),
            smallField(
              monthsController,
              'เดือน',
              onMonthsChanged,
              decimal: false,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showEzTopBanner(
        context,
        'กรุณากรอกชื่อยา/วัคซีน',
        type: EzBannerType.warning,
      );
      return;
    }
    if (_selectedMethod == null) {
      showEzTopBanner(
        context,
        'กรุณาเลือกวิธีการให้',
        type: EzBannerType.warning,
      );
      return;
    }
    final minAge = int.tryParse(_minAgeController.text.trim());
    final maxAge = int.tryParse(_maxAgeController.text.trim());
    if (minAge == null || maxAge == null) {
      showEzTopBanner(
        context,
        'กรุณากรอกช่วงอายุให้ครบถ้วน',
        type: EzBannerType.warning,
      );
      return;
    }
    if (minAge > maxAge) {
      showEzTopBanner(
        context,
        'อายุต่ำสุดต้องไม่มากกว่าอายุสูงสุด',
        type: EzBannerType.warning,
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final response = await ApiClient.post(
        Uri.parse('$backendBaseUrl/api/vaccines/schedule'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'name': name,
          'method': _selectedMethod,
          'min_age_days': minAge,
          'max_age_days': maxAge,
          'description': _descriptionController.text.trim(),
        }),
      );

      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        // แสดงข้อความจริงจาก backend ถ้ามี (เช่น "มียา/วัคซีนชื่อนี้อยู่ในระบบแล้ว"
        // ตอนชื่อซ้ำ - สถานะ 409) แทนข้อความกลางๆ เดิมที่ไม่บอกสาเหตุจริง ทำให้
        // ดูเหมือนบันทึกไม่เข้าทั้งที่จริงๆ ระบบปฏิเสธด้วยเหตุผลที่ชัดเจนอยู่แล้ว
        String message = 'บันทึกไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
        try {
          final decoded = json.decode(response.body);
          if (decoded is Map && decoded['message'] is String) {
            message = decoded['message'] as String;
          }
        } catch (_) {
          // response.body ไม่ใช่ JSON (เช่น plain text error) - ใช้ข้อความกลางๆ ต่อไป
        }
        showEzTopBanner(context, message, type: EzBannerType.error);
      }
    } catch (e) {
      if (!mounted) return;
      showEzTopBanner(
        context,
        'เชื่อมต่อ backend ไม่สำเร็จ',
        type: EzBannerType.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void onTabSelected(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainDeviceSummary()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ShowChart()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Mainchicken()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainShowDataFood()),
      );
    } else {
      setState(() {
        selectedIndex = index;
      });
    }
  }

  void _warnEmoji() {
    // formatter ถูกเรียกระหว่างจัดการ input - เลื่อนไปแสดง banner หลังเฟรมนี้
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showEzTopBanner(
        context,
        'ไม่สามารถกรอกอิโมจิได้',
        type: EzBannerType.warning,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ez = ezColors(context);
    return Scaffold(
      extendBody: true,
      backgroundColor: ezBackgroundColor(context),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EzHeader(pageTitle: 'เพิ่มประเภทวัคซีน/ยา'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: ezCardDecoration(context, radius: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ez.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.vaccines_rounded,
                            color: ez.gold,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'ข้อมูลยา/วัคซีนชนิดใหม่',
                            style: GoogleFonts.kanit(
                              color: ez.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    EzFormTextField(
                      label: 'ชื่อยา',
                      isRequired: true,
                      controller: _nameController,
                      inputFormatters: [
                        NoEmojiFormatter(onRejected: _warnEmoji),
                      ],
                      hintText: 'เช่น นิวคาสเซิล, หลอดลมอักเสบ',
                    ),
                    const SizedBox(height: 12),
                    EzFormDropdown<String>(
                      label: 'วิธีการให้',
                      isRequired: true,
                      value: _selectedMethod,
                      hint: 'เลือกวิธีการให้',
                      items: kVaccineMethodOptions
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _selectedMethod = val),
                    ),
                    const SizedBox(height: 12),
                    _buildAgeInputGroup(
                      label: 'อายุต่ำสุดที่ให้',
                      daysController: _minAgeController,
                      weeksController: _minAgeWeeksController,
                      monthsController: _minAgeMonthsController,
                      onDaysChanged: _onMinDaysChanged,
                      onWeeksChanged: _onMinWeeksChanged,
                      onMonthsChanged: _onMinMonthsChanged,
                    ),
                    const SizedBox(height: 12),
                    _buildAgeInputGroup(
                      label: 'อายุสูงสุดที่ให้',
                      daysController: _maxAgeController,
                      weeksController: _maxAgeWeeksController,
                      monthsController: _maxAgeMonthsController,
                      onDaysChanged: _onMaxDaysChanged,
                      onWeeksChanged: _onMaxWeeksChanged,
                      onMonthsChanged: _onMaxMonthsChanged,
                    ),
                    const SizedBox(height: 12),
                    EzFormTextField(
                      label: 'คำอธิบาย',
                      controller: _descriptionController,
                      hintText: 'ไม่บังคับ',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ez.accentGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: Text(
                    _isSaving ? 'กำลังบันทึก...' : 'บันทึกยา/วัคซีน',
                    style: GoogleFonts.kanit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected,
      ),
    );
  }
}
