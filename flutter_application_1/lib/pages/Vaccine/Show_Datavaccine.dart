import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/calendar.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../bottombar.dart';
import '../main_dash.dart';

class datavaccine extends StatefulWidget {
  final String vaccineTypeFilter;

  const datavaccine({super.key, required this.vaccineTypeFilter});

  @override
  State<datavaccine> createState() => _datavaccineState();
}

class _datavaccineState extends State<datavaccine> {
  int selectedIndex = 0;
  String selectedCoop = "เลือกคอก";

  List<Map<String, dynamic>> allVaccineData = [];
  bool isLoading = true;
  bool isSaving = false; 

  List<String> coopList = ["ทั้งหมด"];
  Map<String, String> coopChickenCounts = {};

  DateTime _selectedDate = DateTime.now();

  // Controllers สำหรับช่องกรอกข้อมูล
  TextEditingController medNameCtrl = TextEditingController(text: "");
  TextEditingController methodCtrl = TextEditingController(text: "");
  TextEditingController ageCondCtrl = TextEditingController(text: "");
  TextEditingController remarkCtrl = TextEditingController(text: "");

  @override
  void initState() {
    super.initState();
    fetchCoops();
    fetchVaccineData();
  }

  // 🌟 ฟังก์ชันบันทึกข้อมูลวัคซีน/ยาลง Backend (เพิ่มเงื่อนไขตรวจเช็คหมายเหตุแล้ว)
  Future<void> saveVaccineData() async {
    // 1. เช็คว่ากรอกข้อมูลครบไหม (เพิ่มตรวจสอบ remarkCtrl.text.isEmpty เข้าไป)
    if (medNameCtrl.text.isEmpty || 
        methodCtrl.text.isEmpty || 
        ageCondCtrl.text.isEmpty || 
        remarkCtrl.text.isEmpty) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orangeAccent,
          content: Text(
            'กรุณากรอกข้อมูล ชื่อยา, วิธีการให้, เงื่อนไขอายุ และ "หมายเหตุ" ให้ครบถ้วนก่อนบันทึก', 
            style: GoogleFonts.kanit(color: Colors.white)
          )
        ),
      );
      return; // สั่งหยุดการทำงานตรงนี้ ไม่ให้รันโค้ดบันทึกด้านล่างต่อ
    }

    setState(() {
      isSaving = true;
    });

    // 2. แปลงข้อความเงื่อนไขอายุ เช่น "5-7" เป็นตัวเลข
    int minDays = 0;
    int maxDays = 0;
    try {
      String cleanAge = ageCondCtrl.text.replaceAll('วัน', '').trim();
      if (cleanAge.contains('-')) {
        List<String> parts = cleanAge.split('-');
        minDays = int.parse(parts[0].trim());
        maxDays = int.parse(parts[1].trim());
      } else {
        minDays = int.parse(cleanAge);
        maxDays = minDays;
      }
    } catch (e) {
      minDays = 1;
      maxDays = 1;
    }

    // โครงสร้างข้อมูลที่ Backend ต้องการ
    final Map<String, dynamic> requestBody = {
      "name": medNameCtrl.text,
      "method": methodCtrl.text,
      "min_age_days": minDays,
      "max_age_days": maxDays,
      "description": remarkCtrl.text,
    };

    final String apiUrl = 'http://10.0.2.2:8080/api/vaccines/schedule'; 

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: const Color(0xFF55C759), content: Text('บันทึกกำหนดการยา/วัคซีนสำเร็จ!', style: GoogleFonts.kanit())),
        );
        
        // ล้างข้อมูลช่องกรอก
        medNameCtrl.clear();
        methodCtrl.clear();
        ageCondCtrl.clear();
        remarkCtrl.clear();
        
        // รีเฟรชตารางข้อมูล
        fetchVaccineData();
      } else {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.redAccent, content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล: $e', style: GoogleFonts.kanit())),
      );
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  Future<void> fetchCoops() async {
    final String apiUrl = 'http://10.0.2.2:8080/api/coops';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        var decoded = json.decode(response.body);
        List<dynamic> dataList = [];

        if (decoded is List) {
          dataList = decoded;
        } else if (decoded is Map && decoded.containsKey('data')) {
          dataList = decoded['data'];
        }

        setState(() {
          coopList = ["ทั้งหมด"];
          coopChickenCounts.clear();

          for (var item in dataList) {
            String id = item['coop_id']?.toString() ?? item['id']?.toString() ?? "";
            String count = item['chicken_count']?.toString() ??
                item['amount']?.toString() ??
                item['quantity']?.toString() ??
                "-";

            if (id.isNotEmpty) {
              coopList.add(id);
              coopChickenCounts[id] = count;
            }
          }
        });
      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการดึงรหัสคอก: $e');
    }
  }

  Future<void> fetchVaccineData() async {
    setState(() {
      isLoading = true;
    });

    String apiUrl = 'http://10.0.2.2:8080/api/vaccines/recommended';
    if (selectedCoop != "ทั้งหมด" && selectedCoop != "เลือกคอก") {
      apiUrl = 'http://10.0.2.2:8080/api/vaccines/recommended?coop_id=$selectedCoop';
    }

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        List<dynamic> schedules = [];
        String displayCoopId = "ตารางแนะนำ (ทั้งหมด)";
        String displayBirthday = "-";
        String displayChickenCount = "-";

        if (selectedCoop != "ทั้งหมด" && coopChickenCounts.containsKey(selectedCoop)) {
          if (coopChickenCounts[selectedCoop] != "-") {
            displayChickenCount = "${coopChickenCounts[selectedCoop]} ตัว";
          }
        }

        if (jsonResponse.containsKey('recommended_vaccines')) {
          schedules = jsonResponse['recommended_vaccines'] ?? [];
          displayCoopId = jsonResponse['coop_id']?.toString() ?? selectedCoop;

          if (jsonResponse['birthday'] != null) {
            displayBirthday = jsonResponse['birthday'].toString().split('T')[0];
          }
        } else {
          schedules = jsonResponse['schedules'] ?? [];
        }

        setState(() {
          allVaccineData = List<Map<String, dynamic>>.from(schedules.map((item) => {
                "coopId": displayCoopId,
                "chickenCount": displayChickenCount,
                "birthDate": displayBirthday,
                "vaccineDate": "อายุ ${item['min_age_days'] ?? ""}-${item['max_age_days'] ?? ""} วัน",
                "vaccineType": widget.vaccineTypeFilter,
                "medName": item['name'] ?? "",
                "healthyCount": "",
                "unhealthyCount": "",
                "remark": item['description'] ?? "",
              }));
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการดึงข้อมูล API: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void onTabSelected(int index) {
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
    } else if (index == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Mainchicken()));
    } else if (index == 4) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainShowDataFood()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CloseOpenDoor()));
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ShowChart()));
    } else {
      setState(() {
        selectedIndex = index;
      });
    }
  }

  void _showReminderBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            bool isAllDay = false; 
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                  ]
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 10),
                      child: Column(
                        children: [
                          Text("เตือน", style: GoogleFonts.kanit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("ตลอดวัน", style: GoogleFonts.kanit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              Switch(
                                value: isAllDay,
                                onChanged: (val) {
                                  setModalState(() {
                                    isAllDay = val;
                                  });
                                },
                                activeColor: Colors.white,
                                activeTrackColor: Colors.greenAccent,
                                inactiveThumbColor: Colors.white,
                                inactiveTrackColor: Colors.grey,
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white24, thickness: 1.5),
                          _buildReminderDateRow("WEDNES . 4 . DECEMBER . 2026"),
                          const Divider(color: Colors.white24, thickness: 1.5),
                          _buildReminderDateRow("WEDNES . 4 . DECEMBER . 2026"),
                          const Divider(color: Colors.white24, thickness: 1.5),
                          const SizedBox(height: 16),
                          const Icon(Icons.notifications_active_outlined, color: Colors.redAccent, size: 45),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context); 
                        saveVaccineData(); 
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF55C759),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_circle_outline, color: Colors.white, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              "บันทึกการให้วัคซีน",
                              style: GoogleFonts.kanit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReminderDateRow(String dateText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(dateText, style: GoogleFonts.kanit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
          Column(
            children: [
              Text("เวลา", style: GoogleFonts.kanit(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white)),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildTimeBox(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      children: [
                        Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                        const SizedBox(height: 4),
                        Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                      ],
                    ),
                  ),
                  _buildTimeBox(),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBox() {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: TextField(
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 2,
        style: GoogleFonts.kanit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: "", 
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF0F172A), 
      body: Stack(
        children: [
          // 1. ภาพพื้นหลัง
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Vaccine.png'), 
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),

          // 2. เนื้อหา UI (ลบตัวปฏิทินออกแล้ว ปรับระยะความสูงให้พอดี)
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // ปรับความสูงจากด้านบนลงมาให้แบบฟอร์มแสดงผลในตำแหน่งที่เหมาะสม
                  const SizedBox(height: 180),

                  // UI ฟอร์มข้อมูลวัคซีน
                  _buildVaccineFormWidget(),

                  const SizedBox(height: 100), 
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

  Widget _buildVaccineFormWidget() {
    String formattedDate = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PopupMenuButton<String>(
                      onSelected: (String value) {
                        setState(() {
                          selectedCoop = value;
                        });
                        fetchVaccineData();
                      },
                      color: Colors.white,
                      offset: const Offset(0, 45),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selectedCoop,
                              style: GoogleFonts.kanit(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 18),
                          ],
                        ),
                      ),
                      itemBuilder: (BuildContext context) => coopList.map((String coopId) {
                        return PopupMenuItem<String>(
                          value: coopId,
                          child: Text(coopId, style: GoogleFonts.kanit()),
                        );
                      }).toList(),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          formattedDate, 
                          style: GoogleFonts.kanit(fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ฟอร์มกรอกข้อมูล
                _buildInputRow("ชื่อยา", medNameCtrl),
                const SizedBox(height: 12),
                _buildInputRow("วิธีการให้", methodCtrl),
                const SizedBox(height: 12),
                _buildInputRow("เงื่อนไขอายุ", ageCondCtrl), 
                const SizedBox(height: 12),
                _buildInputRow("หมายเหตุ", remarkCtrl),
                
                const SizedBox(height: 20),
                
                GestureDetector(
                  onTap: _showReminderBottomSheet,
                  child: const Icon(Icons.notifications_active_outlined, color: Colors.redAccent, size: 36),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),

          InkWell(
            onTap: isSaving ? null : saveVaccineData,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSaving ? Colors.grey : const Color(0xFF55C759), 
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isSaving 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.add_circle_outline, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    isSaving ? "กำลังบันทึก..." : "บันทึกการให้วัคซีน",
                    style: GoogleFonts.kanit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow(String label, TextEditingController controller) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: GoogleFonts.kanit(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
          ),
        ),
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF131D2A), 
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2B3A4A), width: 1.5),
            ),
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10), 
              ),
            ),
          ),
        ),
      ],
    );
  }
}