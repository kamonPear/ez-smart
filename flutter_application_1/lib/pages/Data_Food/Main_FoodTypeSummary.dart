import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../services/backend_config.dart';
import '../../widgets/ez_header.dart';
import 'Main_DataAdd_Food1.dart';

/// หน้าสรุปผลอาหารแยกตามประเภท — เลือกประเภทอาหาร (เม็ดเล็ก/เม็ดใหญ่) แล้วดูว่า
/// แต่ละคอกที่กินอาหารประเภทนั้นกินไปวันละกี่กิโล (ประมาณจากอายุไก่ในคอก)
/// ใช้เทียบกับสุขภาพไก่/ผลไข่ของคอกนั้นได้ว่ากินเยอะ-น้อยผิดปกติไหม
class MainFoodTypeSummary extends StatefulWidget {
  /// ประเภทที่ต้องการให้เลือกไว้ตั้งแต่เปิดหน้ามา (null = เริ่มที่เม็ดเล็ก)
  final String? initialFoodType;

  const MainFoodTypeSummary({super.key, this.initialFoodType});

  @override
  State<MainFoodTypeSummary> createState() => _MainFoodTypeSummaryState();
}

class _MainFoodTypeSummaryState extends State<MainFoodTypeSummary> {
  bool isLoading = true;
  List<dynamic> coopConsumption = [];
  late String _selectedFoodType;

  @override
  void initState() {
    super.initState();
    _selectedFoodType = widget.initialFoodType ?? kFoodTypeSmallPellet;
    _fetchCoopConsumption();
  }

  Future<void> _fetchCoopConsumption() async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse('$backendBaseUrl/api/foods/coop-consumption');
      final response = await http.get(url);

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

  List<dynamic> get _coopsForSelectedType => coopConsumption
      .where((c) => c['food_type'] == _selectedFoodType)
      .toList();

  double get _totalKgForSelectedType => _coopsForSelectedType.fold(
    0.0,
    (sum, c) => sum + ((c['estimated_kg_per_day'] ?? 0) as num).toDouble(),
  );

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
            border: Border.all(color: selected ? ez.gold : ez.border, width: 1.3),
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
    final int amount = (data['amount'] ?? 0) is num
        ? (data['amount'] as num).toInt()
        : 0;
    final int ageWeeks = (data['age_weeks'] ?? 0) is num
        ? (data['age_weeks'] as num).toInt()
        : 0;
    final double kgPerDay = (data['estimated_kg_per_day'] ?? 0).toDouble();

    return Container(
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
                  style: GoogleFonts.kanit(fontSize: 11, color: ez.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '${kgPerDay.toStringAsFixed(1)} กก./วัน',
            style: GoogleFonts.kanit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: ez.gold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ez = ezColors(context);
    final coops = _coopsForSelectedType;

    return Scaffold(
      backgroundColor: ezBackgroundColor(context),
      body: SafeArea(
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: ez.card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'รวมอาหาร$_selectedFoodType ทั้งฟาร์ม',
                        style: GoogleFonts.kanit(
                          fontSize: 13,
                          color: ez.textSecondary,
                        ),
                      ),
                      Text(
                        '${_totalKgForSelectedType.toStringAsFixed(1)} กก./วัน',
                        style: GoogleFonts.kanit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ez.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

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
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
