import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_client.dart';
import 'dart:convert';
import '../bottombar.dart';
import 'package:flutter_application_1/pages/Main_SenSor/Main_DeviceSummary.dart';
import '../../widgets/ez_header.dart';
import '../../widgets/ez_form_field.dart';
import '../../services/backend_config.dart';
import '../../widgets/ez_top_banner.dart';
import '../../widgets/ez_date_picker.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ez_confirm_dialog.dart';

/// ประเภทอาหารที่รองรับ - ผูกกับช่วงอายุไก่ที่กินอาหารประเภทนั้น
const String kFoodTypeSmallPellet = 'เม็ดเล็ก';
const String kFoodTypeLargePellet = 'เม็ดใหญ่';

String foodTypeAgeHint(String? foodType) {
  switch (foodType) {
    case kFoodTypeSmallPellet:
      return 'สำหรับไก่อายุ 0-14 สัปดาห์';
    case kFoodTypeLargePellet:
      return 'สำหรับไก่อายุตั้งแต่ 14 สัปดาห์ขึ้นไป';
    default:
      return 'เลือกประเภทอาหารให้ตรงกับช่วงอายุไก่';
  }
}

class MainaddDataFood extends StatefulWidget {
  const MainaddDataFood({super.key});

  @override
  State<MainaddDataFood> createState() => _MainaddDataFoodState();
}

class _MainaddDataFoodState extends State<MainaddDataFood> {
  int? selectedIndex; // ไม่ใช่หน้าในแถบเมนูล่าง จึงไม่ไฮไลต์เมนูไหน

  final TextEditingController _dateReceivedController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _expireDateController = TextEditingController();
  final TextEditingController _thresholdController = TextEditingController();

  DateTime? _selectedImportDate;
  DateTime? _selectedExpiryDate;
  String? _selectedFoodType;

  // อัตรากินจริงต่อวัน (กก.) ของแต่ละประเภทอาหาร รวมจากจำนวนไก่จริงในทุกคอกที่
  // กำลังกินอาหารประเภทนั้นอยู่ (ไม่ใช่ค่าคงที่ตายตัวอีกต่อไป) ดึงจาก endpoint
  // เดียวกับที่หน้าคลังอาหารใช้โชว์ตัวเลขต่อคอก ให้วันที่ใกล้หมดที่กะไว้ตรงกับยอด
  // ที่จะถูกตัดจริงทุกวันตอน 6 โมงเช้า ถ้าคอกยังไม่มี/ยังไม่รู้อายุ จะได้ 0 แล้วใช้ค่าเผื่อไว้แทน
  Map<String, double> _dailyConsumptionByType = {};
  static const Map<String, double> _fallbackConsumePerDay = {
    kFoodTypeSmallPellet: 20.0,
    kFoodTypeLargePellet: 30.0,
  };

  @override
  void initState() {
    super.initState();
    // 🌟 ดักจับเหตุการณ์เมื่อผู้ใช้พิมพ์ปริมาณอาหารหรือปริมาณใกล้หมด ให้คำนวณวันอัตโนมัติ
    _amountController.addListener(_calculateExpiryDate);
    _thresholdController.addListener(_calculateExpiryDate);
    _fetchDailyConsumption();
    _fetchSavedThresholds();
  }

  // ปริมาณใกล้หมดตั้งได้ครั้งเดียวแล้วล็อก: true = เคยตั้งแล้ว ช่องนี้แก้ไขไม่ได้
  bool _minLocked = false;

  // ปริมาณใกล้หมดที่เจ้าของเคยตั้งไว้ (จาก /api/foods) ใช้ค่าเดียวร่วมกันทุกประเภทอาหาร
  // เติมในช่องให้อัตโนมัติและล็อกไว้ จะได้ไม่ต้องกรอกซ้ำ
  Future<void> _fetchSavedThresholds() async {
    try {
      final response = await ApiClient.get(Uri.parse('$backendBaseUrl/api/foods'));
      if (response.statusCode != 200) return;
      final decoded = json.decode(response.body);
      if (decoded is! List) return;
      double saved = 0.0;
      for (final row in decoded) {
        final min = (row['min_quantity'] as num?)?.toDouble() ?? 0.0;
        if (min > 0) {
          saved = min;
          break;
        }
      }
      if (!mounted || saved <= 0) return;
      // เคยตั้งแล้ว -> ล็อก แก้ไขไม่ได้ (ตั้งได้ครั้งเดียว) ใช้ค่าเดิมกับทุกประเภท
      _thresholdController.text = saved == saved.roundToDouble()
          ? saved.toInt().toString()
          : saved.toString();
      setState(() => _minLocked = true);
    } catch (e) {
      debugPrint("Connection error (saved thresholds): $e");
    }
  }

  Future<void> _fetchDailyConsumption() async {
    try {
      final url = Uri.parse('$backendBaseUrl/api/foods/coop-consumption');
      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        if (decodedData is List) {
          final totals = <String, double>{};
          for (final row in decodedData) {
            final foodType = row['food_type'] as String?;
            if (foodType == null || foodType.isEmpty) continue;
            final perDay = (row['estimated_kg_per_day'] as num?)?.toDouble() ?? 0.0;
            totals[foodType] = (totals[foodType] ?? 0.0) + perDay;
          }
          setState(() => _dailyConsumptionByType = totals);
          _calculateExpiryDate();
        }
      } else {
        debugPrint("Error fetching daily consumption: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Connection error (daily consumption): $e");
    }
  }

  @override
  void dispose() {
    _dateReceivedController.dispose();
    _amountController.dispose();
    _expireDateController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  // 🌟 ฟังก์ชันคำนวณวันที่อาหารใกล้หมดอัตโนมัติ
  // ✅ ต้องกรอก "กำหนดปริมาณใกล้หมด" ก่อนเสมอ ไม่งั้นค่าเริ่มต้นจะถูกมองเป็น 0
  // ซึ่งกลายเป็นคำนวณวันที่ (ผิดๆ) ขึ้นมาทั้งที่ผู้ใช้ยังไม่ได้กรอกอะไรเลย
  void _calculateExpiryDate() {
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    // ไม่ได้กรอกปริมาณใกล้หมด = คำนวณวันจากยอดทั้งหมด (ไม่ต้องรอช่องนี้แล้ว เพราะ
    // ไม่มีช่องวันที่ให้ผู้ใช้กรอกเองอีก และ backend ต้องการวันที่เสมอ)
    if (amount <= 0) {
      setState(() {
        _selectedExpiryDate = null;
        _expireDateController.text = '';
      });
      return;
    }

    final threshold = double.tryParse(_thresholdController.text.trim()) ?? 0.0;

    // ถ้ายังไม่ได้เลือกวันนำเข้า ให้ใช้วันนี้เป็นฐานคำนวณไปก่อน
    DateTime startDate = _selectedImportDate ?? DateTime.now();

    // อัตราการกิน/ตัดสต็อกต่อวันจริงของประเภทที่เลือกไว้ (รวมจากจำนวนไก่จริง) -
    // ถ้ายังไม่ได้เลือกประเภท หรือยังไม่มีคอกกินอยู่เลย ใช้ค่าเผื่อไว้แทน
    final consumePerDay = (_selectedFoodType != null
            ? _dailyConsumptionByType[_selectedFoodType]
            : null) ??
        _fallbackConsumePerDay[_selectedFoodType] ??
        20.0;

    int daysLeft = 0;
    // ถ้าปริมาณอาหาร มากกว่าปริมาณแจ้งเตือน ถึงจะคำนวณวันได้
    if (amount > threshold) {
      // หาว่าใช้เวลากี่วันถึงจะลดไปถึงจุด threshold
      daysLeft = ((amount - threshold) / consumePerDay).ceil();
    }

    setState(() {
      // เอาวันที่เริ่มต้น + จำนวนวันที่อยู่ได้
      _selectedExpiryDate = startDate.add(Duration(days: daysLeft));

      // อัปเดตไปแสดงผลที่ช่อง TextField ของวันหมดอายุ
      int thaiYear = _selectedExpiryDate!.year + 543;
      String day = _selectedExpiryDate!.day.toString().padLeft(2, '0');
      String month = _selectedExpiryDate!.month.toString().padLeft(2, '0');
      _expireDateController.text = "$day / $month / $thaiYear";
    });
  }

  // 🌟 ฟังก์ชันส่งข้อมูลไปยัง API
  Future<void> _saveFoodData() async {
    // 🌟 เพิ่มสต็อกต้องยิงผ่าน /api/importfoods เท่านั้น (ฝั่ง backend จะบันทึกลง
    // importfood และบวกเพิ่มใน foodstock ให้อัตโนมัติ) — /api/foods รับแค่ GET/PUT/DELETE
    final url = Uri.parse('$backendBaseUrl/api/importfoods');

    if (_selectedFoodType == null) {
      showEzTopBanner(
        context,
        'กรุณาเลือกประเภทอาหาร',
        type: EzBannerType.warning,
      );
      return;
    }
    if (_selectedImportDate == null) {
      showEzTopBanner(
        context,
        'กรุณาเลือกวันที่นำอาหารเข้า',
        type: EzBannerType.warning,
      );
      return;
    }
    final double? enteredAmount = double.tryParse(
      _amountController.text.trim(),
    );
    if (_amountController.text.trim().isEmpty) {
      showEzTopBanner(
        context,
        'กรุณากรอกปริมาณที่นำเข้า',
        type: EzBannerType.warning,
      );
      return;
    }
    if (enteredAmount == null || enteredAmount <= 0) {
      showEzTopBanner(
        context,
        'กรุณากรอกปริมาณที่นำเข้าให้มากกว่า 0',
        type: EzBannerType.warning,
      );
      return;
    }
    // คำนวณวันที่ใกล้หมดอัตโนมัติจากปริมาณ (ผู้ใช้ไม่ต้องกรอกเอง) - ปริมาณ > 0
    // ผ่านการตรวจข้างบนแล้วจึงมีค่าเสมอ แต่กันไว้ก่อนส่งกรณีคำนวณยังไม่ทัน
    if (_selectedExpiryDate == null) _calculateExpiryDate();
    final expiryDate = _selectedExpiryDate ?? _selectedImportDate!;

    // ตั้งครั้งแรกเท่านั้น (ถ้าล็อกแล้วไม่ส่ง) และต้องมากกว่า 0
    final double? enteredThreshold = _minLocked
        ? null
        : double.tryParse(_thresholdController.text.trim());

    // กรอกปริมาณใกล้หมดเป็นครั้งแรก -> ถามยืนยันก่อน เพราะบันทึกแล้วแก้ไขไม่ได้
    final bool askThreshold = enteredThreshold != null && enteredThreshold > 0;
    if (askThreshold) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('ยืนยันปริมาณอาหารใกล้หมด'),
          content: Text(
            'ต้องการตั้งแจ้งเตือนเมื่อเหลือไม่เกิน ${_thresholdController.text.trim()} กก. ใช่ไหม\n\n'
            'ค่านี้ใช้กับอาหารทุกประเภท และเมื่อบันทึกแล้วจะแก้ไขไม่ได้',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('กลับไปแก้'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ยืนยันและบันทึก'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    // ให้เจ้าของฟาร์มทวนข้อมูลอีกรอบก่อนบันทึกจริง (ป็อบอัพกลาง widgets/ez_confirm_dialog.dart)
    // ถ้าเพิ่งกดยืนยันในป็อบอัพ "ปริมาณใกล้หมด" ด้านบนแล้ว ถือว่ายืนยันแล้ว ไม่ถามซ้ำ
    if (!askThreshold && !await showEzConfirm(context, message: 'ตรวจสอบข้อมูลการนำเข้าอาหารก่อนบันทึก', details: [
      'ประเภทอาหาร: ${_selectedFoodType ?? '-'}',
      'ปริมาณ: ${_amountController.text.trim()} กก.',
      'วันที่นำเข้า: ${ezConfirmDate(_selectedImportDate)}',
      'วันหมดอายุ: ${ezConfirmDate(_selectedExpiryDate)}',
    ])) return;
    if (!mounted) return;
    try {
      final response = await ApiClient.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "food_type": _selectedFoodType,
          // 🌟 import_volume เป็น int ฝั่ง backend (models.CreateImportFoodRequest)
          "import_volume": enteredAmount.round(),
          "expiry_date": expiryDate.toUtc().toIso8601String(),
          // ปริมาณที่เจ้าของฟาร์มกำหนดให้แจ้งเตือน "ใกล้หมด" ของประเภทนี้
          if (enteredThreshold != null && enteredThreshold > 0)
            "min_quantity": enteredThreshold,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        showEzTopBanner(
          context,
          'เพิ่มข้อมูลคลังอาหารสำเร็จ!',
          type: EzBannerType.success,
        );
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        showEzTopBanner(
          context,
          'บันทึกไม่สำเร็จ (${response.statusCode}): ${response.body}',
          type: EzBannerType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showEzTopBanner(
        context,
        'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e',
        type: EzBannerType.error,
      );
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
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Mainchicken()),
      );
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainShowDataFood()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ShowChart()),
      );
    } else {
      setState(() {
        selectedIndex = index;
      });
    }
  }

  // 🌟 ฟังก์ชันเปิดปฏิทินที่บันทึกค่าลงตัวแปร DateTime ด้วย
  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
    bool isImportDate,
  ) async {
    DateTime initialDate = DateTime.now();

    final DateTime? picked = await showEzDatePicker(
      context,
      initialDate: initialDate,
      helpText: 'เลือกวันที่',
    );

    if (picked != null) {
      setState(() {
        if (isImportDate) {
          _selectedImportDate = picked;
        } else {
          _selectedExpiryDate = picked;
        }

        int thaiYear = picked.year + 543;
        String day = picked.day.toString().padLeft(2, '0');
        String month = picked.month.toString().padLeft(2, '0');
        controller.text = "$day / $month / $thaiYear";

        // 🌟 ถ้าผู้ใช้เปลี่ยนวันนำเข้าใหม่ ให้คำนวณวันหมดอายุใหม่ด้วย
        if (isImportDate) {
          _calculateExpiryDate();
        }
      });
    }
  }

  /// การ์ดเลือกประเภทอาหาร — แตะเลือกได้ทันที ไม่ต้องเปิดดรอปดาวน์ (เร็วกว่า
  /// และเห็นช่วงอายุที่เหมาะกับแต่ละประเภทได้เลยโดยไม่ต้องเลือกก่อนถึงจะเห็น)
  Widget _buildFoodTypeChoice(
    EzColors ez, {
    required String value,
    required IconData icon,
    required double iconSize,
  }) {
    final bool selected = _selectedFoodType == value;
    return InkWell(
      onTap: () {
        setState(() => _selectedFoodType = value);
        // โหลดซ้ำตอนเลือกประเภท เผื่อโหลดตอนเปิดหน้าไม่สำเร็จ/ยังไม่เสร็จ (เติมเมื่อช่องว่างเท่านั้น)
        _fetchSavedThresholds();
        _calculateExpiryDate();
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? ez.gold.withValues(alpha: 0.12) : ez.inputFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? ez.gold : ez.border,
            width: selected ? 1.6 : 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: iconSize,
                  color: selected ? ez.gold : ez.textSecondary,
                ),
                const Spacer(),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected ? ez.gold : ez.border,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.kanit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: selected ? ez.gold : ez.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              foodTypeAgeHint(value),
              style: GoogleFonts.kanit(fontSize: 10.5, color: ez.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ez = ezColors(context);

    return Scaffold(
      extendBody: true,
      backgroundColor: ezBackgroundColor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const EzHeader(pageTitle: 'เพิ่มสต็อกอาหาร'),
              const SizedBox(height: 20),

              // ฟอร์มข้อมูลการนำเข้า — ใช้ช่องกรอกมาตรฐานเดียวกับหน้าอื่นในแอป
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: ezCardColor(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
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
                            Icons.inventory_2_outlined,
                            color: ez.gold,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'เพิ่มข้อมูลคลังอาหาร',
                                style: GoogleFonts.kanit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: ez.textPrimary,
                                ),
                              ),
                              Text(
                                'ช่องที่มี * ต้องกรอกให้ครบก่อนบันทึก',
                                style: GoogleFonts.kanit(
                                  fontSize: 10,
                                  color: ez.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Text.rich(
                      TextSpan(
                        text: 'ประเภทอาหาร',
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
                    const SizedBox(height: 8),
                    // ✅ IntrinsicHeight + stretch ให้การ์ดทั้ง 2 สูงเท่ากันเสมอ
                    // ไม่ว่าข้อความช่วงอายุของแต่ละประเภทจะขึ้นบรรทัดเดียวหรือ 2 บรรทัด
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildFoodTypeChoice(
                              ez,
                              value: kFoodTypeSmallPellet,
                              icon: Icons.grain,
                              iconSize: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildFoodTypeChoice(
                              ez,
                              value: kFoodTypeLargePellet,
                              icon: Icons.grain,
                              iconSize: 26,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    EzFormDateField(
                      label: 'วันที่นำอาหารเข้า',
                      isRequired: true,
                      controller: _dateReceivedController,
                      onTap: () =>
                          _selectDate(context, _dateReceivedController, true),
                    ),
                    const SizedBox(height: 12),
                    EzFormTextField(
                      label: 'ปริมาณที่นำเข้า',
                      isRequired: true,
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      hintText: 'เช่น 100',
                      suffixText: 'กก.',
                    ),
                    const SizedBox(height: 12),
                    EzFormTextField(
                      label: _minLocked
                          ? 'ปริมาณอาหารใกล้หมด 🔒'
                          : 'กำหนดปริมาณอาหารใกล้หมด',
                      controller: _thresholdController,
                      readOnly: _minLocked,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      hintText: 'เช่น 20 (ตั้งได้ครั้งเดียว)',
                      suffixText: 'กก.',
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        _minLocked
                            ? 'ตั้งไว้แล้วและล็อกไว้ แก้ไขไม่ได้ ใช้ค่านี้กับอาหารทุกประเภท'
                            : 'ใช้ร่วมกันทุกประเภท ตั้งได้ครั้งเดียว บันทึกแล้วแก้ไขไม่ได้',
                        style: GoogleFonts.kanit(
                          fontSize: 11,
                          color: ez.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveFoodData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6FE975),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'เข้าสต็อกอาหาร',
                    style: GoogleFonts.kanit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
