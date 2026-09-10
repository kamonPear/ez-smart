import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:flutter_application_1/pages/number_for_Egg/Edit_NumberEggchicken_3.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../bottombar.dart';
import '../../widgets/ez_header.dart';
import '../../widgets/ez_egg_chart.dart';
import '../../widgets/ez_form_field.dart';
import '../../utils/thai_date.dart';
import '../../widgets/ez_skeleton.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../services/backend_config.dart';
import '../../widgets/ez_top_banner.dart';

class AddEgg extends StatefulWidget {
  final String? initialCoopId;

  const AddEgg({super.key, this.initialCoopId});

  @override
  State<AddEgg> createState() => _AddEggState();
}

class _AddEggState extends State<AddEgg> {
  int? selectedIndex; // ไม่ใช่หน้าในแถบเมนูล่าง จึงไม่ไฮไลต์เมนูไหน

  bool isLoading = true;
  bool isSubmitting = false;

  int todayTotalEggs = 0;
  int yesterdayTotalEggs = 0;

  List<dynamic> eggHistoryList = [];
  List<dynamic> _rawEggData = [];

  final TextEditingController _eggCountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(
    text: thaiDate(DateTime.now()),
  );

  String? _selectedCoop;
  DateTime _selectedDate = DateTime.now();
  List<String> availableCoops = [];
  Map<String, String> _coopNames =
      {}; // ✅ แผนที่ coop_id -> ชื่อคอก สำหรับแสดงผล

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
    _dateController.dispose();
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
    List<dynamic> data = _recordsForSelectedCoop;

    int tempTodayTotal = 0;
    int tempYesterdayTotal = 0;
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));

    for (var item in data) {
      if (item['date_collect_egg'] == null) continue;

      DateTime date = DateTime.parse(item['date_collect_egg']).toLocal();
      double amount = (item['number_egg'] ?? 0).toDouble();

      DateTime itemDate = DateTime(date.year, date.month, date.day);
      if (itemDate == today) {
        tempTodayTotal += amount.toInt();
      } else if (itemDate == yesterday) {
        tempYesterdayTotal += amount.toInt();
      }
    }

    setState(() {
      todayTotalEggs = tempTodayTotal;
      yesterdayTotalEggs = tempYesterdayTotal;
      eggHistoryList = List.from(data.reversed);
    });
  }

  // ✅ ข้อมูลไข่ดิบที่กรองตามคอกที่เลือกแล้ว ใช้ทั้งสรุปยอด/ประวัติ/กราฟ
  List<dynamic> get _recordsForSelectedCoop => _selectedCoop == null
      ? _rawEggData
      : _rawEggData
            .where((e) => e['coop_id']?.toString() == _selectedCoop)
            .toList();

  Future<void> _submitEggData() async {
    if (_selectedCoop == null) {
      _showBanner('กรุณาเลือกคอกไก่');
      return;
    }

    if (_eggCountController.text.trim().isEmpty) {
      _showBanner('กรุณากรอกจำนวนไข่');
      return;
    }

    int? eggCount = int.tryParse(_eggCountController.text.trim());
    if (eggCount == null || eggCount < 0) {
      _showBanner('กรุณากรอกตัวเลขจำนวนไข่ที่ถูกต้อง');
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
        _showBanner('บันทึกข้อมูลสำเร็จ', type: EzBannerType.success);
        _eggCountController.clear();
        _noteController.clear();
        setState(() {
          _selectedDate = DateTime.now();
          _dateController.text = thaiDate(_selectedDate);
        });
        _fetchEggData();
      } else {
        _showBanner(
          'เกิดข้อผิดพลาดในการบันทึก: Error ${response.statusCode}',
          type: EzBannerType.error,
        );
      }
    } catch (e) {
      _showBanner('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้', type: EzBannerType.error);
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  void _showBanner(String message, {EzBannerType type = EzBannerType.warning}) {
    showEzTopBanner(context, message, type: type);
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
      backgroundColor: ezBackgroundColor(context),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(minHeight: screenHeight),
            child: Column(
              children: [
                const EzHeader(pageTitle: 'บันทึกการเก็บไข่'),
                const SizedBox(height: 20),

                if (isLoading && _rawEggData.isEmpty)
                  Skeletonizer(
                    enabled: true,
                    child: Column(
                      children: [
                        _buildSummaryCard(),
                        _buildRecordFormCard(),
                        _buildEggChart(),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: EzSkeletonList(count: 3, itemHeight: 64),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      _buildSummaryCard(),
                      _buildRecordFormCard(),
                      _buildEggChart(),
                      _buildHistoryList(),
                    ],
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

  Widget _buildSummaryCard() {
    final ez = ezColors(context);
    String formatNum(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

    int diff = todayTotalEggs - yesterdayTotalEggs;
    bool isUp = diff > 0;
    bool isDown = diff < 0;

    Color trendBg = isUp
        ? ez.chipGreenBg
        : (isDown ? ez.danger.withValues(alpha: 0.15) : ez.chipDarkBg);
    Color trendFg = isUp
        ? ez.chipGreenText
        : (isDown ? ez.danger : ez.chipDarkText);
    IconData trendIcon = isUp
        ? Icons.arrow_upward_rounded
        : (isDown ? Icons.arrow_downward_rounded : Icons.remove_rounded);
    String trendLabel = isUp
        ? 'เพิ่มขึ้น ${formatNum(diff)} ฟอง'
        : (isDown ? 'ลดลง ${formatNum(diff.abs())} ฟอง' : 'เท่ากับเมื่อวาน');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(18),
      decoration: ezCardDecoration(context, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ez.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.egg_rounded, color: ez.gold, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ไข่ที่เก็บวันนี้',
                      style: GoogleFonts.kanit(
                        fontSize: 12,
                        color: ez.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatNum(todayTotalEggs)} ฟอง',
                      style: GoogleFonts.kanit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: ez.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: trendBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trendIcon, size: 14, color: trendFg),
                    const SizedBox(width: 4),
                    Text(
                      trendLabel,
                      style: GoogleFonts.kanit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: trendFg,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'เมื่อวานเก็บได้ ${formatNum(yesterdayTotalEggs)} ฟอง',
            style: GoogleFonts.kanit(fontSize: 12, color: ez.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordFormCard() {
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
                      'บันทึกยอดเก็บไข่',
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
            value: availableCoops.contains(_selectedCoop)
                ? _selectedCoop
                : null,
            hint: availableCoops.isEmpty ? 'กำลังโหลด..' : 'เลือกคอก',
            items: availableCoops.map((String val) {
              return DropdownMenuItem<String>(
                value: val,
                child: Text(_coopNames[val] ?? val),
              );
            }).toList(),
            onChanged: (val) {
              if (val == null) return;
              setState(() => _selectedCoop = val);
              _recalculateStats();
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
            controller: _eggCountController,
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
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ez.accentGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
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

  Widget _buildEggChart() {
    String coopLabel = _selectedCoop == null
        ? 'ทุกคอก'
        : (_coopNames[_selectedCoop] ?? _selectedCoop!);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: EzEggMultiChart(
        coopLabel: coopLabel,
        records: _recordsForSelectedCoop,
      ),
    );
  }

  Widget _buildHistoryList() {
    if (eggHistoryList.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: ezCardColor(context),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                color: ezColors(context).textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'ประวัติการบันทึก (ล่าสุด)',
                style: GoogleFonts.kanit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ezColors(context).textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: ezColors(context).border, thickness: 1),

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
                int amount = item['number_egg'] ?? 0;
                String coopId = item['coop_id']?.toString() ?? '-';
                String coop = _coopNames[coopId] ?? coopId;

                String formattedDate = thaiDateFromIso(
                  item['date_collect_egg']?.toString(),
                  fallback: '',
                );

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  visualDensity: const VisualDensity(
                    horizontal: 0,
                    vertical: -4,
                  ),
                  title: Text(
                    'คอกที่ $coop : $amount ฟอง',
                    style: GoogleFonts.kanit(
                      color: ezColors(context).textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    'วันที่: $formattedDate',
                    style: GoogleFonts.kanit(
                      color: ezColors(context).textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  trailing: IconButton(
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
