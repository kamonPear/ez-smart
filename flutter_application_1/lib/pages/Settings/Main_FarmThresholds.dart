import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/Main_SenSor/Main_DeviceSummary.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import '../bottombar.dart';
import '../../widgets/ez_header.dart';
import '../../widgets/ez_gauge.dart';
import '../../widgets/ez_top_banner.dart';
import '../../theme/farm_settings.dart';

/// หน้าตั้งค่าอุณหภูมิ/แอมโมเนียมาตรฐาน ที่ใช้ร่วมกันทุกคอกในฟาร์ม (ข้อ 1.3.2.2, 1.3.2.3)
class MainFarmThresholds extends StatefulWidget {
  const MainFarmThresholds({super.key});

  @override
  State<MainFarmThresholds> createState() => _MainFarmThresholdsState();
}

class _MainFarmThresholdsState extends State<MainFarmThresholds> {
  int? selectedIndex; // ไม่ใช่หน้าในแถบเมนูล่าง จึงไม่ไฮไลต์เมนูไหน

  late double _temp;
  late double _ammonia;

  static const double _tempMin = 10, _tempMax = 45;
  static const double _ammoniaMin = 0, _ammoniaMax = 100;

  @override
  void initState() {
    super.initState();
    _temp = farmThresholdController.temperature;
    _ammonia = farmThresholdController.ammonia;
  }

  void _saveAndExit() {
    farmThresholdController.save(temperature: _temp, ammonia: _ammonia);
    showEzTopBanner(
      context,
      'บันทึกค่ามาตรฐานสำเร็จ',
      type: EzBannerType.success,
    );
    Navigator.pop(context);
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Mainchicken()),
      );
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainShowDataFood()),
      );
    } else {
      setState(() {
        selectedIndex = index;
      });
    }
  }

  Widget _buildStepperField({
    required String label,
    required double value,
    required String unit,
    required double min,
    required double max,
    required double step,
    required ValueChanged<double> onChanged,
  }) {
    final ez = ezColors(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.kanit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: ez.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: ez.inputFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ez.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: value > min
                    ? () => onChanged((value - step).clamp(min, max))
                    : null,
                icon: Icon(Icons.remove_circle_outline, color: ez.gold),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: value.toStringAsFixed(0),
                      style: GoogleFonts.kanit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ez.textPrimary,
                      ),
                    ),
                    TextSpan(
                      text: ' $unit',
                      style: GoogleFonts.kanit(
                        fontSize: 13,
                        color: ez.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: value < max
                    ? () => onChanged((value + step).clamp(min, max))
                    : null,
                icon: Icon(Icons.add_circle_outline, color: ez.gold),
              ),
            ],
          ),
        ),
      ],
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
              const EzHeader(pageTitle: 'ค่ามาตรฐานทุกคอก'),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: ezCardDecoration(context, radius: 20),
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
                            Icons.tune_rounded,
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
                                'ค่าที่ใช้ร่วมกันทุกคอก',
                                style: GoogleFonts.kanit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: ez.textPrimary,
                                ),
                              ),
                              Text(
                                'มีผลกับทุกคอกไก่ทันทีหลังบันทึก',
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
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        EzGaugeCard(
                          icon: Icons.thermostat_outlined,
                          value: _temp.toStringAsFixed(0),
                          unit: '°',
                          subTitle: 'อุณหภูมิเป้าหมาย',
                          color: Colors.cyan,
                          percent: (_temp / 50).clamp(0, 1),
                        ),
                        EzGaugeCard(
                          icon: Icons.air_outlined,
                          value: _ammonia.toStringAsFixed(0),
                          unit: 'PPM',
                          subTitle: 'แอมโมเนียเป้าหมาย',
                          color: Colors.orange.shade800,
                          percent: (_ammonia / 100).clamp(0, 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: ezCardDecoration(context, radius: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepperField(
                      label: 'อุณหภูมิมาตรฐาน',
                      value: _temp,
                      unit: '°C',
                      min: _tempMin,
                      max: _tempMax,
                      step: 1,
                      onChanged: (v) => setState(() => _temp = v),
                    ),
                    const SizedBox(height: 16),
                    _buildStepperField(
                      label: 'ปริมาณแอมโมเนียมาตรฐาน',
                      value: _ammonia,
                      unit: 'PPM',
                      min: _ammoniaMin,
                      max: _ammoniaMax,
                      step: 1,
                      onChanged: (v) => setState(() => _ammonia = v),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: ez.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 15,
                            color: ez.gold,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ค่านี้เป็นค่ากลาง ใช้เทียบกับทุกคอกในฟาร์ม ไม่ใช่ค่าเฉพาะคอกใดคอกหนึ่ง',
                              style: GoogleFonts.kanit(
                                fontSize: 11.5,
                                color: ez.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              side: BorderSide(color: ez.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'ยกเลิก',
                              style: GoogleFonts.kanit(
                                color: ez.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ez.accentGreen,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _saveAndExit,
                            child: Text(
                              'บันทึกค่ามาตรฐาน',
                              style: GoogleFonts.kanit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
