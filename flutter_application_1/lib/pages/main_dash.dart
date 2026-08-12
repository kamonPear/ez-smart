import 'dart:convert';
import 'package:flutter_application_1/pages/Chicken_health_information/Show_Chicken_health.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_Datadopt_chicken_2.dart';
import 'package:flutter_application_1/pages/Main_SenSor/Data_System.dart';
import 'package:flutter_application_1/pages/Vaccine/Main_Vaccine.dart';
import 'package:flutter_application_1/pages/Vaccine/Show_Datavaccine.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'bottombar.dart';
import 'close_open_Door.dart';
import 'main_dash_AddData.dart';
import 'Data_AdoptChicken/Main_DataChicken_2.dart';
import 'Data_AdoptChicken/Main_CoopDetail.dart';
import '../../services/backend_config.dart' hide backendBaseUrl;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;
  bool isLoading = true;
  List<Map<String, dynamic>> coopList = [];

  @override
  void initState() {
    super.initState();
    _fetchCoops();
  }

  Future<void> _fetchCoops() async {
    setState(() {
      isLoading = true;
    });

    try {
      final coopResponse = await http.get(
        Uri.parse('$backendBaseUrl/api/coops'),
      );
      final healthResponse = await http.get(
        Uri.parse('$backendBaseUrl/api/healths'),
      );
      final eggResponse = await http.get(Uri.parse('$backendBaseUrl/api/eggs'));
      final deviceResponse = await http.get(
        Uri.parse('$backendBaseUrl/api/devices'),
      );

      if (coopResponse.statusCode == 200) {
        final List<dynamic> coopData = jsonDecode(coopResponse.body);
        List<dynamic> healthData = [];
        List<dynamic> eggData = [];
        List<dynamic> deviceData = [];

        if (healthResponse.statusCode == 200) {
          healthData = jsonDecode(healthResponse.body);
        }
        if (eggResponse.statusCode == 200) {
          eggData = jsonDecode(eggResponse.body);
        }
        if (deviceResponse.statusCode == 200) {
          deviceData = jsonDecode(deviceResponse.body);
        }

        setState(() {
          coopList = coopData.map((item) {
            String currentCoopId =
                item['coop_id']?.toString() ?? item['id']?.toString() ?? "1";

            var matchedHealths = healthData
                .where((h) => h['coop_id']?.toString() == currentCoopId)
                .toList();
            var latestHealth = matchedHealths.isNotEmpty
                ? matchedHealths.last
                : null;

            var matchedEggs = eggData
                .where((e) => e['coop_id']?.toString() == currentCoopId)
                .toList();
            Map<String, List<double>> eggStats = {};

            for (var egg in matchedEggs) {
              String year = '2026';
              int month = 1;

              if (egg['date_collect_egg'] != null) {
                try {
                  DateTime parsedDate = DateTime.parse(
                    egg['date_collect_egg'].toString(),
                  );
                  year = parsedDate.year.toString();
                  month = parsedDate.month;
                } catch (e) {
                  debugPrint("Date parsing error: $e");
                }
              }

              double amount =
                  double.tryParse((egg['number_egg'] ?? '0').toString()) ?? 0.0;

              if (!eggStats.containsKey(year)) {
                eggStats[year] = List.filled(12, 0.0);
              }
              if (month >= 1 && month <= 12) {
                eggStats[year]![month - 1] += amount;
              }
            }

            if (eggStats.isEmpty) {
              eggStats['2026'] = List.filled(12, 0.0);
            }

            var coopDevices = deviceData.where((d) {
              return d['coop_id'] != null &&
                  d['coop_id'].toString() == currentCoopId;
            }).toList();

            var tempDevice = coopDevices.firstWhere((d) {
              String name = (d['name'] ?? '').toString().toLowerCase();
              return name.contains('อุณหภูมิ') || name.contains('dht');
            }, orElse: () => null);
            String latestTemp = tempDevice != null
                ? tempDevice['value']?.toString() ?? "0"
                : "0";

            var ppmDevice = coopDevices.firstWhere((d) {
              String name = (d['name'] ?? '').toString().toLowerCase();
              return name.contains('แอมโมเนีย') || name.contains('mq');
            }, orElse: () => null);
            String latestPpm = ppmDevice != null
                ? ppmDevice['value']?.toString() ?? "0"
                : "0";

            // 💡 1. จัดการวันที่นำเข้า
            var rawImport = item['date_adopt_animals'];
            String importDate = "ไม่ระบุ";
            if (rawImport != null) {
              String dateStr = rawImport.toString().split('T')[0];
              if (dateStr != "0001-01-01") {
                // เช็คเพื่อกรองค่าว่างของ Go ทิ้ง
                importDate = dateStr;
              }
            }

            // 💡 2. จัดการวันเกิดไก่ (ใช้ 'Birthday' ตัว B พิมพ์ใหญ่ และ 'birthday')
            var rawBirth = item['Birthday'] ?? item['birthday'];
            String birthDate = "ไม่ระบุ";
            if (rawBirth != null) {
              String dateStr = rawBirth.toString().split('T')[0];
              if (dateStr != "0001-01-01") {
                // เช็คเพื่อกรองค่าว่างของ Go ทิ้ง
                birthDate = dateStr;
              }
            }

            return {
              "id": currentCoopId,
              "number": currentCoopId,
              "name": item['name_coop']?.toString().trim().isNotEmpty == true
                  ? item['name_coop'].toString()
                  : currentCoopId,
              "amount": item['amount']?.toString() ?? "120",

              "import_date": importDate,
              "birth_date": birthDate,

              "healthy": latestHealth != null
                  ? latestHealth['healthy']?.toString() ?? "0"
                  : "0",
              "poor_health": latestHealth != null
                  ? latestHealth['poor_health']?.toString() ?? "0"
                  : "0",

              "temp": latestTemp,
              "ppm": latestPpm,
              "egg_data": eggStats,
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("❌ Connection/Parsing error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void onTabSelected(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CloseOpenDoor()),
      ).then((_) => setState(() => selectedIndex = 0));
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Mainchicken()),
      ).then((_) => setState(() => selectedIndex = 0));
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainShowDataFood()),
      ).then((_) => setState(() => selectedIndex = 0));
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ShowChart()),
      ).then((_) => setState(() => selectedIndex = 0));
    } else {
      setState(() {
        selectedIndex = index;
      });
    }
  }

  int get _totalChickenCount {
    int total = 0;
    for (var coop in coopList) {
      total +=
          int.tryParse(
            coop["amount"].toString().replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0;
    }
    return total;
  }

  int get _totalEggCount {
    int total = 0;
    for (var coop in coopList) {
      Map<String, List<double>> eggStats = coop["egg_data"] ?? {};
      for (var values in eggStats.values) {
        total += values.fold<double>(0, (sum, v) => sum + v).round();
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F1621),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(minHeight: screenHeight),
          decoration: const BoxDecoration(
            color: Color(0xFF0F1621),
            image: DecorationImage(
              image: AssetImage('assets/images/backg2.png'),
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 150),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Theme(
                        data: Theme.of(context).copyWith(
                          dividerTheme: const DividerThemeData(
                            color: Colors.white24,
                            thickness: 1,
                          ),
                        ),
                        child: PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.menu,
                            color: Colors.white,
                            size: 32,
                          ),
                          color: const Color(0xFF19232F),
                          offset: const Offset(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          onSelected: (String value) {
                            if (value == 'คอกไก่') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const Adoptchicken(),
                                ),
                              );
                            } else if (value == 'ตรวจสุขภาพ') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const Chickenhealth(),
                                ),
                              );
                            } else if (value == 'การให้วัคซีน') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ShowDatavaccine(
                                    vaccineTypeFilter: '',
                                  ),
                                ),
                              );
                            } else if (value == 'อุปกรณ์') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DataSystem(),
                                ),
                              );
                            } else if (value == 'สต็อกอาหาร') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const MainShowDataFood(),
                                ),
                              );
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            _buildDropdownItem('คอกไก่'),
                            const PopupMenuDivider(height: 1),
                            _buildDropdownItem('ปฏิทินรวม'),
                            const PopupMenuDivider(height: 1),
                            _buildDropdownItem('การแจ้งเตือน'),
                            const PopupMenuDivider(height: 1),
                            _buildDropdownItem('ตรวจสุขภาพ'),
                            const PopupMenuDivider(height: 1),
                            _buildDropdownItem('การให้วัคซีน'),
                            const PopupMenuDivider(height: 1),
                            _buildDropdownItem('อุปกรณ์'),
                            const PopupMenuDivider(height: 1),
                            _buildDropdownItem('เซนเซอร์'),
                            const PopupMenuDivider(height: 1),
                            _buildDropdownItem('สต็อกอาหาร'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextField(
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              hintText: 'SEARCH',
                              hintStyle: GoogleFonts.kanit(
                                color: Colors.grey.shade400,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              suffixIcon: const Icon(
                                Icons.search,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const Notifications(), // ⚠️ เปลี่ยนชื่อ Notifications() ให้ตรงกับชื่อ Class ในไฟล์ Notifications_.dart ของคุณ
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(
                          20,
                        ), // เพิ่มเอฟเฟกต์ตอนกดให้เป็นวงกลม
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.notifications_none,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 15,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF19232F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTopCircularGauge(
                        title: "อุณหภูมิ",
                        value: "25",
                        unit: "°",
                        subTitle: "อุณหภูมิที่ตั้งไว้คงที่",
                        color: Colors.cyan,
                        percent: 0.6,
                      ),
                      _buildTopCircularGauge(
                        title: "ปริมาณแอมโมเนีย",
                        value: "35",
                        unit: "PPM",
                        subTitle: "ปริมาณแอมโมเนียที่ตั้งไว้คงที่",
                        color: Colors.orange.shade800,
                        percent: 0.4,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          emoji: '🐔',
                          bgColor: const Color(0xFFCFE8D9),
                          textColor: Colors.black87,
                          label: 'จำนวนไก่ทั้งหมด',
                          value: '$_totalChickenCount ตัว',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          emoji: '🥚',
                          bgColor: const Color(0xFFF3DCC2),
                          textColor: Colors.black87,
                          label: 'จำนวนไข่ทั้งหมด',
                          value: '$_totalEggCount ฟอง',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          emoji: '🌾',
                          bgColor: const Color(0xFF232E3D),
                          textColor: Colors.white,
                          label: 'อาหารคงเหลือ',
                          value: '250 กิโลกรัม',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                Text(
                  'คอกไก่ทั้งหมด',
                  style: GoogleFonts.kanit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE5BA93),
                  ),
                ),

                const SizedBox(height: 15),

                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 50),
                    child: CircularProgressIndicator(),
                  )
                else if (coopList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 50),
                    child: Text(
                      "ไม่มีข้อมูลคอกไก่",
                      style: GoogleFonts.kanit(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  )
                else
                  ...coopList.map((coop) => _buildCoopCard(coop)).toList(),

                const SizedBox(height: 80),
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

  Widget _buildStatCard({
    required String emoji,
    required Color bgColor,
    required Color textColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.kanit(
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.kanit(
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCircularGauge({
    required String title,
    required String value,
    required String unit,
    required String subTitle,
    required Color color,
    required double percent,
  }) {
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 55.0,
          lineWidth: 12.0,
          animation: true,
          percent: percent,
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (unit == "PPM")
                Text(
                  "PPM",
                  style: GoogleFonts.kanit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.kanit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (unit == "°")
                    Text(
                      "°",
                      style: GoogleFonts.kanit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
              Text(
                title,
                style: GoogleFonts.kanit(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
          circularStrokeCap: CircularStrokeCap.round,
          backgroundColor: Colors.grey.shade800,
          progressColor: color,
        ),
        const SizedBox(height: 10),
        Text(
          subTitle,
          style: GoogleFonts.kanit(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildCoopCard(Map<String, dynamic> data) {
    // ✅ ลบคำว่า "ตัว" ออกจากค่า amount
    String cleanAmount = data["amount"].toString().replaceAll(
      RegExp(r'ตัว|\s'),
      '',
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CoopDetailPage(coop: data)),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF19232F),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('🐔', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'คอกไก่ ${data["name"]}',
                      style: GoogleFonts.kanit(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          cleanAmount,
                          style: GoogleFonts.kanit(
                            color: const Color(0xFFFCA5A5),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "ตัว",
                          style: GoogleFonts.kanit(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "วันที่นำเข้า : ${data["import_date"]}",
                    style: GoogleFonts.kanit(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "วันเกิดไก่ : ${data["birth_date"]}",
                    style: GoogleFonts.kanit(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildDropdownItem(String title) {
    return PopupMenuItem<String>(
      value: title,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 25),
      child: Center(
        child: Text(
          title,
          style: GoogleFonts.kanit(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
