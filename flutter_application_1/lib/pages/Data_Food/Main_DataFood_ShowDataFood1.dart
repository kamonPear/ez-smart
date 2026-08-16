import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

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
import '../../widgets/ez_header.dart';

class MainShowDataFood extends StatefulWidget {
  const MainShowDataFood({super.key});

  @override
  State<MainShowDataFood> createState() => _MainShowDataFoodState();
}

class _MainShowDataFoodState extends State<MainShowDataFood> {
  int selectedIndex = 4;
  bool isLoading = true;

  Map<String, String>? foodData;
  Map<String, dynamic>? rawData; // 🌟 เพิ่มตัวแปรสำหรับเก็บข้อมูลดิบจากฐานข้อมูล
  String? currentFoodId; 
  
  double currentPercent = 0.0;
  String expireStatusText = "กำลังโหลดข้อมูล...";
  
  List<dynamic> foodHistory = [];
  final TextEditingController _updateQtyController = TextEditingController();
  DateTime? _selectedUpdateExpiryDate;

  @override
  void initState() {
    super.initState();
    _fetchFoodData(); 
    _fetchFoodHistory(); 
  }

  @override
  void dispose() {
    _updateQtyController.dispose();
    super.dispose();
  }

  String _getThaiMonthShort(int month) {
    const List<String> thaiMonths = [
      "", "ม.ค.", "ก.พ.", "มี.ค.", "เม.ย.", "พ.ค.", "มิ.ย.",
      "ก.ค.", "ส.ค.", "ก.ย.", "ต.ค.", "พ.ย.", "ธ.ค."
    ];
    if (month < 1 || month > 12) return "";
    return thaiMonths[month];
  }

  Future<void> _fetchFoodData() async {
    setState(() { isLoading = true; });

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
          if (data['expiry_date'] != null && data['expiry_date'].toString().isNotEmpty) {
            try {
              DateTime expDt = DateTime.parse(data['expiry_date']).toLocal();
              DateTime now = DateTime.now();
              DateTime today = DateTime(now.year, now.month, now.day);
              DateTime expDay = DateTime(expDt.year, expDt.month, expDt.day);
              
              int daysDiff = expDay.difference(today).inDays;
              String thaiMonth = _getThaiMonthShort(expDt.month);
              
              if (daysDiff < 0) {
                 expireStatus = "อาหารหมดอายุแล้ว (${expDt.day} $thaiMonth ${expDt.year + 543})";
              } else {
                 expireStatus = "อาหารจะหมดในอีก : $daysDiff วัน (${expDt.day} $thaiMonth ${expDt.year + 543})";
              }
            } catch (_) {}
          }

          setState(() {
            currentPercent = calculatedPercent.clamp(0.0, 100.0); 
            expireStatusText = expireStatus;

            foodData = {
              "id": data?['food_id'].toString() ?? "", 
              "receiveDate": _formatDate(data?['import_date']),
              "amount": _formatAmount(data?['quantity_current']),
              "expireDate": _formatDate(data?['expiry_date']),
              "threshold": "${data?['min_quantity']} กิโลกรัม",
              "lastUpdateDate": _formatDateTime(data?['updated_at'] ?? data?['date_up']),
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
        setState(() { isLoading = false; });
      }
    }
  }

  void _setEmptyFoodData() {
    setState(() { 
      foodData = null; 
      rawData = null;
      currentFoodId = null; 
      currentPercent = 0.0; 
      expireStatusText = "ไม่มีข้อมูลอาหาร"; 
    });
  }

  Future<void> _fetchFoodHistory() async {
    try {
      final url = Uri.parse('$backendBaseUrl/api/food_history'); 
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);

        if (decodedData is List) {
          setState(() { foodHistory = decodedData; });
        } else if (decodedData is Map && decodedData.containsKey('data')) {
          setState(() { foodHistory = decodedData['data']; });
        }
      } else {
        debugPrint("Error fetching history: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Connection error (History): $e");
    }
  }

  Future<void> _pickUpdateExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6FE975),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() { _selectedUpdateExpiryDate = picked; });
    }
  }

  // 🌟 อัพเดตสต็อกด้วยการยิงไปที่ /api/importfoods เหมือนตอน "เข้าสต็อกอาหาร"
  // เพื่อให้ importfood บันทึกปริมาณที่เพิ่มเข้ามาไว้ด้วย (ไม่ใช่แค่ทับยอด foodstock เฉยๆ)
  Future<void> _updateFoodStock() async {
    if (_updateQtyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("กรุณากรอกปริมาณที่ต้องการอัปเดต", style: GoogleFonts.kanit())),
      );
      return;
    }

    if (_selectedUpdateExpiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("กรุณาเลือกวันที่อาหารใกล้หมดก่อนอัปเดต", style: GoogleFonts.kanit())),
      );
      return;
    }

    setState(() { isLoading = true; });

    try {
      final url = Uri.parse('$backendBaseUrl/api/importfoods');

      double inputQty = double.tryParse(_updateQtyController.text) ?? 0.0;

      final requestBody = {
        "import_volume": inputQty.round(),
        "expiry_date": _selectedUpdateExpiryDate!.toUtc().toIso8601String(),
      };

      print("📌 กำลังส่งข้อมูลอัปเดตไปที่: $url");
      print("📌 ข้อมูลที่ส่งไป (Body): $requestBody");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      );

      print("📌 Status Code ที่ตอบกลับ: ${response.statusCode}");
      print("📌 ข้อความตอบกลับจาก Backend: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("อัปเดตสต็อกเรียบร้อยแล้ว!", style: GoogleFonts.kanit())),
        );
        _updateQtyController.clear();
        setState(() { _selectedUpdateExpiryDate = null; });
        await _fetchFoodData();
        await _fetchFoodHistory();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("อัปเดตไม่สำเร็จ (${response.statusCode})", style: GoogleFonts.kanit())),
        );
      }
    } catch (e) {
      debugPrint("Error updating stock: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาดในการเชื่อมต่อ", style: GoogleFonts.kanit())),
      );
    } finally {
      setState(() { isLoading = false; });
    }
  }

  // 🌟 ฟังก์ชันลบสต็อกอาหาร
  Future<void> _deleteFoodstock() async {
    if (currentFoodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ไม่มีข้อมูลให้ลบ", style: GoogleFonts.kanit())),
      );
      return;
    }

    bool confirmDelete = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E2832),
              title: Text("ยืนยันการลบข้อมูล", style: GoogleFonts.kanit(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Text("คุณต้องการลบข้อมูลคลังอาหารสัตว์ทั้งหมดในฐานข้อมูลใช่หรือไม่? การกระทำนี้ไม่สามารถย้อนคืนได้", style: GoogleFonts.kanit(color: Colors.white70)),
              actions: [
                TextButton(
                  child: Text("ยกเลิก", style: GoogleFonts.kanit(color: Colors.grey)),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: Text("ลบข้อมูล", style: GoogleFonts.kanit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ?? false;

    if (!confirmDelete) return;

    setState(() { isLoading = true; });

    try {
      final url = Uri.parse('$backendBaseUrl/api/foods?id=$currentFoodId'); 
      print("📌 กำลังส่งคำสั่งลบไปที่: $url");

      final response = await http.delete(url);
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ลบข้อมูลอาหารและคลังสำเร็จเรียบร้อยแล้ว!", style: GoogleFonts.kanit())),
        );
        _fetchFoodData();
        _fetchFoodHistory(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาดจากเซิร์ฟเวอร์: ไม่สามารถลบได้ (${response.statusCode})", style: GoogleFonts.kanit())),
        );
      }
    } catch (e) {
      debugPrint("Error deleting foodstock: $e");
    } finally {
      setState(() { isLoading = false; });
    }
  }

  // 🌟 เพิ่มฟังก์ชันสั่งตัดสต็อก 20 กก. แบบแมนนวลที่นี่
  Future<void> _forceDeductStock() async {
    if (currentFoodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ไม่มีข้อมูลสต็อกให้ตัด", style: GoogleFonts.kanit())),
      );
      return;
    }

    bool confirm = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E2832),
              title: Text("ยืนยันการตัดสต็อก", style: GoogleFonts.kanit(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Text("คุณต้องการตัดสต็อกอาหาร 20 กิโลกรัม ใช่หรือไม่?", style: GoogleFonts.kanit(color: Colors.white70)),
              actions: [
                TextButton(
                  child: Text("ยกเลิก", style: GoogleFonts.kanit(color: Colors.grey)),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: Text("ยืนยัน", style: GoogleFonts.kanit(color: const Color(0xFFFFA726), fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ?? false;

    if (!confirm) return;

    setState(() { isLoading = true; });

    try {
      final url = Uri.parse('$backendBaseUrl/api/foodstocks/force-deduct'); 
      print("📌 กำลังส่งคำสั่งตัดสต็อกไปที่: $url");

      final response = await http.post(url);
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ตัดสต็อก 20 กก. สำเร็จ!", style: GoogleFonts.kanit())),
        );
        await _fetchFoodData();
        await _fetchFoodHistory(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ตัดสต็อกไม่สำเร็จ (${response.statusCode})", style: GoogleFonts.kanit())),
        );
      }
    } catch (e) {
      debugPrint("Error deducting foodstock: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาดในการเชื่อมต่อ", style: GoogleFonts.kanit())),
      );
    } finally {
      setState(() { isLoading = false; });
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
    if (isoString == null || isoString.isEmpty) return "-";
    try {
      DateTime dt = DateTime.parse(isoString).toLocal();
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    } catch (e) {
      return "-";
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return "-";
    try {
      DateTime dt = DateTime.parse(isoString).toLocal();
      return "${dt.day.toString().padLeft(2, '0')} / ${dt.month.toString().padLeft(2, '0')} / ${dt.year + 543}";
    } catch (e) {
      return "-";
    }
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return "-";
    try {
      DateTime dt = DateTime.parse(isoString).toLocal();
      return "${dt.day.toString().padLeft(2, '0')} / ${dt.month.toString().padLeft(2, '0')} / ${dt.year + 543} เวลา ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} น.";
    } catch (e) {
      return "-";
    }
  }

  void onTabSelected(int index) {
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CloseOpenDoor()));
    } else if(index == 3){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Mainchicken()));
    } else if (index == 4) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainShowDataFood()));
    } else if(index == 2){
       Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ShowChart()));
    } else {
      setState(() { selectedIndex = index; });
    }
  }

  Widget _buildDarkCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2832),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildActionBtn({required String text, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.kanit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: ezBackgroundColor,
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
                    const Padding(
                      padding: EdgeInsets.only(top: 50.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    _buildDarkCard(
                      child: Column(
                        children: [
                          Text(
                            "ปริมาณคงเหลือปัจจุบัน: ${foodData?['amount'] ?? '0'} กิโลกรัม",
                            style: GoogleFonts.kanit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          
                          SizedBox(
                            height: 100, 
                            width: 200,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                CustomPaint(
                                  size: const Size(200, 100),
                                  painter: GaugePainter(percentage: currentPercent), 
                                ),
                                Positioned(
                                  bottom: 10,
                                  child: Text(
                                    "${currentPercent.toInt()} %", 
                                    style: GoogleFonts.kanit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0, left: 0,
                                  child: Text("MIN", style: GoogleFonts.kanit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                                Positioned(
                                  bottom: 0, right: 0,
                                  child: Text("MAX", style: GoogleFonts.kanit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          Text(
                            expireStatusText, 
                            style: GoogleFonts.kanit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFEF5350)),
                          ),
                        ],
                      ),
                    ),

                    _buildDarkCard(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text("ปริมาณ (กก.)", style: GoogleFonts.kanit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text("วันที่นำอาหารเข้า", style: GoogleFonts.kanit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                          const Divider(color: Colors.white30, thickness: 1, height: 20),
                          
                          if (foodHistory.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text("ไม่มีข้อมูลประวัติ", style: GoogleFonts.kanit(color: Colors.white54)),
                            )
                          else
                            ...foodHistory.map((data) {
                              String amount = "0";
                              if (data['import_volume'] != null && data['import_volume'] != 0) {
                                amount = data['import_volume'].toString();
                              } else if (data['quantity_current'] != null) {
                                amount = data['quantity_current'].toString();
                              }
                              String date = _formatDateSimple(data['import_date'] ?? data['created_at']);
                              return _buildTableRow(amount, date);
                            }).toList(),
                        ],
                      ),
                    ),

                    _buildDarkCard(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("ปริมาณที่อัพเดต", style: GoogleFonts.kanit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              Row(
                                children: [
                                  Container(
                                    height: 35,
                                    width: 80,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF141D26),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                                    ),
                                    child: TextField(
                                      controller: _updateQtyController, 
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.kanit(color: Colors.white),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.only(bottom: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: _pickUpdateExpiryDate,
                                    child: Icon(
                                      Icons.calendar_today_outlined,
                                      color: _selectedUpdateExpiryDate != null
                                          ? const Color(0xFF6FE975)
                                          : Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                          if (_selectedUpdateExpiryDate != null) ...[
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "วันหมดอายุ: ${_formatDate(_selectedUpdateExpiryDate!.toIso8601String())}",
                                style: GoogleFonts.kanit(fontSize: 12, color: Colors.white70),
                              ),
                            ),
                          ],
                          const SizedBox(height: 15),

                          _buildActionBtn(
                            text: "อัพเดตสต็อก",
                            color: const Color(0xFF6A92D4),
                            onTap: _updateFoodStock,
                          ),
                        ],
                      ),
                    ),

                    // 🌟 เพิ่มปุ่มใหม่ไว้ตรงนี้ เรียงกัน 3 ปุ่ม
                    _buildActionBtn(
                      text: "เข้าสต็อกอาหาร",
                      color: const Color(0xFF67C269),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MainaddDataFood()),
                        );
                        _fetchFoodData();
                        _fetchFoodHistory();
                      },
                    ),

                    // 🌟 ปุ่มกดตัดสต็อก (Manual)
                    _buildActionBtn(
                      text: "ตัดสต็อกอาหาร 20 กก. (Manual)",
                      color: const Color(0xFFFFA726), // ใช้สีส้มเพื่อแยกจากปุ่มอื่นชัดเจน
                      onTap: _forceDeductStock,
                    ),

                    _buildActionBtn(
                      text: "ล้างสต็อกทั้งหมด (ลบข้อมูล)",
                      color: const Color(0xFFD32F2F), 
                      onTap: _deleteFoodstock,        
                    ),
                    const SizedBox(height: 50),
                  ]
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
              Text(amount, style: GoogleFonts.kanit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(date, style: GoogleFonts.kanit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
        const Divider(color: Colors.white30, thickness: 1, height: 5),
      ],
    );
  }
}

class GaugePainter extends CustomPainter {
  final double percentage;

  GaugePainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    Paint backgroundPaint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.butt;

    const double startAngle = pi;
    const double sweepAngle = pi;

    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    canvas.drawArc(rect, startAngle, sweepAngle, false, backgroundPaint);

    const Gradient gradient = SweepGradient(
      startAngle: pi,
      endAngle: 2 * pi,
      colors: [Color(0xFF81D4FA), Color(0xFF66BB6A), Color(0xFFFFEE58), Color(0xFFEF5350)],
      stops: [0.0, 0.3, 0.7, 1.0],
    );

    Paint foregroundPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.butt;

    double filledAngle = (percentage / 100) * sweepAngle;
    canvas.drawArc(rect, startAngle, filledAngle, false, foregroundPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}