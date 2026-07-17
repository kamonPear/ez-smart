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
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'bottombar.dart';
import 'close_open_Door.dart'; 
import 'main_dash_AddData.dart';
import 'Data_AdoptChicken/Main_DataChicken_2.dart'; 
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
      final coopResponse = await http.get(Uri.parse('$backendBaseUrl/api/coops'));
      final healthResponse = await http.get(Uri.parse('$backendBaseUrl/api/healths'));
      final eggResponse = await http.get(Uri.parse('$backendBaseUrl/api/eggs')); 
      final deviceResponse = await http.get(Uri.parse('$backendBaseUrl/api/devices')); 
      
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
            String currentCoopId = item['coop_id']?.toString() ?? item['id']?.toString() ?? "1";
            
            var matchedHealths = healthData.where((h) => h['coop_id']?.toString() == currentCoopId).toList();
            var latestHealth = matchedHealths.isNotEmpty ? matchedHealths.last : null;

            var matchedEggs = eggData.where((e) => e['coop_id']?.toString() == currentCoopId).toList();
            Map<String, List<double>> eggStats = {};
            
            for (var egg in matchedEggs) {
              String year = '2026'; 
              int month = 1;

              if (egg['date_collect_egg'] != null) {
                try {
                  DateTime parsedDate = DateTime.parse(egg['date_collect_egg'].toString());
                  year = parsedDate.year.toString();
                  month = parsedDate.month;
                } catch (e) {
                  debugPrint("Date parsing error: $e");
                }
              }

              double amount = double.tryParse((egg['number_egg'] ?? '0').toString()) ?? 0.0;

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
              return d['coop_id'] != null && d['coop_id'].toString() == currentCoopId;
            }).toList();
            
            var tempDevice = coopDevices.firstWhere(
              (d) {
                String name = (d['name'] ?? '').toString().toLowerCase();
                return name.contains('อุณหภูมิ') || name.contains('dht');
              }, 
              orElse: () => null
            );
            String latestTemp = tempDevice != null ? tempDevice['value']?.toString() ?? "0" : "0";

            var ppmDevice = coopDevices.firstWhere(
              (d) {
                String name = (d['name'] ?? '').toString().toLowerCase();
                return name.contains('แอมโมเนีย') || name.contains('mq');
              }, 
              orElse: () => null
            );
            String latestPpm = ppmDevice != null ? ppmDevice['value']?.toString() ?? "0" : "0";

            // 💡 1. จัดการวันที่นำเข้า
            var rawImport = item['date_adopt_animals'];
            String importDate = "ไม่ระบุ";
            if (rawImport != null) {
              String dateStr = rawImport.toString().split('T')[0];
              if (dateStr != "0001-01-01") { // เช็คเพื่อกรองค่าว่างของ Go ทิ้ง
                importDate = dateStr;
              }
            }

            // 💡 2. จัดการวันเกิดไก่ (ใช้ 'Birthday' ตัว B พิมพ์ใหญ่ และ 'birthday')
            var rawBirth = item['Birthday'] ?? item['birthday']; 
            String birthDate = "ไม่ระบุ";
            if (rawBirth != null) {
              String dateStr = rawBirth.toString().split('T')[0];
              if (dateStr != "0001-01-01") { // เช็คเพื่อกรองค่าว่างของ Go ทิ้ง
                birthDate = dateStr;
              }
            }

            return {
              "id": currentCoopId,
              "number": currentCoopId, 
              "amount": item['amount']?.toString() ?? "120", 

              "import_date": importDate, 
              "birth_date": birthDate,   

              "healthy": latestHealth != null ? latestHealth['healthy']?.toString() ?? "0" : "0",
              "poor_health": latestHealth != null ? latestHealth['poor_health']?.toString() ?? "0" : "0",
              
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
      Navigator.push(context, MaterialPageRoute(builder: (context) => const CloseOpenDoor())).then((_) => setState(() => selectedIndex = 0));
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const Mainchicken())).then((_) => setState(() => selectedIndex = 0));
    } else if (index == 4) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const MainShowDataFood())).then((_) => setState(() => selectedIndex = 0));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const ShowChart())).then((_) => setState(() => selectedIndex = 0));
    } else {
      setState(() { selectedIndex = index; });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF0F1621),
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
                          icon: const Icon(Icons.menu, color: Colors.white, size: 32),
                          color: const Color(0xFF19232F), 
                          offset: const Offset(0, 50), 
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          onSelected: (String value) {
                            if (value == 'คอกไก่') {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const Adoptchicken()));
                            } else if (value == 'ตรวจสุขภาพ') {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const Chickenhealth()));
                            } else if (value == 'การให้วัคซีน') {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const datavaccine(vaccineTypeFilter: '')));
                            } else if (value == 'อุปกรณ์') {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const DataSystem()));
                            } else if (value == 'สต็อกอาหาร') {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const MainShowDataFood()));
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
                              hintStyle: GoogleFonts.kanit(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w500),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                              suffixIcon: const Icon(Icons.search, color: Colors.black87),
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
        builder: (context) => const Notifications(), // ⚠️ เปลี่ยนชื่อ Notifications() ให้ตรงกับชื่อ Class ในไฟล์ Notifications_.dart ของคุณ
      ),
    );
  },
  borderRadius: BorderRadius.circular(20), // เพิ่มเอฟเฟกต์ตอนกดให้เป็นวงกลม
  child: const Padding(
    padding: EdgeInsets.all(4.0),
    child: Icon(Icons.notifications_none, color: Colors.white, size: 32),
  ),
),
                    ],
                  ),
                ),
                
                const SizedBox(height: 25),
                
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF19232F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTopCircularGauge(title: "อุณหภูมิ", value: "25", unit: "°", subTitle: "อุณหภูมิที่ตั้งไว้คงที่", color: Colors.cyan, percent: 0.6),
                      _buildTopCircularGauge(title: "ปริมาณแอมโมเนีย", value: "35", unit: "PPM", subTitle: "ปริมาณแอมโมเนียที่ตั้งไว้คงที่", color: Colors.orange.shade800, percent: 0.4),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                
                Text(
                  'แนะนำคอก',
                  style: GoogleFonts.kanit(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFFE5BA93)),
                ),
                
                const SizedBox(height: 15),
                
                if (isLoading)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 50), child: CircularProgressIndicator())
                else if (coopList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 50),
                    child: Text("ไม่มีข้อมูลคอกไก่", style: GoogleFonts.kanit(fontSize: 18, color: Colors.grey)),
                  )
                else
                  ...coopList.map((coop) => _buildCoopCard(coop)).toList(),
                  
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomBar(selectedIndex: selectedIndex, onTabSelected: onTabSelected),
    );
  }

  Widget _buildTopCircularGauge({required String title, required String value, required String unit, required String subTitle, required Color color, required double percent}) {
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 55.0, lineWidth: 12.0, animation: true, percent: percent,
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (unit == "PPM") Text("PPM", style: GoogleFonts.kanit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: GoogleFonts.kanit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (unit == "°") Text("°", style: GoogleFonts.kanit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              Text(title, style: GoogleFonts.kanit(fontSize: 11, color: Colors.white70)),
            ],
          ),
          circularStrokeCap: CircularStrokeCap.round, backgroundColor: Colors.grey.shade800, progressColor: color,
        ),
        const SizedBox(height: 10),
        Text(subTitle, style: GoogleFonts.kanit(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w400)),
      ],
    );
  }

  Widget _buildCoopCard(Map<String, dynamic> data) {
    int healthyCount = int.tryParse(data["healthy"].toString()) ?? 0;
    int poorCount = int.tryParse(data["poor_health"].toString()) ?? 0;

    double tempValue = double.tryParse(data["temp"].toString()) ?? 0.0;
    double ppmValue = double.tryParse(data["ppm"].toString()) ?? 0.0;
    
    double tempPercent = (tempValue / 50.0).clamp(0.0, 1.0);
    double ppmPercent = (ppmValue / 100.0).clamp(0.0, 1.0);

    // ✅ ลบคำว่า "ตัว" ออกจากค่า amount
    String cleanAmount = data["amount"].toString().replaceAll(RegExp(r'ตัว|\s'), '');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF19232F),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'คอกไก่ที่ ${data["number"]}', 
                        style: GoogleFonts.kanit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      
                      // ✅ เปลี่ยนจากรูปกระต่าย เป็นรูปไก่
                      Image.asset(
                        'assets/images/chicken.png', 
                        width: 85, 
                        height: 85, 
                        color: Colors.white,
                        errorBuilder: (context, error, stackTrace) {
                          return const Text('🐔', style: TextStyle(fontSize: 60)); 
                        },
                      ),
                      
                      const SizedBox(height: 5),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(cleanAmount, style: GoogleFonts.kanit(color: const Color(0xFFFCA5A5), fontSize: 36, fontWeight: FontWeight.bold, height: 1)),
                          const SizedBox(width: 5),
                          Text("ตัว", style: GoogleFonts.kanit(color: Colors.white, fontSize: 18)),
                        ],
                      )
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text("วันที่นำเข้า : ${data["import_date"]}", style: GoogleFonts.kanit(color: Colors.white, fontSize: 13)),
                      Text("วันเกิดไก่ : ${data["birth_date"]}", style: GoogleFonts.kanit(color: Colors.white, fontSize: 13)),
                      const SizedBox(height: 12),
                      Text("สุขภาพไก่", style: GoogleFonts.kanit(color: Colors.white, fontSize: 13)),
                      const SizedBox(height: 4),
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Row(
                              children: [
                                if (healthyCount > 0)
                                  Expanded(
                                    flex: healthyCount,
                                    child: Container(
                                      color: const Color(0xFF4ADE80), height: 18, alignment: Alignment.center,
                                      child: Text("$healthyCount", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                if (poorCount > 0)
                                  Expanded(
                                    flex: poorCount,
                                    child: Container(
                                      color: const Color(0xFFEF4444), height: 18, alignment: Alignment.center,
                                      child: Text("$poorCount", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                if (healthyCount == 0 && poorCount == 0)
                                  Expanded(
                                    flex: 1, 
                                    child: Container(
                                      color: Colors.grey.shade700, height: 18, alignment: Alignment.center,
                                      child: const Text("0", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (healthyCount > 0)
                                Expanded(flex: healthyCount, child: const Align(alignment: Alignment.center, child: Text("😊", style: TextStyle(fontSize: 14)))),
                              if (poorCount > 0)
                                Expanded(flex: poorCount, child: const Align(alignment: Alignment.center, child: Text("☹️", style: TextStyle(fontSize: 14)))),
                              if (healthyCount == 0 && poorCount == 0)
                                Expanded(flex: 1, child: const Align(alignment: Alignment.center, child: Text("➖", style: TextStyle(fontSize: 14)))),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildHorizontalIndicator(
                        title: "อุณหภูมิ", 
                        value: "${data["temp"]}", 
                        unit: "C", 
                        color: Colors.cyan, 
                        percent: tempPercent 
                      ),
                      const SizedBox(height: 10),
                      _buildHorizontalIndicator(
                        title: "แอมโมเนีย", 
                        value: "${data["ppm"]}", 
                        unit: "PPM", 
                        color: Colors.orange.shade800, 
                        percent: ppmPercent 
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            EggCollectionLineChart(
              coopNumber: "${data["number"]}",
              eggData: data["egg_data"] ?? {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalIndicator({required String title, required String value, required String unit, required Color color, required double percent}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.kanit(color: Colors.white, fontSize: 13)),
        const SizedBox(height: 4),
        Container(
          height: 20,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: percent,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Positioned.fill(
                right: 15,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text("$value $unit", style: GoogleFonts.kanit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ],
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

class EggCollectionLineChart extends StatelessWidget {
  final String coopNumber; 
  final Map<String, List<double>> eggData; 

  const EggCollectionLineChart({Key? key, required this.coopNumber, required this.eggData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<String> sortedYears = eggData.keys.toList()..sort();
    String activeYear = sortedYears.isNotEmpty ? sortedYears.last : '2026';
    int thaiYear = int.parse(activeYear) + 543; 

    List<double> values = eggData[activeYear] ?? List.filled(12, 0.0);

    Iterable<double> nonZeroValues = values.where((v) => v > 0);
    double minVal = nonZeroValues.isNotEmpty ? nonZeroValues.reduce((a, b) => a < b ? a : b) : 0;
    int minIndex = minVal > 0 ? values.indexOf(minVal) : -1;

    double maxVal = values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 100;
    double chartMaxY = maxVal > 0 ? maxVal * 1.2 : 100; 

    List<FlSpot> spots = [];
    for (int i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i]));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'บันทึกการเก็บไข่รายปีของไก่คอกที่ $coopNumber ปี $thaiYear',
          style: GoogleFonts.kanit(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.white12,
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(color: Colors.white60, fontSize: 9),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      const months = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
                      int index = value.toInt();
                      if (index >= 0 && index < months.length) {
                        return Text(months[index], style: const TextStyle(color: Colors.white60, fontSize: 9));
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 11,
              minY: 0,
              maxY: chartMaxY, 
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false, 
                  color: Colors.white,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      bool isLowestPoint = (index == minIndex);
                      return FlDotCirclePainter(
                        radius: 4,
                        color: isLowestPoint ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                        strokeWidth: 0,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}