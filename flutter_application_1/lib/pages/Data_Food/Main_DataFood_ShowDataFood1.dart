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
import '../../services/backend_config.dart';
import '../../utils/thai_date.dart';
import '../../widgets/ez_header.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../widgets/ez_top_banner.dart';
import '../../widgets/ez_confirm_dialog.dart';
import '../../theme/app_theme.dart';

class MainShowDataFood extends StatefulWidget {
  const MainShowDataFood({super.key});

  @override
  State<MainShowDataFood> createState() => _MainShowDataFoodState();
}

class _MainShowDataFoodState extends State<MainShowDataFood> {
  int selectedIndex = 4;
  bool isLoading = true;

  Map<String, String>? foodData;
  Map<String, dynamic>?
  rawData; // 🌟 เพิ่มตัวแปรสำหรับเก็บข้อมูลดิบจากฐานข้อมูล
  String? currentFoodId;

  double currentPercent = 0.0;
  String expireStatusText = "กำลังโหลดข้อมูล...";
  // จำนวนวันจนถึงวันหมดอายุ (null = ยังไม่ทราบ/ไม่มีข้อมูล) ใช้ตัดสินใจสี
  // ของป้ายสถานะ แทนที่จะให้เป็นสีแดงตลอดไม่ว่ากรณีไหน
  int? _daysUntilExpire;

  List<dynamic> foodHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchFoodData();
    _fetchFoodHistory();
  }

  String _getThaiMonthShort(int month) {
    const List<String> thaiMonths = [
      "",
      "ม.ค.",
      "ก.พ.",
      "มี.ค.",
      "เม.ย.",
      "พ.ค.",
      "มิ.ย.",
      "ก.ค.",
      "ส.ค.",
      "ก.ย.",
      "ต.ค.",
      "พ.ย.",
      "ธ.ค.",
    ];
    if (month < 1 || month > 12) return "";
    return thaiMonths[month];
  }

  Future<void> _fetchFoodData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('$backendBaseUrl/api/foods'));

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);
        Map<String, dynamic>? data;

        if (decodedData is List) {
          if (decodedData.isNotEmpty) {
            data = decodedData.last;
          }
        } else if (decodedData is Map<String, dynamic>) {
          data = decodedData;
        }

        if (data != null && data['food_id'] != null && data['food_id'] != 0) {
          currentFoodId = data['food_id'].toString();
          rawData = data; // 🌟 เก็บข้อมูลทั้งหมดไว้ เพื่อใช้ตอนส่งอัปเดตกลับไป

          double currentQty = (data['quantity_current'] ?? 0).toDouble();
          double maxQty = (data['max_quantity'] ?? 400).toDouble();
          if (maxQty <= 0) maxQty = 400;

          double calculatedPercent = (currentQty / maxQty) * 100;

          String expireStatus = "ไม่ระบุวันหมด";
          int? daysDiff;
          if (data['expiry_date'] != null &&
              data['expiry_date'].toString().isNotEmpty) {
            try {
              DateTime expDt = DateTime.parse(data['expiry_date']).toLocal();
              DateTime now = DateTime.now();
              DateTime today = DateTime(now.year, now.month, now.day);
              DateTime expDay = DateTime(expDt.year, expDt.month, expDt.day);

              daysDiff = expDay.difference(today).inDays;
              String thaiMonth = _getThaiMonthShort(expDt.month);

              if (daysDiff < 0) {
                expireStatus =
                    "หมดอายุแล้ว (${expDt.day} $thaiMonth ${expDt.year + 543})";
              } else {
                expireStatus =
                    "จะหมดในอีก $daysDiff วัน (${expDt.day} $thaiMonth ${expDt.year + 543})";
              }
            } catch (_) {}
          }

          setState(() {
            currentPercent = calculatedPercent.clamp(0.0, 100.0);
            expireStatusText = expireStatus;
            _daysUntilExpire = daysDiff;

            foodData = {
              "id": data?['food_id'].toString() ?? "",
              "receiveDate": _formatDate(data?['import_date']),
              "amount": _formatAmount(data?['quantity_current']),
              "expireDate": _formatDate(data?['expiry_date']),
              "threshold": "${data?['min_quantity']} กิโลกรัม",
              "lastUpdateDate": _formatDateTime(
                data?['updated_at'] ?? data?['date_up'],
              ),
            };
          });
        } else {
          _setEmptyFoodData();
        }
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
      foodData = null;
      rawData = null;
      currentFoodId = null;
      currentPercent = 0.0;
      expireStatusText = "ยังไม่มีข้อมูลสต็อกปัจจุบัน";
      _daysUntilExpire = null;
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

  // 🌟 ฟังก์ชันลบสต็อกอาหาร
  Future<void> _deleteFoodstock() async {
    if (currentFoodId == null) {
      showEzTopBanner(context, "ไม่มีข้อมูลให้ลบ", type: EzBannerType.warning);
      return;
    }

    final bool confirmDelete = await showEzDeleteConfirm(
      context,
      title: 'ยืนยันการลบข้อมูล',
      message:
          'คุณต้องการลบข้อมูลคลังอาหารสัตว์ทั้งหมดในฐานข้อมูลใช่หรือไม่? การกระทำนี้ไม่สามารถย้อนคืนได้',
      confirmText: 'ลบข้อมูล',
    );

    if (!confirmDelete) return;

    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse('$backendBaseUrl/api/foods?id=$currentFoodId');
      print("📌 กำลังส่งคำสั่งลบไปที่: $url");

      final response = await http.delete(url);

      if (response.statusCode == 200) {
        showEzTopBanner(
          context,
          "ลบข้อมูลอาหารและคลังสำเร็จเรียบร้อยแล้ว!",
          type: EzBannerType.success,
        );
        _fetchFoodData();
        _fetchFoodHistory();
      } else {
        showEzTopBanner(
          context,
          "เกิดข้อผิดพลาดจากเซิร์ฟเวอร์: ไม่สามารถลบได้ (${response.statusCode})",
          type: EzBannerType.error,
        );
      }
    } catch (e) {
      debugPrint("Error deleting foodstock: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // 🌟 เพิ่มฟังก์ชันสั่งตัดสต็อก 20 กก. แบบแมนนวลที่นี่
  Future<void> _forceDeductStock() async {
    if (currentFoodId == null) {
      showEzTopBanner(
        context,
        "ไม่มีข้อมูลสต็อกให้ตัด",
        type: EzBannerType.warning,
      );
      return;
    }

    final bool confirm = await showEzConfirmDialog(
      context,
      title: 'ยืนยันการตัดสต็อก',
      message: 'คุณต้องการตัดสต็อกอาหาร 20 กิโลกรัม ใช่หรือไม่?',
      confirmText: 'ยืนยัน',
      icon: Icons.remove_circle_outline_rounded,
    );

    if (!confirm) return;

    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse('$backendBaseUrl/api/foodstocks/force-deduct');
      print("📌 กำลังส่งคำสั่งตัดสต็อกไปที่: $url");

      final response = await http.post(url);

      if (response.statusCode == 200) {
        showEzTopBanner(
          context,
          "ตัดสต็อก 20 กก. สำเร็จ!",
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

  String _formatDate(String? isoString) {
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

  /// สีของป้ายสถานะวันหมดอายุ ให้สอดคล้องกับความเร่งด่วนจริง แทนที่จะเป็น
  /// สีแดงตายตัวไม่ว่าจะเหลือเวลาอีกกี่วันก็ตาม
  Color _expireColor(EzColors ez) {
    if (_daysUntilExpire == null) return ez.textSecondary;
    if (_daysUntilExpire! < 0) return ez.danger;
    if (_daysUntilExpire! <= 7) return const Color(0xFFFFA726);
    return ez.success;
  }

  IconData _expireIcon() {
    if (_daysUntilExpire == null) return Icons.help_outline_rounded;
    if (_daysUntilExpire! < 0) return Icons.error_outline_rounded;
    if (_daysUntilExpire! <= 7) return Icons.warning_amber_rounded;
    return Icons.check_circle_outline_rounded;
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
                    // การ์ดที่ 1: สรุปสต็อกปัจจุบัน
                    _buildDarkCard(
                      child: Column(
                        children: [
                          _sectionHeader(
                            Icons.inventory_2_outlined,
                            'สรุปสต็อกปัจจุบัน',
                            subtitle: foodData == null
                                ? null
                                : 'อัปเดตล่าสุด ${foodData!['lastUpdateDate']}',
                          ),
                          const SizedBox(height: 18),

                          Text(
                            "ปริมาณคงเหลือ",
                            style: GoogleFonts.kanit(
                              fontSize: 13,
                              color: ezColors(context).textSecondary,
                            ),
                          ),
                          Text(
                            "${foodData?['amount'] ?? '0'} กก.",
                            style: GoogleFonts.kanit(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: ezColors(context).textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Text(
                                "${currentPercent.toInt()}%",
                                style: GoogleFonts.kanit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: ezColors(context).textPrimary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: (currentPercent / 100).clamp(
                                      0.0,
                                      1.0,
                                    ),
                                    minHeight: 14,
                                    backgroundColor: ezColors(context).border,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      ezColors(context).gold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                rawData?['min_quantity'] != null
                                    ? "ต่ำสุด ${rawData!['min_quantity']} กก."
                                    : "ต่ำสุด -",
                                style: GoogleFonts.kanit(
                                  fontSize: 11,
                                  color: ezColors(context).textSecondary,
                                ),
                              ),
                              Text(
                                rawData?['max_quantity'] != null
                                    ? "เต็มถัง ${rawData!['max_quantity']} กก."
                                    : "เต็มถัง -",
                                style: GoogleFonts.kanit(
                                  fontSize: 11,
                                  color: ezColors(context).textSecondary,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _expireColor(
                                ezColors(context),
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _expireIcon(),
                                  size: 16,
                                  color: _expireColor(ezColors(context)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    expireStatusText,
                                    style: GoogleFonts.kanit(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: _expireColor(ezColors(context)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                              return _buildTableRow(amount, date);
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

                          Row(
                            children: [
                              _buildSecondaryActionButton(
                                icon: Icons.remove_circle_outline,
                                text: 'ตัดสต็อก 20 กก.',
                                color: const Color(0xFFFFA726),
                                onTap: _forceDeductStock,
                              ),
                              const SizedBox(width: 10),
                              _buildSecondaryActionButton(
                                icon: Icons.delete_outline,
                                text: 'ลบข้อมูลทั้งหมด',
                                color: ezColors(context).danger,
                                onTap: _deleteFoodstock,
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

  Widget _buildTableRow(String amount, String date) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
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
