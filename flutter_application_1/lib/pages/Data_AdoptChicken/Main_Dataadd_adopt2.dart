import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/Main_SenSor/Main_DeviceSummary.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../bottombar.dart';
import '../../services/backend_config.dart';
import '../../widgets/ez_header.dart';
import '../../widgets/ez_form_field.dart';
import '../../widgets/ez_top_banner.dart';

class AddDataadopt extends StatefulWidget {
  const AddDataadopt({super.key});

  @override
  State<AddDataadopt> createState() => _AddDataadoptState();
}

class _AddDataadoptState extends State<AddDataadopt> {
  int? selectedIndex; // ไม่ใช่หน้าในแถบเมนูล่าง จึงไม่ไฮไลต์เมนูไหน

  final TextEditingController nameController = TextEditingController();
  final TextEditingController importDateController = TextEditingController();
  final TextEditingController countController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ตั้งค่าเริ่มต้นของวันที่นำเข้าเป็นวันนี้ (แสดงเป็น พ.ศ.)
    final today = DateTime.now();
    importDateController.text =
        "${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year + 543}";
  }

  // แปลงวันที่ให้ตรงกับที่ Backend (Go) ต้องการเป๊ะๆ
  String _toISO8601(String dateStr) {
    if (dateStr.isEmpty) return '';
    final parts = dateStr.split('/');
    if (parts.length != 3) return '';
    final day = parts[0].padLeft(2, '0');
    final month = parts[1].padLeft(2, '0');
    // ตัวควบคุมข้อความแสดงปี พ.ศ. (ดู importDateController/birthDateController)
    // ต้องแปลงกลับเป็น ค.ศ. ก่อนส่งให้ backend
    final buddhistYear = int.tryParse(parts[2]) ?? 0;
    final year = (buddhistYear - 543).toString();

    return '$year-$month-${day}T00:00:00Z';
  }

  void onTabSelected(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
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
    } else {
      setState(() {
        selectedIndex = index;
      });
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      helpText: 'เลือกวันที่',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
    );
    if (picked != null) {
      setState(() {
        controller.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year + 543}";
      });
    }
  }

  Future<void> _submitData() async {
    if (nameController.text.trim().isEmpty ||
        importDateController.text.isEmpty ||
        countController.text.isEmpty ||
        birthDateController.text.isEmpty) {
      showEzTopBanner(
        context,
        'กรุณากรอกชื่อคอกไก่, จำนวนไก่, วันนำเข้า และวันเกิดให้ครบ',
        type: EzBannerType.warning,
      );
      return;
    }

    final int? count = int.tryParse(countController.text.trim());
    if (count == null || count <= 0) {
      showEzTopBanner(
        context,
        'จำนวนไก่ต้องเป็นตัวเลขที่มากกว่า 0',
        type: EzBannerType.warning,
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF66E07A)),
      ),
    );

    try {
      final body = jsonEncode({
        "name_coop": nameController.text.trim(),
        "date_adopt_animals": _toISO8601(importDateController.text),
        "amount": count,
        "birthday": _toISO8601(birthDateController.text),
        "note": noteController.text.trim().isEmpty
            ? '-'
            : noteController.text.trim(),
      });

      debugPrint('POST /api/coops body: $body');
      final response = await http.post(
        Uri.parse('$backendBaseUrl/api/coops'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      Navigator.pop(context); // ปิด Dialog โหลด

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // ส่งกลับเป็น ISO เหมือนที่ backend ใช้ หน้ารายการจะได้ฟอร์แมตวันที่ต่อได้ถูก
        Map<String, String> newData = {
          "id":
              responseData["CoopID"]?.toString() ??
              responseData["coop_id"]?.toString() ??
              '',
          "name": nameController.text.trim(),
          "importDate": _toISO8601(importDateController.text),
          "count": "$count ตัว",
          "birthDate": _toISO8601(birthDateController.text),
          "note": noteController.text.isNotEmpty ? noteController.text : "-",
        };

        showEzTopBanner(
          context,
          'บันทึกข้อมูลสำเร็จ!',
          type: EzBannerType.success,
        );

        Navigator.pop(context, newData);
      } else {
        showEzTopBanner(
          context,
          'เกิดข้อผิดพลาด: ${response.statusCode} - ${response.body}',
          type: EzBannerType.error,
        );
      }
    } catch (e) {
      Navigator.pop(context); // ปิด Dialog โหลด
      showEzTopBanner(
        context,
        'ไม่สามารถเชื่อมต่อ Server ได้: $e',
        type: EzBannerType.error,
      );
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
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const EzHeader(pageTitle: 'เพิ่มคอกไก่'),
                const SizedBox(height: 20),

                // ฟอร์มข้อมูลไก่ — ใช้ช่องกรอกมาตรฐานเดียวกับหน้าอื่นในแอป
                Container(
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
                              Icons.pets_outlined,
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
                                  'ข้อมูลไก่',
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
                      EzFormTextField(
                        label: 'ชื่อคอกไก่',
                        isRequired: true,
                        controller: nameController,
                        hintText: 'เช่น ก้านกล้วย',
                      ),
                      const SizedBox(height: 12),
                      EzFormTextField(
                        label: 'จำนวนไก่',
                        isRequired: true,
                        controller: countController,
                        keyboardType: TextInputType.number,
                        hintText: 'เช่น 200',
                        suffixText: 'ตัว',
                      ),
                      const SizedBox(height: 12),
                      EzFormDateField(
                        label: 'วันนำเข้าไก่',
                        isRequired: true,
                        controller: importDateController,
                        onTap: () => _selectDate(context, importDateController),
                      ),
                      const SizedBox(height: 12),
                      EzFormDateField(
                        label: 'วันเกิดไก่',
                        isRequired: true,
                        controller: birthDateController,
                        onTap: () => _selectDate(context, birthDateController),
                      ),
                      const SizedBox(height: 12),
                      EzFormTextField(
                        label: 'หมายเหตุ',
                        controller: noteController,
                        hintText: 'รายละเอียดเพิ่มเติม',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // 🔹 ปุ่มบันทึก (เพิ่มคอก)
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _submitData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF66E07A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      'เพิ่มคอกไก่',
                      style: GoogleFonts.kanit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 100,
                ), // เว้นที่สำหรับ BottomNavigationBar
              ],
            ),
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
