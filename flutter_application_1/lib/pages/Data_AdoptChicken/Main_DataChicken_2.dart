import 'package:flutter/material.dart';
import 'dart:convert'; // เพิ่มสำหรับแปลง JSON
import 'package:http/http.dart' as http; // เพิ่มสำหรับยิง API
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_Datadopt_chicken_2.dart';
import 'package:flutter_application_1/pages/Main_SenSor/Data_System.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/Vaccine/Main_Vaccine.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Chicken_health_information/Show_Chicken_health.dart';
import '../bottombar.dart';
import '../main_dash.dart';
import '../../widgets/ez_header.dart';
import '../../services/backend_config.dart';

class Mainchicken extends StatefulWidget {
  const Mainchicken({super.key});

  @override
  State<Mainchicken> createState() => _MainchickenState();
}

class _MainchickenState extends State<Mainchicken> {
  int selectedIndex = 0;

  // --- เพิ่มตัวแปรสำหรับเก็บข้อมูลและเช็คสถานะโหลด ---
  List<Map<String, dynamic>> coopData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // เรียกใช้ฟังก์ชันดึงข้อมูลเมื่อเปิดหน้านี้
    fetchCoopData();
  }

  // --- ฟังก์ชันสำหรับดึงข้อมูลจาก API ---
  Future<void> fetchCoopData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // 🔴 เปลี่ยน URL เป็น API ของคุณ (เช่น http://192.168.x.x/api/get_coops)
      final String apiUrl = "$backendBaseUrl/api/coops";
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        final List<Map<String, dynamic>> fetchedData = jsonData.map((data) {
          String rawDate = data["date_adopt_animals"]?.toString() ?? "-";
          String displayDate = rawDate != "-" ? rawDate.split('T')[0] : "-";

          String coopId = data["coop_id"]?.toString() ?? "-";
          String coopName = data["name_coop"]?.toString().trim() ?? "";

          return {
            // 🔴 เปลี่ยนชื่อ Key ในกรอบสี่เหลี่ยมให้ตรงกับ Database/API ของคุณ
            "coop_id": coopId,
            "coop_name": coopName.isNotEmpty ? coopName : coopId,
            "chicken_count": data["amount"] ?? "0",
            "adopt_date": displayDate,
          };
        }).toList();

        setState(() {
          coopData = fetchedData;
          isLoading = false;
        });
      } else {
        print("ดึงข้อมูลไม่สำเร็จ Status code: ${response.statusCode}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดในการเชื่อมต่อ API: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void onTabSelected(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainShowDataFood()),
      );
    } else if (index == 1) {
      Navigator.push(
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

  // --- ฟังก์ชันสร้างแถวข้อมูลในตาราง ---
  Widget _buildTableRow(String col1, String col2, String col3) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white24, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              col1,
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              col2,
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              col3,
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ฟังก์ชันสร้างปุ่มเมนูสี่เหลี่ยม ---
  Widget _buildSquareMenu(
    IconData icon,
    String title,
    VoidCallback onTap, {
    double? width,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFF1E2730), // สีพื้นหลังปุ่มแบบในรูป
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 45),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.kanit(
                fontSize: 16,
                fontWeight: FontWeight.w500,
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
                child: EzHeader(pageTitle: 'เมนูไก่'),
              ),
            ),
          ),

          // --- เนื้อหา ---
          Positioned(
            top: 110,
            left: 0,
            right: 0,
            bottom: 80,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // 1. ตารางข้อมูลคอกรวม
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2730), // สีพื้นหลังกล่องข้อมูล
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "คอกรวม",
                          style: GoogleFonts.kanit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Header ตาราง
                        Container(
                          padding: const EdgeInsets.only(bottom: 8),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white54,
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "คอกที่",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.kanit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "จำนวนไก่",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.kanit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "วันที่รับมาเลี้ยง",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.kanit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // --- ส่วนที่แสดงผลข้อมูลที่ได้จาก API ---
                        isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.green,
                                  ),
                                ),
                              )
                            : coopData.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Center(
                                  child: Text(
                                    "ไม่มีข้อมูล",
                                    style: GoogleFonts.kanit(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                children: coopData.map((data) {
                                  return _buildTableRow(
                                    data["coop_name"].toString(),
                                    data["chicken_count"].toString(),
                                    data["adopt_date"].toString(),
                                  );
                                }).toList(),
                              ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 2. เมนูปุ่มด้านล่าง
                  Row(
                    children: [
                      // ปุ่มตรวจสุขภาพ
                      Expanded(
                        child: _buildSquareMenu(
                          Icons.medical_information_outlined,
                          "ตรวจสุขภาพ",
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Chickenhealth(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      // ปุ่มการให้วัคซีน
                      Expanded(
                        child: _buildSquareMenu(
                          Icons.vaccines_outlined,
                          "การให้วัคซีน",
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MainVaccine(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // ปุ่มอุปกรณ์และเซนเซอร์
                  _buildSquareMenu(
                    Icons.cell_tower,
                    "อุปกรณ์ และ เซนเซอร์",
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DataSystem(),
                        ),
                      );
                    },
                    width: MediaQuery.of(context).size.width * 0.65,
                  ),

                  const SizedBox(height: 50),
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
}
