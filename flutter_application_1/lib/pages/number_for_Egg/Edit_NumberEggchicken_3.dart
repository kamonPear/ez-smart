import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/Main_SenSor/Main_DeviceSummary.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../bottombar.dart';
import '../../services/backend_config.dart';
import '../../widgets/ez_header.dart';
import '../../widgets/ez_form_field.dart';
import '../../utils/thai_date.dart';
import '../../widgets/ez_top_banner.dart';

class EditNumbereggchicken extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const EditNumbereggchicken({super.key, required this.initialData});

  @override
  State<EditNumbereggchicken> createState() => _EditNumbereggchickenState();
}

class _EditNumbereggchickenState extends State<EditNumbereggchicken> {
  int? selectedIndex; // ไม่ใช่หน้าในแถบเมนูล่าง จึงไม่ไฮไลต์เมนูไหน

  late TextEditingController _eggIdController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late TextEditingController _dateController;

  String? _selectedCoopId;
  DateTime _selectedDate = DateTime.now();

  List<String> availableCoops = [];
  Map<String, String> _coopNames = {};

  @override
  void initState() {
    super.initState();
    _eggIdController = TextEditingController(
      text: widget.initialData['id']?.toString(),
    );

    _selectedCoopId = widget.initialData['coop_id']?.toString();
    _selectedDate =
        DateTime.tryParse(
          widget.initialData['date']?.toString() ?? '',
        )?.toLocal() ??
        DateTime.now();
    _dateController = TextEditingController(text: thaiDate(_selectedDate));

    String countText =
        widget.initialData['count']?.toString().replaceAll(' ฟอง', '') ?? '';
    _amountController = TextEditingController(text: countText);

    _noteController = TextEditingController(
      text: widget.initialData['note']?.toString(),
    );

    _fetchCoops();
  }

  Future<void> _fetchCoops() async {
    try {
      final response = await http.get(Uri.parse('$backendBaseUrl/api/coops'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          availableCoops = data
              .map((item) => (item['coop_id'] ?? item['id']).toString())
              .toSet()
              .toList();
          _coopNames = {
            for (var item in data)
              (item['coop_id'] ?? item['id']).toString():
                  (item['name_coop']?.toString().trim().isNotEmpty == true)
                  ? item['name_coop'].toString()
                  : (item['coop_id'] ?? item['id']).toString(),
          };
        });
      }
    } catch (e) {
      // เงียบไว้ได้ ถ้าดึงรายชื่อคอกไม่สำเร็จก็ยังโชว์เลขคอกแทนได้
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = thaiDate(picked);
      });
    }
  }

  @override
  void dispose() {
    _eggIdController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _noteController.dispose();
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

  Future<void> _updateEggData() async {
    if (_selectedCoopId == null) {
      showEzTopBanner(context, 'กรุณาเลือกคอก', type: EzBannerType.warning);
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
      String id = _eggIdController.text;

      // 🌟 ดักจับ ID หายเพื่อความปลอดภัย
      if (id.isEmpty || id == "null") {
        Navigator.of(context, rootNavigator: true).pop();
        showEzTopBanner(
          context,
          'ข้อผิดพลาด: ไม่พบ ID ของข้อมูล',
          type: EzBannerType.error,
        );
        return;
      }

      Map<String, dynamic> requestBody = {
        "coop_id": int.tryParse(_selectedCoopId!) ?? 0,
        // ✅ ส่งเฉพาะ "วันที่" ตรงๆ ไม่แปลงเป็น UTC (ป้องกันบั๊กวันที่ถอยหลัง 1 วัน
        // เพราะไทยอยู่ UTC+7 — เหมือนที่แก้ไว้แล้วในหน้าเพิ่มข้อมูลไข่)
        "date_collect_egg":
            '${_selectedDate.toIso8601String().split('T').first}T00:00:00Z',
        "number_egg": int.tryParse(_amountController.text.trim()) ?? 0,
        "note": _noteController.text,
      };

      final response = await http.put(
        Uri.parse('$backendBaseUrl/api/eggs?id=$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (response.statusCode == 200 || response.statusCode == 201) {
        showEzTopBanner(
          context,
          'อัปเดตข้อมูลสำเร็จ',
          type: EzBannerType.success,
        );
        Navigator.pop(context, true);
      } else {
        String errorMsg = 'เกิดข้อผิดพลาด (${response.statusCode})';
        try {
          var errorData = jsonDecode(response.body);
          if (errorData['error'] != null) {
            errorMsg = errorData['error'];
          } else if (errorData['message'] != null) {
            errorMsg = errorData['message'];
          } else {
            errorMsg = response.body;
          }
        } catch (_) {
          errorMsg = response.body.isNotEmpty ? response.body : errorMsg;
        }

        showEzTopBanner(
          context,
          'เซิร์ฟเวอร์ปฏิเสธ: $errorMsg',
          type: EzBannerType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      showEzTopBanner(
        context,
        'เชื่อมต่อเซิร์ฟเวอร์ล้มเหลว: $e',
        type: EzBannerType.error,
      );
    }
  }

  Widget _buildFormCard() {
    final ez = ezColors(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(18),
      decoration: ezCardDecoration(context, radius: 18),
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
                child: Icon(Icons.edit_note_rounded, color: ez.gold, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'แก้ไขข้อมูลการเก็บไข่',
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
            label: 'ชื่อคอก',
            isRequired: true,
            value: availableCoops.contains(_selectedCoopId)
                ? _selectedCoopId
                : null,
            hint: availableCoops.isEmpty ? 'กำลังโหลด..' : 'เลือกคอก',
            items: availableCoops.map((val) {
              return DropdownMenuItem<String>(
                value: val,
                child: Text(_coopNames[val] ?? val),
              );
            }).toList(),
            onChanged: (val) {
              if (val == null) return;
              setState(() => _selectedCoopId = val);
            },
          ),
          const SizedBox(height: 12),
          EzFormDateField(
            label: 'วันที่',
            isRequired: true,
            controller: _dateController,
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          EzFormTextField(
            label: 'จำนวนไข่',
            isRequired: true,
            controller: _amountController,
            keyboardType: TextInputType.number,
            hintText: 'เช่น 100',
            suffixText: 'ฟอง',
          ),
          const SizedBox(height: 12),
          EzFormTextField(
            label: 'หมายเหตุ',
            controller: _noteController,
            hintText: 'ไม่บังคับ',
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ezColors(context).accentGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () {
            if (_amountController.text.isEmpty) {
              showEzTopBanner(
                context,
                'กรุณากรอกจำนวนไข่',
                type: EzBannerType.warning,
              );
              return;
            }
            _updateEggData();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.feed_outlined, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                "บันทึกการแก้ไข",
                style: GoogleFonts.kanit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: ezBackgroundColor(context),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: EzHeader(pageTitle: 'แก้ไขข้อมูลไข่'),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildFormCard(),
                    const SizedBox(height: 6),
                    _buildSaveButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected,
      ),
    );
  }
}
