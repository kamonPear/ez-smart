import 'package:flutter/material.dart';
import 'dart:convert';
import '../../services/api_client.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../services/backend_config.dart';
import '../../utils/thai_date.dart';
import '../../widgets/ez_header.dart';
import 'Main_DataAdd_Food1.dart';
import '../bottombar.dart';
import '../main_dash.dart';
import '../Data_AdoptChicken/Main_DataChicken_2.dart';
import 'Main_DataFood_ShowDataFood1.dart';
import '../Main_SenSor/Main_DeviceSummary.dart';
import '../Show_chart.dart';

/// หน้าสรุปผลอาหารแยกตามประเภท — เลือกประเภทอาหาร (เม็ดเล็ก/เม็ดใหญ่) แล้วดูว่า
/// แต่ละคอกที่กินอาหารประเภทนั้นกินไปวันละกี่กิโล (ประมาณจากอายุไก่ในคอก) แตะคอก
/// ไหนดูประวัติการตัดสต็อกจริงของคอกนั้นได้ ใช้เทียบกับสุขภาพไก่/ผลไข่ของคอกนั้น
/// ได้ว่ากินเยอะ-น้อยผิดปกติไหม — การตัดสต็อกจริงทำที่หน้าคลังอาหาร (ปุ่ม
/// "ตัดสต็อก") หรือ Cron อัตโนมัติทุกวันตอน 6 โมงเช้า ไม่มีโหมดกรอกจำนวนเองในหน้านี้แล้ว
/// (คำนวณให้อัตโนมัติทั้งหมดจากจำนวนไก่จริง)
class MainFoodTypeSummary extends StatefulWidget {
  /// ประเภทที่ต้องการให้เลือกไว้ตั้งแต่เปิดหน้ามา (null = เริ่มที่เม็ดเล็ก)
  final String? initialFoodType;

  const MainFoodTypeSummary({super.key, this.initialFoodType});

  @override
  State<MainFoodTypeSummary> createState() => _MainFoodTypeSummaryState();
}

class _MainFoodTypeSummaryState extends State<MainFoodTypeSummary> {
  int? selectedIndex; // ไม่ใช่หน้าในแถบเมนูล่าง จึงไม่ไฮไลต์เมนูไหน
  bool isLoading = true;
  List<dynamic> coopConsumption = [];
  late String _selectedFoodType;
  // จำนวนกิโลที่กรอกจริงล่าสุดของแต่ละคอก (key = "coopId_foodType") — ดึงจาก
  // ประวัติการแจกจ่ายที่บันทึกไว้จริง ใช้แทนตัวเลขประมาณการตอนแสดงผล
  Map<String, double> _actualKgByCoopType = {};
  // ประวัติการแจกจ่ายทั้งหมด (ไม่กรองซ้ำ) ใช้ตอนกดดูประวัติของคอกใดคอกหนึ่ง
  List<dynamic> _distributionHistory = [];

  @override
  void initState() {
    super.initState();
    _selectedFoodType = widget.initialFoodType ?? kFoodTypeSmallPellet;
    _fetchCoopConsumption();
    _fetchDistributionHistory();
  }

  Future<void> _fetchCoopConsumption() async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse('$backendBaseUrl/api/foods/coop-consumption');
      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        if (decodedData is List) {
          setState(() => coopConsumption = decodedData);
        }
      } else {
        debugPrint("Error fetching coop consumption: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Connection error (Coop consumption): $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ดึงประวัติการแจกจ่ายอาหารจริงทั้งหมด แล้วเก็บไว้แค่ "ค่าล่าสุด" ของแต่ละ
  // คอก+ประเภทอาหาร (backend ส่งเรียงใหม่สุดก่อนอยู่แล้ว จึงเจอค่าล่าสุดตัวแรกเสมอ)
  Future<void> _fetchDistributionHistory() async {
    try {
      final url = Uri.parse('$backendBaseUrl/api/foods/distribution');
      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          final Map<String, double> latest = {};
          for (final row in decoded) {
            final coopId = row['coop_id']?.toString() ?? '';
            final foodType = row['food_type']?.toString() ?? '';
            final key = '${coopId}_$foodType';
            latest.putIfAbsent(
              key,
              () => (row['kg_given'] as num?)?.toDouble() ?? 0.0,
            );
          }
          if (mounted) {
            setState(() {
              _actualKgByCoopType = latest;
              _distributionHistory = decoded;
            });
          }
        }
      } else {
        debugPrint(
          "Error fetching food distribution history: ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint("Connection error (food distribution history): $e");
    }
  }

  List<dynamic> get _coopsForSelectedType => coopConsumption
      .where((c) => c['food_type'] == _selectedFoodType)
      .toList();

  Widget _buildTypeTab(String foodType) {
    final ez = ezColors(context);
    final bool selected = _selectedFoodType == foodType;
    final int coopCount = coopConsumption
        .where((c) => c['food_type'] == foodType)
        .length;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedFoodType = foodType),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? ez.gold.withValues(alpha: 0.15) : ez.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? ez.gold : ez.border,
              width: 1.3,
            ),
          ),
          child: Column(
            children: [
              Text(
                foodType,
                style: GoogleFonts.kanit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: selected ? ez.gold : ez.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$coopCount คอก',
                style: GoogleFonts.kanit(fontSize: 11, color: ez.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoopRow(dynamic data) {
    final ez = ezColors(context);
    final String name = (data['name_coop'] ?? '-').toString();
    final String coopId = (data['coop_id'] ?? '').toString();
    final int amount = (data['amount'] ?? 0) is num
        ? (data['amount'] as num).toInt()
        : 0;
    final int ageWeeks = (data['age_weeks'] ?? 0) is num
        ? (data['age_weeks'] as num).toInt()
        : 0;
    final String foodType = (data['food_type'] ?? '').toString();
    final double? actualKg = _actualKgByCoopType['${coopId}_$foodType'];

    final Widget card = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ez.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ez.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.kanit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ez.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'อายุ $ageWeeks สัปดาห์ • $amount ตัว',
                  style: GoogleFonts.kanit(
                    fontSize: 11,
                    color: ez.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            actualKg != null ? '${actualKg.toStringAsFixed(1)} กก.' : '-',
            style: GoogleFonts.kanit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: actualKg != null ? ez.gold : ez.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: ez.textSecondary,
          ),
        ],
      ),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showCoopHistoryDialog(coopId, name, foodType),
      child: card,
    );
  }

  /// ป็อบอัพประวัติการแจกจ่ายอาหารของคอกนี้ (ประเภทอาหารเดียวกัน) เรียงใหม่สุดก่อน
  void _showCoopHistoryDialog(String coopId, String coopName, String foodType) {
    final rows = _distributionHistory.where((r) {
      return (r['coop_id']?.toString() ?? '') == coopId &&
          (r['food_type']?.toString() ?? '') == foodType;
    }).toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final ez = ezColors(dialogContext);
        return Dialog(
          backgroundColor: ezCardColor(dialogContext),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                        Icons.history_rounded,
                        color: ez.gold,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ประวัติอาหาร$foodType – คอก$coopName',
                        style: GoogleFonts.kanit(
                          color: ez.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      'ยังไม่มีประวัติการแจกจ่ายของคอกนี้',
                      style: GoogleFonts.kanit(
                        color: ez.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: SingleChildScrollView(
                      child: Column(
                        children: rows.map((r) {
                          final kg = (r['kg_given'] as num?)?.toDouble() ?? 0.0;
                          final date = thaiDateFromIso(
                            r['distributed_at']?.toString(),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  date,
                                  style: GoogleFonts.kanit(
                                    color: ez.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${kg.toStringAsFixed(1)} กก.',
                                  style: GoogleFonts.kanit(
                                    color: ez.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: ez.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      'ปิด',
                      style: GoogleFonts.kanit(
                        color: ez.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Mainchicken()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainShowDataFood()),
      );
    } else {
      setState(() {
        selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ez = ezColors(context);
    final coops = _coopsForSelectedType;

    return Scaffold(
      extendBody: true,
      backgroundColor: ezBackgroundColor(context),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back, color: ez.textPrimary),
                  ),
                  Text(
                    'สรุปผลอาหารแต่ละประเภท',
                    style: GoogleFonts.kanit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ez.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  _buildTypeTab(kFoodTypeSmallPellet),
                  const SizedBox(width: 12),
                  _buildTypeTab(kFoodTypeLargePellet),
                ],
              ),
              const SizedBox(height: 18),

              if (isLoading)
                Skeletonizer(
                  enabled: true,
                  child: Column(
                    children: List.generate(
                      3,
                      (_) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        height: 60,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
              else ...[
                Text(
                  'แยกตามคอก',
                  style: GoogleFonts.kanit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ez.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),

                if (coops.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'ยังไม่มีคอกที่กินอาหาร$_selectedFoodType',
                      style: GoogleFonts.kanit(color: ez.textSecondary),
                    ),
                  )
                else
                  ...coops.map(_buildCoopRow),
              ],
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
