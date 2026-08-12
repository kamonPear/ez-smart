import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:flutter_application_1/pages/number_for_Egg/Edit_NumberEggchicken_3.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../bottombar.dart';

class AddEgg extends StatefulWidget {
  final String? initialCoopId;

  const AddEgg({super.key, this.initialCoopId});

  @override
  State<AddEgg> createState() => _AddEggState();
}

class _AddEggState extends State<AddEgg> {
  int selectedIndex = 2;

  bool isMonthly = true;
  String selectedYear = DateTime.now().year.toString();

  bool isLoading = true;
  bool isSubmitting = false;

  int todayTotalEggs = 0;
  int yesterdayTotalEggs = 0;

  Map<String, List<double>> actualMonthlyData = {};
  List<String> availableYears = [];

  List<dynamic> eggHistoryList = [];
  List<dynamic> _rawEggData = [];

  final TextEditingController _eggCountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String? _selectedCoop;
  DateTime _selectedDate = DateTime.now();
  List<String> availableCoops = [];
  Map<String, String> _coopNames =
      {}; // ✅ แผนที่ coop_id -> ชื่อคอก สำหรับแสดงผล

  final String backendBaseUrl = "http://10.0.2.2:8080";

  @override
  void initState() {
    super.initState();
    _fetchCoops().then((_) {
      _fetchEggData();
    });
  }

  @override
  void dispose() {
    _eggCountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchCoops() async {
    try {
      final response = await http.get(Uri.parse('$backendBaseUrl/api/coops'));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        setState(() {
          availableCoops = data
              .map((item) => item['coop_id'].toString())
              .toSet()
              .toList();

          _coopNames = {
            for (var item in data)
              item['coop_id'].toString():
                  (item['name_coop']?.toString().trim().isNotEmpty == true)
                  ? item['name_coop'].toString()
                  : item['coop_id'].toString(),
          };

          if (widget.initialCoopId != null &&
              availableCoops.contains(widget.initialCoopId)) {
            _selectedCoop = widget.initialCoopId;
          } else if (availableCoops.isNotEmpty) {
            _selectedCoop = availableCoops.first;
          }
        });
      } else {
        debugPrint("Error fetching coops: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Connection error (coops): $e");
    }
  }

  Future<void> _fetchEggData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('$backendBaseUrl/api/eggs'));

      if (response.statusCode == 200) {
        _rawEggData = jsonDecode(response.body);
        _recalculateStats();
      } else {
        debugPrint("Error fetching eggs: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Connection error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _recalculateStats() {
    List<dynamic> data = _selectedCoop == null
        ? _rawEggData
        : _rawEggData
              .where((e) => e['coop_id']?.toString() == _selectedCoop)
              .toList();

    Map<String, List<double>> tempMonthlyData = {};

    int tempTodayTotal = 0;
    int tempYesterdayTotal = 0;
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));

    for (var item in data) {
      if (item['date_collect_egg'] == null) continue;

      DateTime date = DateTime.parse(item['date_collect_egg']).toLocal();
      String yearStr = date.year.toString();
      int monthIndex = date.month - 1;
      double amount = (item['number_egg'] ?? 0).toDouble();

      tempMonthlyData.putIfAbsent(yearStr, () => List.filled(12, 0.0));
      tempMonthlyData[yearStr]![monthIndex] += amount;

      DateTime itemDate = DateTime(date.year, date.month, date.day);
      if (itemDate == today) {
        tempTodayTotal += amount.toInt();
      } else if (itemDate == yesterday) {
        tempYesterdayTotal += amount.toInt();
      }
    }

    setState(() {
      actualMonthlyData = tempMonthlyData;
      availableYears = tempMonthlyData.keys.toList()..sort();

      todayTotalEggs = tempTodayTotal;
      yesterdayTotalEggs = tempYesterdayTotal;

      eggHistoryList = List.from(data.reversed);

      if (availableYears.isNotEmpty) {
        selectedYear = availableYears.last;
      } else {
        String currentYear = DateTime.now().year.toString();
        availableYears = [currentYear];
        actualMonthlyData[currentYear] = List.filled(12, 0.0);
        selectedYear = currentYear;
      }
    });
  }

  Future<void> _submitEggData() async {
    if (_selectedCoop == null) {
      _showSnackBar('กรุณาเลือกคอกไก่');
      return;
    }

    if (_eggCountController.text.trim().isEmpty) {
      _showSnackBar('กรุณากรอกจำนวนไข่');
      return;
    }

    int? eggCount = int.tryParse(_eggCountController.text.trim());
    if (eggCount == null || eggCount < 0) {
      _showSnackBar('กรุณากรอกตัวเลขจำนวนไข่ที่ถูกต้อง');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    DateTime now = DateTime.now();
    DateTime combinedDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      now.hour,
      now.minute,
    );

    Map<String, dynamic> payload = {
      "coop_id": int.parse(_selectedCoop!),
      "number_egg": eggCount,
      "date_collect_egg": combinedDate.toUtc().toIso8601String(),
      "note": _noteController.text.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse('$backendBaseUrl/api/eggs'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('บันทึกข้อมูลสำเร็จ', isSuccess: true);
        _eggCountController.clear();
        _noteController.clear();
        setState(() => _selectedDate = DateTime.now());
        _fetchEggData();
      } else {
        _showSnackBar(
          'เกิดข้อผิดพลาดในการบันทึก: Error ${response.statusCode}',
        );
      }
    } catch (e) {
      _showSnackBar('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้');
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  Future<void> _deleteEggData(int id) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.delete(
        Uri.parse('$backendBaseUrl/api/eggs?id=$id'),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _showSnackBar('ลบข้อมูลสำเร็จ', isSuccess: true);
        _fetchEggData();
      } else {
        _showSnackBar('เกิดข้อผิดพลาดในการลบ: Error ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้');
      debugPrint("Delete error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showDeleteConfirmDialog(int id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2933),
          title: Text(
            'ยืนยันการลบ',
            style: GoogleFonts.kanit(color: Colors.white),
          ),
          content: Text(
            'คุณแน่ใจหรือไม่ว่าต้องการลบข้อมูลนี้?',
            style: GoogleFonts.kanit(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'ยกเลิก',
                style: GoogleFonts.kanit(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                Navigator.pop(context);
                _deleteEggData(id);
              },
              child: Text(
                'ลบข้อมูล',
                style: GoogleFonts.kanit(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.kanit()),
        backgroundColor: isSuccess ? Colors.green : Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  double _calculateMaxY() {
    if (actualMonthlyData.isEmpty ||
        !actualMonthlyData.containsKey(selectedYear))
      return 100;

    double max = 0;
    if (isMonthly) {
      for (var val in actualMonthlyData[selectedYear]!) {
        if (val > max) max = val;
      }
    } else {
      for (var year in availableYears) {
        double yearlyTotal = actualMonthlyData[year]!.reduce((a, b) => a + b);
        if (yearlyTotal > max) max = yearlyTotal;
      }
    }
    return max > 0 ? max * 1.2 : 100;
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
    } else {
      setState(() {
        selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(minHeight: screenHeight),
          decoration: const BoxDecoration(
            color: Color(0xFF101820),
            image: DecorationImage(
              image: AssetImage('assets/images/chart.png'),
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 240),

              if (isLoading && actualMonthlyData.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(50.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Column(
                  children: [
                    _buildSummaryCard(),
                    _buildToggleSwitch(),
                    _buildRecordFormCard(),
                    _buildLineChartCard(),
                    _buildHistoryList(),
                  ],
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

  Widget _buildSummaryCard() {
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
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
      ),
    );
  }

  Widget _buildToggleSwitch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => isMonthly = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isMonthly
                          ? const Color(0xFFFF7B7B)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'เดือน',
                      style: GoogleFonts.kanit(
                        fontSize: 14,
                        color: isMonthly ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => isMonthly = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: !isMonthly
                          ? const Color(0xFFFF7B7B)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ปี',
                      style: GoogleFonts.kanit(
                        fontSize: 14,
                        color: !isMonthly ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordFormCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2933),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _buildCoopFieldRow(),
          const SizedBox(height: 12),
          _buildDateFieldRow(),
          const SizedBox(height: 12),
          _buildFormInputRow(
            'จำนวนไข่',
            _eggCountController,
            inputType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _buildFormInputRow('หมายเหตุ', _noteController, hint: '-'),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: isSubmitting ? null : _submitEggData,
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'บันทึกยอดเก็บไข่ไก่',
                          style: GoogleFonts.kanit(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoopFieldRow() {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            'ชื่อคอก',
            style: GoogleFonts.kanit(fontSize: 14, color: Colors.white),
          ),
        ),
        Expanded(
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF151C22),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: availableCoops.contains(_selectedCoop)
                    ? _selectedCoop
                    : null,
                isDense: true,
                isExpanded: true,
                dropdownColor: const Color(0xFF1F2933),
                hint: Text(
                  availableCoops.isEmpty ? 'กำลังโหลด..' : 'เลือกคอก',
                  style: GoogleFonts.kanit(color: Colors.white54, fontSize: 14),
                ),
                style: GoogleFonts.kanit(fontSize: 14, color: Colors.white),
                items: availableCoops.map((String val) {
                  return DropdownMenuItem<String>(
                    value: val,
                    child: Text(_coopNames[val] ?? val),
                  );
                }).toList(),
                onChanged: availableCoops.isEmpty
                    ? null
                    : (val) {
                        setState(() => _selectedCoop = val!);
                        _recalculateStats();
                      },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateFieldRow() {
    String formattedDate =
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            'วันที่',
            style: GoogleFonts.kanit(fontSize: 14, color: Colors.white),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: _pickDate,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF151C22),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      formattedDate,
                      style: GoogleFonts.kanit(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.white70,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
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

  Widget _buildFormInputRow(
    String label,
    TextEditingController controller, {
    String hint = '',
    TextInputType inputType = TextInputType.text,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.kanit(fontSize: 14, color: Colors.white),
          ),
        ),
        Expanded(
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF151C22),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
            ),
            child: TextField(
              controller: controller,
              keyboardType: inputType,
              style: GoogleFonts.kanit(color: Colors.white),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                isDense: true,
                hintText: hint,
                hintStyle: GoogleFonts.kanit(color: Colors.white54),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLineChartCard() {
    double chartMaxY = _calculateMaxY();
    int thaiYear = int.parse(selectedYear) + 543;

    List<double> currentData = isMonthly
        ? (actualMonthlyData[selectedYear] ?? List.filled(12, 0.0))
        : availableYears
              .map((y) => actualMonthlyData[y]!.reduce((a, b) => a + b))
              .toList();

    double minVal = currentData.where((v) => v > 0).isEmpty
        ? 0
        : currentData.where((v) => v > 0).reduce((a, b) => a < b ? a : b);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2933),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            _selectedCoop == null
                ? 'บันทึกการเก็บไข่รวมทุกคอก ปี $thaiYear'
                : 'บันทึกการเก็บไข่ของคอก ${_coopNames[_selectedCoop] ?? _selectedCoop} ปี $thaiYear',
            style: GoogleFonts.kanit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),

          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: chartMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.3),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.kanit(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.right,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        List<String> months = [
                          'ม.ค.',
                          'ก.พ.',
                          'มี.ค.',
                          'เม.ย.',
                          'พ.ค.',
                          'มิ.ย.',
                          'ก.ค.',
                          'ส.ค.',
                          'ก.ย.',
                          'ต.ค.',
                          'พ.ย.',
                          'ธ.ค.',
                        ];
                        String text = '';
                        if (isMonthly && value >= 0 && value < 12) {
                          text = months[value.toInt()];
                        } else if (!isMonthly &&
                            value >= 0 &&
                            value < availableYears.length) {
                          text = availableYears[value.toInt()];
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            text,
                            style: GoogleFonts.kanit(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      currentData.length,
                      (index) => FlSpot(index.toDouble(), currentData[index]),
                    ),
                    isCurved: false,
                    color: Colors.white,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        bool isLowest = spot.y == minVal && spot.y > 0;
                        return FlDotCirclePainter(
                          radius: 4,
                          color: isLowest ? Colors.red : Colors.greenAccent,
                          strokeWidth: 0,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (eggHistoryList.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2933),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                'ประวัติการบันทึก (ล่าสุด)',
                style: GoogleFonts.kanit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white24, thickness: 1),

          MediaQuery.removePadding(
            context: context,
            removeTop: true,
            removeBottom: true,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: eggHistoryList.length > 5 ? 5 : eggHistoryList.length,
              itemBuilder: (context, index) {
                var item = eggHistoryList[index];
                int id = item['id'] ?? item['egg_id'] ?? 0;
                int amount = item['number_egg'] ?? 0;
                String coopId = item['coop_id']?.toString() ?? '-';
                String coop = _coopNames[coopId] ?? coopId;

                String dateStr = item['date_collect_egg']?.toString() ?? '';
                String formattedDate = '';
                if (dateStr.isNotEmpty && dateStr.length >= 10) {
                  formattedDate = dateStr.substring(0, 10);
                }

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  visualDensity: const VisualDensity(
                    horizontal: 0,
                    vertical: -4,
                  ),
                  title: Text(
                    'คอกที่ $coop : $amount ฟอง',
                    style: GoogleFonts.kanit(color: Colors.white, fontSize: 15),
                  ),
                  subtitle: Text(
                    'วันที่: $formattedDate',
                    style: GoogleFonts.kanit(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.blueAccent,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditNumbereggchicken(
                                initialData: {
                                  'id': item['egg_id'] ?? item['id'],
                                  'date': item['date_collect_egg'],
                                  'count': item['number_egg'],
                                  'note': item['note'],
                                  'coop_id': item['coop_id'],
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _showDeleteConfirmDialog(id),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
