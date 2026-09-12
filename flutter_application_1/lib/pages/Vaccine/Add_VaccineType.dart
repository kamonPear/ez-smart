import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../../services/backend_config.dart';
import '../../widgets/ez_header.dart';
import '../../widgets/ez_form_field.dart';
import '../../widgets/ez_top_banner.dart';
import '../../utils/vaccine_methods.dart';

/// หน้าเพิ่ม "ประเภทวัคซีน/ยา" ใหม่เข้าไปในระบบ นอกเหนือจากที่ฟิกไว้เดิม
/// เพื่อให้เจ้าของฟาร์มกรอกยาชนิดอื่นที่ยังไม่มีในระบบได้เอง
/// บันทึกลงตาราง medicine_schedules ผ่าน POST /api/vaccines/schedule
class AddVaccineType extends StatefulWidget {
  const AddVaccineType({super.key});

  @override
  State<AddVaccineType> createState() => _AddVaccineTypeState();
}

class _AddVaccineTypeState extends State<AddVaccineType> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _minAgeController = TextEditingController();
  final TextEditingController _maxAgeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedMethod;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _minAgeController.dispose();
    _maxAgeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showEzTopBanner(context, 'กรุณากรอกชื่อยา/วัคซีน', type: EzBannerType.warning);
      return;
    }
    if (_selectedMethod == null) {
      showEzTopBanner(context, 'กรุณาเลือกวิธีการให้', type: EzBannerType.warning);
      return;
    }
    final minAge = int.tryParse(_minAgeController.text.trim());
    final maxAge = int.tryParse(_maxAgeController.text.trim());
    if (minAge == null || maxAge == null) {
      showEzTopBanner(context, 'กรุณากรอกช่วงอายุให้ครบถ้วน', type: EzBannerType.warning);
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
      final response = await http.post(
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
        showEzTopBanner(
          context,
          'บันทึกไม่สำเร็จ กรุณาลองใหม่อีกครั้ง',
          type: EzBannerType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showEzTopBanner(context, 'เชื่อมต่อ backend ไม่สำเร็จ', type: EzBannerType.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ez = ezColors(context);
    return Scaffold(
      backgroundColor: ezBackgroundColor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(),
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
                      hintText: 'เช่น นิวคาสเซิล, หลอดลมอักเสบ',
                    ),
                    const SizedBox(height: 12),
                    EzFormDropdown<String>(
                      label: 'วิธีการให้',
                      isRequired: true,
                      value: _selectedMethod,
                      hint: 'เลือกวิธีการให้',
                      items: kVaccineMethodOptions
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedMethod = val),
                    ),
                    const SizedBox(height: 12),
                    EzFormTextField(
                      label: 'อายุต่ำสุด',
                      isRequired: true,
                      controller: _minAgeController,
                      keyboardType: TextInputType.number,
                      hintText: 'เช่น 7',
                      suffixText: 'วัน',
                    ),
                    const SizedBox(height: 12),
                    EzFormTextField(
                      label: 'อายุสูงสุด',
                      isRequired: true,
                      controller: _maxAgeController,
                      keyboardType: TextInputType.number,
                      hintText: 'เช่น 14',
                      suffixText: 'วัน',
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
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
