import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../bottombar.dart';
import '../../services/backend_config.dart';

class EditNumbereggchicken extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const EditNumbereggchicken({super.key, required this.initialData});

  @override
  State<EditNumbereggchicken> createState() => _EditNumbereggchickenState();
}

class _EditNumbereggchickenState extends State<EditNumbereggchicken> {
  int selectedIndex = 0;

  late TextEditingController _eggIdController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  String? _selectedCoopId;
  DateTime _selectedDate = DateTime.now();

  List<String> availableCoops = [];
  Map<String, String> _coopNames = {};
  List<dynamic> _rawEggData = [];

  int todayTotalEggs = 0;
  int yesterdayTotalEggs = 0;

  @override
  void initState() {
    super.initState();
    _eggIdController = TextEditingController(
      text: widget.initialData['id']?.toString(),
    );

    _selectedCoopId = widget.initialData['coop_id']?.toString();
    _selectedDate =
        DateTime.tryParse(widget.initialData['date']?.toString() ?? '') ??
        DateTime.now();

    String countText =
        widget.initialData['count']?.toString().replaceAll(' ฟอง', '') ?? '';
    _amountController = TextEditingController(text: countText);

    _noteController = TextEditingController(
      text: widget.initialData['note']?.toString(),
    );

    _fetchCoops();
    _fetchEggSummary();
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

  Future<void> _fetchEggSummary() async {
    try {
      final response = await http.get(Uri.parse('$backendBaseUrl/api/eggs'));
      if (response.statusCode == 200) {
        _rawEggData = jsonDecode(response.body);
        _recalculateSummary();
      }
    } catch (e) {
      // เงียบไว้ได้ ถ้าดึงยอดสรุปไม่สำเร็จ
    }
  }

  void _recalculateSummary() {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));

    int tempToday = 0;
    int tempYesterday = 0;

    for (var item in _rawEggData) {
      if (_selectedCoopId != null &&
          item['coop_id']?.toString() != _selectedCoopId) {
        continue;
      }
      if (item['date_collect_egg'] == null) continue;

      DateTime date = DateTime.parse(item['date_collect_egg']).toLocal();
      DateTime itemDate = DateTime(date.year, date.month, date.day);
      int amount = (item['number_egg'] as num?)?.toInt() ?? 0;

      if (itemDate == today) {
        tempToday += amount;
      } else if (itemDate == yesterday) {
        tempYesterday += amount;
      }
    }

    if (!mounted) return;
    setState(() {
      todayTotalEggs = tempToday;
      yesterdayTotalEggs = tempYesterday;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  void dispose() {
    _eggIdController.dispose();
    _amountController.dispose();
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
        MaterialPageRoute(builder: (context) => const CloseOpenDoor()),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาเลือกคอก', style: GoogleFonts.kanit()),
          backgroundColor: Colors.red,
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ข้อผิดพลาด: ไม่พบ ID ของข้อมูล',
              style: GoogleFonts.kanit(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Map<String, dynamic> requestBody = {
        "coop_id": int.tryParse(_selectedCoopId!) ?? 0,
        "date_collect_egg": _selectedDate.toUtc().toIso8601String(),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('อัปเดตข้อมูลสำเร็จ', style: GoogleFonts.kanit()),
            backgroundColor: Colors.green,
          ),
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'เซิร์ฟเวอร์ปฏิเสธ: $errorMsg',
              style: GoogleFonts.kanit(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'เชื่อมต่อเซิร์ฟเวอร์ล้มเหลว: $e',
            style: GoogleFonts.kanit(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDarkTextFieldRow({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0, left: 20, right: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.kanit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF151C22),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blueAccent.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                style: GoogleFonts.kanit(fontSize: 15, color: Colors.white),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  isDense: true,
                  hintStyle: GoogleFonts.kanit(color: Colors.white54),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    String formatNum(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

    bool isUp = todayTotalEggs > yesterdayTotalEggs;
    bool isEqual = todayTotalEggs == yesterdayTotalEggs;

    IconData trendIcon = isEqual
        ? Icons.remove
        : (isUp ? Icons.arrow_upward : Icons.arrow_downward);
    Color trendColor = isEqual
        ? Colors.white54
        : (isUp ? const Color(0xFF4ADE80) : Colors.redAccent);

    return Column(
      children: [
        const Icon(Icons.egg_outlined, color: Color(0xFFFDE68A), size: 46),
        const SizedBox(height: 10),
        Text(
          'วันนี้ : ${formatNum(todayTotalEggs)} ฟอง',
          style: GoogleFonts.kanit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(trendIcon, color: trendColor, size: 16),
            const SizedBox(width: 4),
            Text(
              'เมื่อวาน : ${formatNum(yesterdayTotalEggs)} ฟอง',
              style: GoogleFonts.kanit(fontSize: 13, color: trendColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCoopFieldRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0, left: 20, right: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              'เลือกคอก',
              style: GoogleFonts.kanit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: const Color(0xFF151C22),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blueAccent.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: availableCoops.contains(_selectedCoopId)
                      ? _selectedCoopId
                      : null,
                  isDense: true,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1F2933),
                  hint: Text(
                    availableCoops.isEmpty ? 'กำลังโหลด..' : 'เลือกคอก',
                    style: GoogleFonts.kanit(
                      color: Colors.white54,
                      fontSize: 15,
                    ),
                  ),
                  style: GoogleFonts.kanit(fontSize: 15, color: Colors.white),
                  items: availableCoops.map((val) {
                    return DropdownMenuItem<String>(
                      value: val,
                      child: Text(_coopNames[val] ?? val),
                    );
                  }).toList(),
                  onChanged: availableCoops.isEmpty
                      ? null
                      : (val) {
                          setState(() => _selectedCoopId = val);
                          _recalculateSummary();
                        },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFieldRow() {
    String formattedDate =
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0, left: 20, right: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              'วันที่',
              style: GoogleFonts.kanit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _pickDate,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFF151C22),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blueAccent.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: GoogleFonts.kanit(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF43A047),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: () {
          if (_amountController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('กรุณากรอกจำนวนไข่', style: GoogleFonts.kanit()),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          _updateEggData();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.feed_outlined, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Text(
              "บันทึกการแก้ไข",
              style: GoogleFonts.kanit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Stack(
        children: [
          // 1. ภาพพื้นหลังเดิมของคุณ
          Container(
            height: screenHeight,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/egg.png'),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),

          // 2. เนื้อหาหน้าจัดให้อยู่ตรงกลางหน้าจอ
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 40,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSummary(),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 25),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2933),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildCoopFieldRow(),
                          _buildDateFieldRow(),
                          _buildDarkTextFieldRow(
                            label: "จำนวนไข่",
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                          ),
                          _buildDarkTextFieldRow(
                            label: "หมายเหตุ",
                            controller: _noteController,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: CustomBottomBar(
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected,
      ),
    );
  }
}
