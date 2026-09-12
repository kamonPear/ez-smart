import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/Main_SenSor/Main_DeviceSummary.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../bottombar.dart';
import '../../services/backend_config.dart';
import '../../widgets/ez_header.dart';
import '../../widgets/ez_form_field.dart';
import '../../widgets/ez_top_banner.dart';

class EditDataAdoptchicken extends StatefulWidget {
  final Map<String, String> initialData;

  const EditDataAdoptchicken({super.key, required this.initialData});

  @override
  State<EditDataAdoptchicken> createState() => _EditDataAdoptchickenState();
}

class _EditDataAdoptchickenState extends State<EditDataAdoptchicken> {
  int? selectedIndex; // ไม่ใช่หน้าในแถบเมนูล่าง จึงไม่ไฮไลต์เมนูไหน

  late TextEditingController idController;
  late TextEditingController nameController;
  late TextEditingController importDateController;
  late TextEditingController countController;
  late TextEditingController birthDateController;
  late TextEditingController noteController;

  /// แปลงวันที่ ISO จาก backend เป็นข้อความ "วว / ดด / ปี พ.ศ." สำหรับแสดงในช่องกรอก
  String _isoToThaiInput(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final datePart = iso.split('T').first;
    if (datePart == '0001-01-01') return ''; // ค่าว่างที่ backend (Go) ส่งมา
    // ✅ อ่านปี-เดือน-วันตรงๆ จากสตริง ไม่ผ่าน DateTime.parse ที่มี offset
    // (เช่น "+07:00") เพราะจะถูกแปลงเป็น UTC ภายในจน .day ผิดไปวันนึง
    final parts = datePart.split('-');
    if (parts.length != 3) return '';
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return '';
    return '${day.toString().padLeft(2, '0')} / ${month.toString().padLeft(2, '0')} / ${year + 543}';
  }

  @override
  void initState() {
    super.initState();
    idController = TextEditingController(text: widget.initialData['id']);
    nameController = TextEditingController(text: widget.initialData['name']);
    importDateController = TextEditingController(
      text: _isoToThaiInput(widget.initialData['importDate']),
    );

    String countText =
        widget.initialData['count']?.replaceAll(' ตัว', '') ?? '';
    countController = TextEditingController(text: countText);

    birthDateController = TextEditingController(
      text: _isoToThaiInput(widget.initialData['birthDate']),
    );
    noteController = TextEditingController(text: widget.initialData['note']);
  }

  @override
  void dispose() {
    idController.dispose();
    nameController.dispose();
    importDateController.dispose();
    countController.dispose();
    birthDateController.dispose();
    noteController.dispose();
    super.dispose();
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

  // ปฏิทินแบบ Popup สำหรับวันเกิดไก่
  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    DateTime initialDate = DateTime.now();

    if (controller.text.isNotEmpty) {
      try {
        List<String> parts = controller.text.split(RegExp(r'\s*/\s*'));
        if (parts.length == 3) {
          int day = int.parse(parts[0].trim());
          int month = int.parse(parts[1].trim());
          int year = int.parse(parts[2].trim());
          if (year > 2500) year -= 543;
          initialDate = DateTime(year, month, day);
        }
      } catch (e) {
        initialDate = DateTime.now();
      }
    }

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
        int thaiYear = picked.year + 543;
        String day = picked.day.toString().padLeft(2, '0');
        String month = picked.month.toString().padLeft(2, '0');
        controller.text = "$day / $month / $thaiYear";
      });
    }
  }

  Future<void> _updateData() async {
    final String id = idController.text.trim();
    final String nameRaw = nameController.text.trim();
    final String importDateRaw = importDateController.text.trim();
    final String countRaw = countController.text.trim();
    final String birthDateRaw = birthDateController.text.trim();
    final String noteRaw = noteController.text.trim();

    String toISO8601(String dateStr) {
      if (dateStr.isEmpty) return '';
      final parts = dateStr.split(RegExp(r'\s*/\s*'));
      if (parts.length != 3) return '';
      final day = parts[0].padLeft(2, '0');
      final month = parts[1].padLeft(2, '0');
      int year = int.parse(parts[2]);
      if (year > 2500) year -= 543;
      return '$year-$month-${day}T00:00:00Z';
    }

    if (nameRaw.isEmpty ||
        countRaw.isEmpty ||
        importDateRaw.isEmpty ||
        birthDateRaw.isEmpty) {
      showEzTopBanner(
        context,
        'กรุณากรอกชื่อคอกไก่, จำนวนไก่, วันนำเข้า และวันเกิดให้ครบ',
      );
      return;
    }

    final int? amount = int.tryParse(countRaw);
    if (amount == null || amount <= 0) {
      showEzTopBanner(context, 'จำนวนไก่ต้องเป็นตัวเลขที่มากกว่า 0');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF6FE975)),
      ),
    );

    try {
      final body = jsonEncode({
        "name_coop": nameRaw,
        "date_adopt_animals": toISO8601(importDateRaw),
        "amount": amount,
        "birthday": toISO8601(birthDateRaw),
        "note": noteRaw.isEmpty ? "-" : noteRaw,
      });

      final response = await http.put(
        Uri.parse('$backendBaseUrl/api/coops?id=$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (response.statusCode == 200) {
        // ส่งกลับเป็น ISO เหมือนที่ backend ใช้ หน้ารายการจะได้ฟอร์แมตวันที่ต่อได้ถูก
        Map<String, String> updatedData = {
          "id": id,
          "name": nameRaw,
          "importDate": toISO8601(importDateRaw),
          "count": "$amount ตัว",
          "birthDate": toISO8601(birthDateRaw),
          "note": noteRaw.isEmpty ? "-" : noteRaw,
        };

        showEzTopBanner(
          context,
          'แก้ไขข้อมูลสำเร็จ',
          type: EzBannerType.success,
        );

        Navigator.pop(context, updatedData);
      } else {
        showEzTopBanner(
          context,
          'เกิดข้อผิดพลาดในการแก้ไข: ${response.statusCode}',
          type: EzBannerType.error,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      showEzTopBanner(
        context,
        'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $e',
        type: EzBannerType.error,
      );
    }
  }

  // --- Widget ส่วนประกอบ UI ใหม่ตามแบบในรูป ---

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
                const EzHeader(pageTitle: 'แก้ไขคอกไก่'),
                const SizedBox(height: 20),

                // ฟอร์มข้อมูลไก่ — ใช้ช่องกรอกมาตรฐานเดียวกับหน้าเพิ่มคอกไก่
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

                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _updateData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF66E07A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      'แก้ไขข้อมูลคอกไก่',
                      style: GoogleFonts.kanit(
                        fontSize: 22,
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
      ),
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected,
      ),
    );
  }
}
