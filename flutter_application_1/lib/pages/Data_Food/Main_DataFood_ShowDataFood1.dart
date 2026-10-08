import 'package:flutter/material.dart';
import 'dart:convert';
import '../../services/api_client.dart';

import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataAdd_Food1.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bottombar.dart';
import 'package:flutter_application_1/pages/Main_SenSor/Main_DeviceSummary.dart';
import 'Main_FoodTypeSummary.dart';
import '../../services/backend_config.dart';
import '../../utils/thai_date.dart';
import '../../widgets/ez_header.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../widgets/ez_top_banner.dart';

class MainShowDataFood extends StatefulWidget {
  const MainShowDataFood({super.key});

  @override
  State<MainShowDataFood> createState() => _MainShowDataFoodState();
}

class _MainShowDataFoodState extends State<MainShowDataFood> {
  int selectedIndex = 4;
  bool isLoading = true;

  // 🌟 สต็อกปัจจุบันแยกตามประเภทอาหาร (เม็ดเล็ก/เม็ดใหญ่ มียอดของตัวเอง)
  Map<String, dynamic>? _smallStock;
  Map<String, dynamic>? _largeStock;

  // ประเภทที่เลือกไว้ก่อนกดตัดสต็อก (ต้องเลือกก่อนเสมอ)
  String? _selectedDeductType;

  List<dynamic> foodHistory = [];
  // ประวัติ "นำเข้า" และ "นำออก/แจกจ่าย" แยกกล่องกันคนละกล่อง เรียงใหม่สุดก่อน
  List<Map<String, dynamic>> _importHistory = [];
  List<Map<String, dynamic>> _distributeHistory = [];

  // 🌟 ปริมาณอาหารที่แต่ละคอกกินโดยประมาณต่อวัน (คำนวณจากอายุไก่ -> ประเภทอาหาร
  // แล้วหารสัดส่วนยอดตัดสต็อกรายวันตามจำนวนไก่ในคอก)
  List<dynamic> coopConsumption = [];

  @override
  void initState() {
    super.initState();
    _fetchFoodData();
    _fetchFoodHistory();
    _fetchCoopConsumption();
  }

  Future<void> _fetchFoodData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiClient.get(Uri.parse('$backendBaseUrl/api/foods'));

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);
        final List<dynamic> rows = decodedData is List
            ? decodedData
            : (decodedData is Map<String, dynamic> ? [decodedData] : []);

        Map<String, dynamic>? small;
        Map<String, dynamic>? large;
        for (final row in rows) {
          if (row is! Map<String, dynamic>) continue;
          if (row['food_type'] == kFoodTypeSmallPellet) small = row;
          if (row['food_type'] == kFoodTypeLargePellet) large = row;
        }

        setState(() {
          _smallStock = small;
          _largeStock = large;
        });
      } else {
        _setEmptyFoodData();
      }
    } catch (e) {
      debugPrint("Connection error: $e");
      _setEmptyFoodData();
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _setEmptyFoodData() {
    setState(() {
      _smallStock = null;
      _largeStock = null;
    });
  }

  // ดึงทั้งประวัติ "นำเข้า" (importfood) และ "นำออก/แจกจ่าย" (food_distribution)
  // มารวมเป็นตารางเดียว เรียงตามวันที่ใหม่สุดก่อน ให้เห็นภาพรวมของอาหารทั้งเข้า-ออก
  Future<void> _fetchFoodHistory() async {
    try {
      final results = await Future.wait([
        ApiClient.get(Uri.parse('$backendBaseUrl/api/food_history')),
        ApiClient.get(Uri.parse('$backendBaseUrl/api/foods/distribution')),
      ]);

      List<dynamic> importRows = [];
      final importResp = results[0];
      if (importResp.statusCode == 200) {
        final decoded = json.decode(importResp.body);
        if (decoded is List) {
          importRows = decoded;
        } else if (decoded is Map && decoded.containsKey('data')) {
          importRows = decoded['data'];
        }
      } else {
        debugPrint("Error fetching history: ${importResp.statusCode}");
      }

      final List<Map<String, dynamic>> combined = [];
      for (final row in importRows) {
        final date = DateTime.tryParse(
          (row['import_date'] ?? row['created_at'] ?? '').toString(),
        )?.toLocal();
        if (date == null) continue;
        double amount = 0;
        if (row['import_volume'] != null && row['import_volume'] != 0) {
          amount = (row['import_volume'] as num).toDouble();
        } else if (row['quantity_current'] != null) {
          amount = (row['quantity_current'] as num).toDouble();
        }
        combined.add({
          'kind': 'import',
          'foodType': (row['food_type'] ?? '-').toString(),
          'amount': amount,
          'date': date,
        });
      }

      // นำออก/แจกจ่าย: หนึ่งครั้งที่กดตัดสต็อกจะได้หลายแถว (แถวละ 1 คอก) และในวันเดียวกัน
      // อาจมีการกดตัดสต็อกหลายครั้งด้วย (คนละเวลากันเป๊ะ) แต่ในตารางประวัติจะโชว์แค่
      // ระดับวันที่ (ไม่มีเวลา) จึงรวมยอดของทุกคอก+ทุกครั้งในวันเดียวกัน (แยกตามประเภท
      // อาหาร) เป็นแถวเดียว ไม่ให้ดูเหมือนมีรายการซ้ำวันที่กันหลายแถว
      final distResp = results[1];
      if (distResp.statusCode == 200) {
        final decoded = json.decode(distResp.body);
        if (decoded is List) {
          final Map<String, Map<String, dynamic>> grouped = {};
          for (final row in decoded) {
            final date = DateTime.tryParse(
              (row['distributed_at'] ?? '').toString(),
            )?.toLocal();
            if (date == null) continue;
            final foodType = (row['food_type'] ?? '-').toString();
            final dayKey =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            final key = '${foodType}_$dayKey';
            final kg = (row['kg_given'] as num?)?.toDouble() ?? 0.0;
            if (grouped.containsKey(key)) {
              grouped[key]!['amount'] =
                  (grouped[key]!['amount'] as double) + kg;
              if (date.isAfter(grouped[key]!['date'] as DateTime)) {
                grouped[key]!['date'] = date;
              }
            } else {
              grouped[key] = {
                'kind': 'distribute',
                'foodType': foodType,
                'amount': kg,
                'date': date,
              };
            }
          }
          combined.addAll(grouped.values);
        }
      } else {
        debugPrint(
          "Error fetching distribution history: ${distResp.statusCode}",
        );
      }

      int byDateDesc(Map<String, dynamic> a, Map<String, dynamic> b) =>
          (b['date'] as DateTime).compareTo(a['date'] as DateTime);

      final imports = combined.where((e) => e['kind'] == 'import').toList()
        ..sort(byDateDesc);
      final distributes =
          combined.where((e) => e['kind'] == 'distribute').toList()
            ..sort(byDateDesc);

      if (mounted) {
        setState(() {
          foodHistory = importRows;
          _importHistory = imports;
          _distributeHistory = distributes;
        });
      }
    } catch (e) {
      debugPrint("Connection error (History): $e");
    }
  }

  Future<void> _fetchCoopConsumption() async {
    try {
      final url = Uri.parse('$backendBaseUrl/api/foods/coop-consumption');
      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        if (decodedData is List) {
          setState(() {
            coopConsumption = decodedData;
          });
        }
      } else {
        debugPrint("Error fetching coop consumption: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Connection error (Coop consumption): $e");
    }
  }

  bool _isDeducting = false;

  // 🌟 ตัดสต็อก — ต้องเลือกประเภทอาหารก่อนเสมอ ยอดที่ตัดคำนวณอัตโนมัติจากจำนวนไก่
  // จริงในคอกที่กำลังกินอาหารประเภทนี้อยู่ (handlers.ComputeDailyFoodConsumption
  // ฝั่ง backend ตัวเดียวกับที่ Cron ใช้ตัดให้ทุกวันตอน 6 โมงเช้า) ไม่ต้องกรอกจำนวนเองทีละ
  // คอกอีกต่อไป - กดปุ่มเดียวจบ
  Future<void> _forceDeductStock() async {
    final String? foodType = _selectedDeductType;
    if (foodType == null) {
      showEzTopBanner(
        context,
        "กรุณาเลือกประเภทอาหารก่อนตัดสต็อก",
        type: EzBannerType.warning,
      );
      return;
    }
    if (_isSelectedDeductStockEmpty) {
      showEzTopBanner(
        context,
        "สต็อกอาหาร$foodTypeหมดแล้ว ไม่มีอะไรให้ตัด",
        type: EzBannerType.warning,
      );
      return;
    }

    setState(() => _isDeducting = true);
    try {
      final response = await ApiClient.post(
        Uri.parse('$backendBaseUrl/api/foodstocks/force-deduct'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: json.encode({'food_type': foodType}),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        // backend ตอบ 200 เสมอแม้ตัดไม่สำเร็จเพราะสต็อกไม่พอ (shortfall > 0) -
        // ต้องเช็คฟิลด์นี้เอง ไม่งั้นแบนเนอร์จะขึ้นเขียว/ติ๊กถูกทั้งที่จริงๆ ไม่ได้
        // ตัดอะไรเลย ดูเหมือนสำเร็จทั้งที่ไม่ใช่
        final shortfall = (decoded['shortfall'] as num?)?.toDouble() ?? 0;
        showEzTopBanner(
          context,
          (decoded['message'] as String?) ?? 'ตัดสต็อกสำเร็จ',
          type: shortfall > 0 ? EzBannerType.error : EzBannerType.success,
        );
        setState(() => _selectedDeductType = null);
        _fetchFoodData();
        _fetchFoodHistory();
      } else {
        showEzTopBanner(
          context,
          'ตัดสต็อกไม่สำเร็จ กรุณาลองใหม่อีกครั้ง',
          type: EzBannerType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showEzTopBanner(
        context,
        'เชื่อมต่อ backend ไม่สำเร็จ',
        type: EzBannerType.error,
      );
    } finally {
      if (mounted) setState(() => _isDeducting = false);
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return "0";
    double val = (amount as num).toDouble();
    if (val == val.toInt()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(2);
  }

  String _formatDateSimple(String? isoString) {
    return thaiDateFromIso(isoString);
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return "-";
    try {
      DateTime dt = DateTime.parse(isoString).toLocal();
      return "${thaiDate(dt)} เวลา ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} น.";
    } catch (e) {
      return "-";
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

  Widget _buildDarkCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ezCardColor(context),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  /// หัวข้อการ์ดแบบเดียวกับหน้าอื่นในแอป — ไอคอนวงกลม + ชื่อหัวข้อ + คำอธิบายสั้นๆ
  Widget _sectionHeader(IconData icon, String title, {String? subtitle}) {
    final ez = ezColors(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ez.gold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: ez.gold, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.kanit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ez.textPrimary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: GoogleFonts.kanit(
                    fontSize: 11,
                    color: ez.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// การ์ดย่อยแสดงยอดคงเหลือของอาหารประเภทหนึ่ง (เม็ดเล็ก/เม็ดใหญ่) ดีไซน์แบบ
  /// แดชบอร์ด: ไอคอนวงกลม + ป้ายสถานะ + ตัวเลขเด่น + เวลาที่อัปเดตล่าสุด
  Widget _buildTypeStockTile(
    String foodType,
    Map<String, dynamic>? data,
    IconData icon,
    double iconSize,
  ) {
    final ez = ezColors(context);
    final double quantity =
        (data?['quantity_current'] as num?)?.toDouble() ?? 0.0;
    final String amount = _formatAmount(data?['quantity_current']);
    final String lastUpdate = _formatDateTime(data?['date_up']);
    final bool isEmpty = data == null || quantity <= 0;
    final Color statusColor = isEmpty ? ez.danger : ez.accentGreen;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ez.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ez.border),
      ),
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
                child: Icon(icon, size: iconSize, color: ez.gold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isEmpty ? 'หมดแล้ว' : 'ปกติ',
                  style: GoogleFonts.kanit(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            foodType,
            style: GoogleFonts.kanit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ez.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              text: amount,
              style: GoogleFonts.kanit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ez.textPrimary,
              ),
              children: [
                TextSpan(
                  text: ' กก.',
                  style: GoogleFonts.kanit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: ez.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 11,
                color: ez.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  data == null ? 'ยังไม่มีข้อมูล' : lastUpdate,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.kanit(
                    fontSize: 9.5,
                    color: ez.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isStockEmpty(Map<String, dynamic>? stock) {
    final quantity = (stock?['quantity_current'] as num?)?.toDouble() ?? 0.0;
    return stock == null || quantity <= 0;
  }

  /// สต็อกของประเภทที่เลือกไว้ (ก่อนกดตัดสต็อก) ว่างเปล่าอยู่แล้วหรือไม่ - ใช้ปิด
  /// ปุ่ม "ตัดสต็อก" กันกดตัดของที่ไม่มีอยู่แล้ว
  bool get _isSelectedDeductStockEmpty {
    if (_selectedDeductType == kFoodTypeSmallPellet) {
      return _isStockEmpty(_smallStock);
    }
    if (_selectedDeductType == kFoodTypeLargePellet) {
      return _isStockEmpty(_largeStock);
    }
    return false;
  }

  /// ชิปเลือกประเภทอาหารก่อนตัดสต็อก — ต้องเลือกก่อนปุ่ม "ตัดสต็อก" จะรู้ว่าตัดยอดไหน
  Widget _buildTypeChoiceChip(String foodType) {
    final ez = ezColors(context);
    final bool selected = _selectedDeductType == foodType;
    final bool empty = _isStockEmpty(
      foodType == kFoodTypeSmallPellet ? _smallStock : _largeStock,
    );
    return InkWell(
      onTap: () => setState(() => _selectedDeductType = foodType),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? ez.gold.withValues(alpha: 0.15) : ez.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? ez.gold : ez.border, width: 1.3),
        ),
        child: Text(
          empty ? '$foodType (ยังไม่มีในสต็อก)' : foodType,
          style: GoogleFonts.kanit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? ez.gold : ez.textPrimary,
          ),
        ),
      ),
    );
  }

  /// ปุ่มหลัก (เข้าสต็อกอาหาร) — เต็มความกว้าง สีเขียว เด่นชัดว่าเป็นการกระทำหลัก
  Widget _buildPrimaryActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF67C269),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        label: Text(
          text,
          style: GoogleFonts.kanit(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// ปุ่มรอง (ตัดสต็อกแมนนวล / ลบข้อมูล) — แบบมีกรอบ น้ำหนักภาพเบากว่าปุ่มหลัก
  /// เพราะเป็นการกระทำที่ใช้ไม่บ่อยหรือมีผลกระทบสูง ไม่ควรเด่นเท่าปุ่มเพิ่มสต็อก
  Widget _buildSecondaryActionButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon, color: color, size: 18),
        label: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.kanit(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: color,
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
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: EzHeader(pageTitle: 'คลังอาหาร'),
              ),
            ),
          ),

          Positioned(
            top: 110,
            left: 0,
            right: 0,
            bottom: 80,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  if (isLoading)
                    Skeletonizer(
                      enabled: true,
                      child: Column(
                        children: [
                          _buildDarkCard(
                            child: Column(
                              children: [
                                Container(
                                  width: 220,
                                  height: 18,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  width: 200,
                                  height: 100,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                          _buildDarkCard(
                            child: Column(
                              children: List.generate(
                                3,
                                (_) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 16,
                                        color: Colors.grey,
                                      ),
                                      Container(
                                        width: 100,
                                        height: 16,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // การ์ดที่ 1: สรุปสต็อกปัจจุบัน — แยกยอดตามประเภทอาหาร
                    _buildDarkCard(
                      child: Column(
                        children: [
                          _sectionHeader(
                            Icons.inventory_2_outlined,
                            'สรุปสต็อกปัจจุบัน',
                            subtitle: 'แยกยอดตามประเภทอาหาร',
                          ),
                          const SizedBox(height: 18),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _buildTypeStockTile(
                                    kFoodTypeSmallPellet,
                                    _smallStock,
                                    Icons.grain,
                                    18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTypeStockTile(
                                    kFoodTypeLargePellet,
                                    _largeStock,
                                    Icons.grain,
                                    26,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // การ์ดที่ 1.5: สรุปผลอาหารแยกตามประเภท — คลิกประเภทไหนเพื่อดู
                    // รายละเอียดการกินอาหารของแต่ละคอกที่กินประเภทนั้น (คำนวณจากอายุไก่
                    // ในคอก -> ประเภทอาหาร แล้วหารสัดส่วนยอดตัดสต็อกรายวันตามจำนวนไก่)
                    // ใช้เทียบกับสุขภาพไก่/ผลไข่ของคอกนั้นได้ว่ากินเยอะ-น้อยผิดปกติไหม
                    _buildDarkCard(
                      child: Column(
                        children: [
                          _sectionHeader(
                            Icons.egg_alt_outlined,
                            'สรุปผลอาหารแต่ละประเภท',
                            subtitle: 'แตะประเภทเพื่อดูการกินอาหารของแต่ละคอก',
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildFoodTypeSummaryTile(
                                  kFoodTypeSmallPellet,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildFoodTypeSummaryTile(
                                  kFoodTypeLargePellet,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // การ์ดที่ 2: ประวัติการนำเข้า — แยกชัดจากยอดคงเหลือด้านบน
                    // (การ์ดแรกคือ "ยอดตอนนี้", การ์ดนี้คือ "ประวัติการนำเข้าทีละครั้ง")
                    _buildHistoryCard(
                      icon: Icons.arrow_downward_rounded,
                      title: 'ประวัติการนำเข้าอาหาร',
                      entries: _importHistory,
                    ),
                    _buildHistoryCard(
                      icon: Icons.arrow_upward_rounded,
                      title: 'ประวัติการนำออก/แจกจ่ายอาหาร',
                      entries: _distributeHistory,
                    ),

                    // การ์ดที่ 3: ตัดสต็อก — แยกกล่องออกจาก "เข้าสต็อกอาหาร" ด้านล่าง
                    // ชัดเจน (เดิมอยู่การ์ดเดียวกัน คั่นด้วยเส้นแบ่ง "การจัดการขั้นสูง"
                    // ดูเหมือนเป็นแค่ตัวเลือกย่อยของปุ่มเพิ่มสต็อก ทั้งที่เป็นคนละ
                    // การกระทำกัน)
                    _buildDarkCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _sectionHeader(
                            Icons.remove_circle_outline,
                            'ตัดสต็อกอาหาร',
                          ),
                          const SizedBox(height: 10),

                          Text(
                            'ระบบตัดสต็อกให้อัตโนมัติทุกวันตอน 6 โมงเช้าตามจำนวนไก่จริงอยู่แล้ว '
                            'เลือกประเภทแล้วกดปุ่มนี้ถ้าต้องการตัดสต็อกวันนี้ก่อนเวลา',
                            style: GoogleFonts.kanit(
                              fontSize: 11,
                              color: ezColors(context).textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTypeChoiceChip(
                                  kFoodTypeSmallPellet,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildTypeChoiceChip(
                                  kFoodTypeLargePellet,
                                ),
                              ),
                            ],
                          ),
                          if (_selectedDeductType != null &&
                              _isSelectedDeductStockEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'สต็อกอาหาร$_selectedDeductTypeหมดแล้ว ไม่มีอะไรให้ตัด',
                              style: GoogleFonts.kanit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFE53935),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              _buildSecondaryActionButton(
                                icon: Icons.remove_circle_outline,
                                text: _isDeducting
                                    ? 'กำลังตัดสต็อก...'
                                    : (_selectedDeductType == null
                                          ? 'ตัดสต็อก'
                                          : 'ตัดสต็อก${_selectedDeductType!}'),
                                color: const Color(0xFFFFA726),
                                onTap:
                                    (_isDeducting ||
                                        _selectedDeductType == null ||
                                        _isSelectedDeductStockEmpty)
                                    ? null
                                    : _forceDeductStock,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // การ์ดที่ 4: เข้าสต็อกอาหาร — อยู่ใต้การ์ดตัดสต็อก กล่องแยกกัน
                    _buildDarkCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _sectionHeader(
                            Icons.add_box_outlined,
                            'เข้าสต็อกอาหาร',
                          ),
                          const SizedBox(height: 14),

                          _buildPrimaryActionButton(
                            icon: Icons.add_circle_outline,
                            text: 'เข้าสต็อกอาหาร',
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MainaddDataFood(),
                                ),
                              );
                              _fetchFoodData();
                              _fetchFoodHistory();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ],
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

  /// การ์ดย่อยสรุปอาหารประเภทหนึ่ง — จำนวนคอกที่กินประเภทนี้
  /// แตะแล้วเปิดหน้ารายละเอียดแยกตามคอกของประเภทนั้น
  Widget _buildFoodTypeSummaryTile(String foodType) {
    final ez = ezColors(context);
    final int coopCount = coopConsumption
        .where((c) => c['food_type'] == foodType)
        .length;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MainFoodTypeSummary(initialFoodType: foodType),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ez.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ez.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              foodType,
              style: GoogleFonts.kanit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ez.gold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$coopCount คอก • ประมาณการจากอายุไก่ • ดูรายละเอียด',
              style: GoogleFonts.kanit(fontSize: 10, color: ez.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  /// กล่องประวัติ 1 กล่อง (นำเข้า หรือ นำออก แยกกันคนละกล่อง) — หัวตาราง 3 คอลัมน์
  /// ความกว้างตายตัว + รายการสูงตายตัวเลื่อนในตัวเอง ไม่ต้องเลื่อนทั้งหน้า
  Widget _buildHistoryCard({
    required IconData icon,
    required String title,
    required List<Map<String, dynamic>> entries,
  }) {
    return _buildDarkCard(
      child: Column(
        children: [
          _sectionHeader(
            icon,
            title,
            subtitle: 'ทั้งหมด ${entries.length} ครั้ง',
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  "ประเภท",
                  style: GoogleFonts.kanit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ezColors(context).textSecondary,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  "ปริมาณ (กก.)",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.kanit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ezColors(context).textSecondary,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  "วันที่",
                  textAlign: TextAlign.right,
                  style: GoogleFonts.kanit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ezColors(context).textSecondary,
                  ),
                ),
              ),
            ],
          ),
          Divider(color: ezColors(context).border, thickness: 1, height: 20),

          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "ไม่มีข้อมูลประวัติ",
                style: GoogleFonts.kanit(
                  color: ezColors(context).textSecondary,
                ),
              ),
            )
          else
            // ✅ กล่องสูงตายตัว เลื่อนดูในกล่องนี้เองถ้ารายการยาว
            // ไม่ต้องเลื่อนทั้งหน้าเวลามีประวัติเพิ่มขึ้นเรื่อยๆ
            SizedBox(
              height: 200,
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: entries.length,
                separatorBuilder: (_, __) => Divider(
                  color: ezColors(context).border,
                  thickness: 1,
                  height: 5,
                ),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _buildTableRow(
                    kind: entry['kind'] as String,
                    foodType: entry['foodType'] as String,
                    amount: entry['amount'] as double,
                    date: _formatDateSimple(
                      (entry['date'] as DateTime).toIso8601String(),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  /// แถวประวัติ 1 รายการ — [kind] "import" (นำเข้า, สีเขียว +) หรือ "distribute"
  /// (นำออก/แจกจ่าย, สีแดง -) ใช้ Expanded คอลัมน์ความกว้างตายตัวเท่ากับหัวตาราง
  /// เสมอ กันปัญหาคอลัมน์เอียงเวลาข้อความยาว-สั้นไม่เท่ากันในแต่ละแถว
  Widget _buildTableRow({
    required String kind,
    required String foodType,
    required double amount,
    required String date,
  }) {
    final ez = ezColors(context);
    final bool isImport = kind == 'import';
    final Color amountColor = isImport ? ez.accentGreen : ez.danger;
    final String sign = isImport ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isImport
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  size: 13,
                  color: amountColor,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    foodType,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.kanit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ez.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '$sign${amount.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              date,
              textAlign: TextAlign.right,
              style: GoogleFonts.kanit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ez.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
