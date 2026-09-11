import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataAdd_Food1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bottombar.dart';
import '../close_open_Door.dart';
import 'Main_EditData_ShowFood1.dart';
import 'Main_FoodTypeSummary.dart';
import '../../services/backend_config.dart';
import '../../utils/thai_date.dart';
import '../../widgets/ez_header.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../widgets/ez_top_banner.dart';
import '../../widgets/ez_confirm_dialog.dart';

class MainShowDataFood extends StatefulWidget {
  const MainShowDataFood({super.key});

  @override
  State<MainShowDataFood> createState() => _MainShowDataFoodState();
}

// จำนวน กก./วัน ที่ตัดออกจากสต็อกแต่ละประเภทตอนกดปุ่มตัดสต็อกแมนนวล (ต้องตรงกับฝั่ง backend)
const Map<String, int> kDailyDeductAmounts = {
  kFoodTypeSmallPellet: 20,
  kFoodTypeLargePellet: 30,
};

class _MainShowDataFoodState extends State<MainShowDataFood> {
  int selectedIndex = 4;
  bool isLoading = true;

  // 🌟 สต็อกปัจจุบันแยกตามประเภทอาหาร (เม็ดเล็ก/เม็ดใหญ่ มียอดของตัวเอง)
  Map<String, dynamic>? _smallStock;
  Map<String, dynamic>? _largeStock;

  // ประเภทที่เลือกไว้ก่อนกดตัดสต็อก (ต้องเลือกก่อนเสมอ)
  String? _selectedDeductType;

  List<dynamic> foodHistory = [];

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
      final response = await http.get(Uri.parse('$backendBaseUrl/api/foods'));

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

  Future<void> _fetchFoodHistory() async {
    try {
      final url = Uri.parse('$backendBaseUrl/api/food_history');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);

        if (decodedData is List) {
          setState(() {
            foodHistory = decodedData;
          });
        } else if (decodedData is Map && decodedData.containsKey('data')) {
          setState(() {
            foodHistory = decodedData['data'];
          });
        }
      } else {
        debugPrint("Error fetching history: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Connection error (History): $e");
    }
  }

  Future<void> _fetchCoopConsumption() async {
    try {
      final url = Uri.parse('$backendBaseUrl/api/foods/coop-consumption');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        if (decodedData is List) {
          setState(() {
            coopConsumption = decodedData;
          });
        }
      } else {
        debugPrint(
          "Error fetching coop consumption: ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint("Connection error (Coop consumption): $e");
    }
  }

  // 🌟 ตัดสต็อกแมนนวล — ต้องเลือกประเภทอาหารก่อนเสมอ
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

    final int amount = kDailyDeductAmounts[foodType] ?? 0;

    final bool confirm = await showEzConfirmDialog(
      context,
      title: 'ยืนยันการตัดสต็อก',
      message: 'คุณต้องการตัดสต็อกอาหาร$foodType $amount กิโลกรัม ใช่หรือไม่?',
      confirmText: 'ยืนยัน',
      icon: Icons.remove_circle_outline_rounded,
    );

    if (!confirm) return;

    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse('$backendBaseUrl/api/foodstocks/force-deduct');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"food_type": foodType}),
      );

      if (response.statusCode == 200) {
        showEzTopBanner(
          context,
          "ตัดสต็อก$foodType $amount กก. สำเร็จ!",
          type: EzBannerType.success,
        );
        await _fetchFoodData();
        await _fetchFoodHistory();
      } else {
        showEzTopBanner(
          context,
          "ตัดสต็อกไม่สำเร็จ (${response.statusCode})",
          type: EzBannerType.error,
        );
      }
    } catch (e) {
      debugPrint("Error deducting foodstock: $e");
      showEzTopBanner(
        context,
        "เกิดข้อผิดพลาดในการเชื่อมต่อ",
        type: EzBannerType.error,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
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

  /// การ์ดย่อยแสดงยอดคงเหลือของอาหารประเภทหนึ่ง (เม็ดเล็ก/เม็ดใหญ่)
  Widget _buildTypeStockTile(String foodType, Map<String, dynamic>? data) {
    final ez = ezColors(context);
    final String amount = _formatAmount(data?['quantity_current']);
    final String lastUpdate = _formatDateTime(data?['date_up']);

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
          Text(
            foodType,
            style: GoogleFonts.kanit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ez.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$amount กก.',
            style: GoogleFonts.kanit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: ez.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data == null ? 'ยังไม่มีข้อมูล' : 'อัปเดต $lastUpdate',
            style: GoogleFonts.kanit(fontSize: 10, color: ez.textSecondary),
          ),
        ],
      ),
    );
  }

  /// ชิปเลือกประเภทอาหารก่อนตัดสต็อก — ต้องเลือกก่อนปุ่ม "ตัดสต็อก" จะรู้ว่าตัดยอดไหน
  Widget _buildTypeChoiceChip(String foodType) {
    final ez = ezColors(context);
    final bool selected = _selectedDeductType == foodType;
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
          foodType,
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
    required VoidCallback onTap,
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
                          Row(
                            children: [
                              Expanded(
                                child: _buildTypeStockTile(
                                  kFoodTypeSmallPellet,
                                  _smallStock,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTypeStockTile(
                                  kFoodTypeLargePellet,
                                  _largeStock,
                                ),
                              ),
                            ],
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
                    _buildDarkCard(
                      child: Column(
                        children: [
                          _sectionHeader(
                            Icons.history_rounded,
                            'ประวัติการนำเข้าอาหาร',
                            subtitle: 'ทั้งหมด ${foodHistory.length} ครั้ง',
                          ),
                          const SizedBox(height: 14),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                "ประเภท",
                                style: GoogleFonts.kanit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: ezColors(context).textSecondary,
                                ),
                              ),
                              Text(
                                "ปริมาณ (กก.)",
                                style: GoogleFonts.kanit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: ezColors(context).textSecondary,
                                ),
                              ),
                              Text(
                                "วันที่นำอาหารเข้า",
                                style: GoogleFonts.kanit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: ezColors(context).textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Divider(
                            color: ezColors(context).border,
                            thickness: 1,
                            height: 20,
                          ),

                          if (foodHistory.isEmpty)
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
                            ...foodHistory.map((data) {
                              String amount = "0";
                              if (data['import_volume'] != null &&
                                  data['import_volume'] != 0) {
                                amount = data['import_volume'].toString();
                              } else if (data['quantity_current'] != null) {
                                amount = data['quantity_current'].toString();
                              }
                              String date = _formatDateSimple(
                                data['import_date'] ?? data['created_at'],
                              );
                              String type = (data['food_type'] ?? '-')
                                  .toString();
                              return _buildTableRow(type, amount, date);
                            }),
                        ],
                      ),
                    ),

                    // การ์ดที่ 3: การจัดการสต็อก — ปุ่มหลักเดียวสำหรับ "เพิ่มสต็อก"
                    // (เดิมมีฟอร์มกรอกปริมาณ+วันที่ซ้ำกับปุ่มนี้ ยิงไป API เดียวกัน
                    // แต่ขาดช่อง "ปริมาณใกล้หมด" ทำให้ดูเหมือนมี 2 ทางที่ทำเรื่องเดียวกัน
                    // จึงรวมเหลือทางเดียวที่ครบถ้วนกว่า)
                    _buildDarkCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _sectionHeader(
                            Icons.add_box_outlined,
                            'จัดการสต็อกอาหาร',
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

                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(color: ezColors(context).border),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text(
                                  'การจัดการขั้นสูง',
                                  style: GoogleFonts.kanit(
                                    fontSize: 11,
                                    color: ezColors(context).textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(color: ezColors(context).border),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Text(
                            'เลือกประเภทอาหารก่อนตัดสต็อก',
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
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              _buildSecondaryActionButton(
                                icon: Icons.remove_circle_outline,
                                text: _selectedDeductType == null
                                    ? 'ตัดสต็อก'
                                    : 'ตัดสต็อก${_selectedDeductType!} ${kDailyDeductAmounts[_selectedDeductType!]} กก.',
                                color: const Color(0xFFFFA726),
                                onTap: _forceDeductStock,
                              ),
                            ],
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

  /// การ์ดย่อยสรุปอาหารประเภทหนึ่ง — จำนวนคอกที่กินประเภทนี้ + ยอดรวม กก./วัน
  /// แตะแล้วเปิดหน้ารายละเอียดแยกตามคอกของประเภทนั้น
  Widget _buildFoodTypeSummaryTile(String foodType) {
    final ez = ezColors(context);
    final matching = coopConsumption.where(
      (c) => c['food_type'] == foodType,
    );
    final int coopCount = matching.length;
    final double totalKg = matching.fold<double>(
      0.0,
      (sum, c) => sum + ((c['estimated_kg_per_day'] ?? 0) as num).toDouble(),
    );

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
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: ez.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${totalKg.toStringAsFixed(1)} กก./วัน',
              style: GoogleFonts.kanit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ez.gold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$coopCount คอก • ดูรายละเอียด',
              style: GoogleFonts.kanit(fontSize: 10, color: ez.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(String foodType, String amount, String date) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                foodType,
                style: GoogleFonts.kanit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ezColors(context).textPrimary,
                ),
              ),
              Text(
                amount,
                style: GoogleFonts.kanit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ezColors(context).textPrimary,
                ),
              ),
              Text(
                date,
                style: GoogleFonts.kanit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ezColors(context).textPrimary,
                ),
              ),
            ],
          ),
        ),
        Divider(color: ezColors(context).border, thickness: 1, height: 5),
      ],
    );
  }
}
