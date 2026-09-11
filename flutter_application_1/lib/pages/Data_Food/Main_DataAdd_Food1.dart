import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../bottombar.dart';
import '../close_open_Door.dart';
import '../../widgets/ez_header.dart';
import '../../widgets/ez_form_field.dart';
import '../../services/backend_config.dart';
import '../../widgets/ez_top_banner.dart';

/// ประเภทอาหารที่รองรับ - ผูกกับช่วงอายุไก่ที่กินอาหารประเภทนั้น
const String kFoodTypeSmallPellet = 'เม็ดเล็ก';
const String kFoodTypeLargePellet = 'เม็ดใหญ่';

String foodTypeAgeHint(String? foodType) {
  switch (foodType) {
    case kFoodTypeSmallPellet:
      return 'สำหรับไก่อายุ 0-6 สัปดาห์';
    case kFoodTypeLargePellet:
      return 'สำหรับไก่อายุมากกว่า 6 สัปดาห์';
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

  @override
  void initState() {
    super.initState();
    // 🌟 ดักจับเหตุการณ์เมื่อผู้ใช้พิมพ์ปริมาณอาหารหรือปริมาณใกล้หมด ให้คำนวณวันอัตโนมัติ
    _amountController.addListener(_calculateExpiryDate);
    _thresholdController.addListener(_calculateExpiryDate);
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
  void _calculateExpiryDate() {
    // ถ้ายังไม่ได้เลือกวันนำเข้า ให้ใช้วันนี้เป็นฐานคำนวณไปก่อน
    DateTime startDate = _selectedImportDate ?? DateTime.now();

    double amount = double.tryParse(_amountController.text) ?? 0.0;
    double threshold = double.tryParse(_thresholdController.text) ?? 0.0;

    // อัตราการกิน/ตัดสต็อก ต่อวัน (20 กิโลกรัม)
    double consumePerDay = 20.0;

    if (amount > 0) {
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
    if (_amountController.text.trim().isEmpty) {
      showEzTopBanner(
        context,
        'กรุณากรอกปริมาณที่นำเข้า',
        type: EzBannerType.warning,
      );
      return;
    }
    if (_selectedExpiryDate == null) {
      showEzTopBanner(
        context,
        'กรุณาเลือกวันที่อาหารใกล้หมด',
        type: EzBannerType.warning,
      );
      return;
    }

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "food_type": _selectedFoodType,
          // 🌟 import_volume เป็น int ฝั่ง backend (models.CreateImportFoodRequest)
          "import_volume": (double.tryParse(_amountController.text) ?? 0.0)
              .round(),
          "expiry_date": _selectedExpiryDate!.toUtc().toIso8601String(),
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
        MaterialPageRoute(builder: (context) => const CloseOpenDoor()),
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

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      helpText: 'เลือกวันที่',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
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

                    EzFormDropdown<String>(
                      label: 'ประเภทอาหาร',
                      isRequired: true,
                      value: _selectedFoodType,
                      hint: 'เลือกประเภทอาหาร',
                      items: const [
                        DropdownMenuItem(
                          value: kFoodTypeSmallPellet,
                          child: Text(kFoodTypeSmallPellet),
                        ),
                        DropdownMenuItem(
                          value: kFoodTypeLargePellet,
                          child: Text(kFoodTypeLargePellet),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedFoodType = value;
                        });
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: kEzFormLabelWidth,
                        top: 4,
                      ),
                      child: Text(
                        foodTypeAgeHint(_selectedFoodType),
                        style: GoogleFonts.kanit(
                          fontSize: 11,
                          color: ez.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

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
                      label: 'กำหนดปริมาณใกล้หมด',
                      controller: _thresholdController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      hintText: 'เช่น 20',
                      suffixText: 'กก.',
                    ),
                    const SizedBox(height: 12),
                    EzFormDateField(
                      label: 'วันที่อาหารใกล้หมด',
                      isRequired: true,
                      controller: _expireDateController,
                      hintText: 'คำนวณอัตโนมัติจากปริมาณ',
                      // ยังคงปุ่มเปิดปฏิทินไว้ เผื่อแอดมินต้องการแก้ไขวันที่คำนวณอัตโนมัติ
                      onTap: () =>
                          _selectDate(context, _expireDateController, false),
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
