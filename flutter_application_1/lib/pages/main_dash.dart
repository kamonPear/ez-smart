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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  // เพิ่มตัวแปรเก็บ List ของข้อมูลคอกไก่ (มีข้อมูลเริ่มต้น 1 คอก)
  List<Map<String, dynamic>> coopList = [
    {
      "id": "1",
      "number": "1",
      "temp": "28",
      "ppm": "20",
    }
  ];

  void onTabSelected(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CloseOpenDoor()),
      ).then((_) {
        setState(() {
          selectedIndex = 0;
        });
      });
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Mainchicken()), 
      ).then((_) {
        setState(() {
          selectedIndex = 0;
        });
      });
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainShowDataFood()), 
      ).then((_) {
        setState(() {
          selectedIndex = 0;
        });
      });
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ShowChart()), 
      ).then((_) {
        setState(() {
          selectedIndex = 0;
        });
      });
    } 
    else {
      setState(() {
        selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF5F5F5), 
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(minHeight: screenHeight),
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
            image: DecorationImage(
              image: AssetImage('assets/images/back1.png'),
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header: Logo & App Name
                Container(
                  height: 160,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 120,
                          height: 120,
                        ),
                      ),
                      Positioned(
                        left: 135,
                        top: 25,
                        child: Text(
                          'EZ -\nSMART\nFARM', 
                          style: GoogleFonts.kanit(
                            fontSize: 28,
                            height: 1.1,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 252, 250, 250),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 20,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const Notifications()),
                            );
                          },
                          child: const Icon(
                            Icons.notifications_active,
                            color: Colors.black87,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60), 

                // Search Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'SEARCH',
                      hintStyle: GoogleFonts.kanit(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      suffixIcon: const Icon(Icons.search, color: Colors.black54),
                    ),
                  ),
                ),

                const SizedBox(height: 50), 

                // วนลูปสร้าง Dashboard Card ตามจำนวนข้อมูลใน coopList
                ...coopList.map((coop) {
                  return _buildCoopCard(coop);
                }),
                
                // เว้นระยะด้านล่างสุดไม่ให้ทับกับ BottomBar
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // รอรับข้อมูลที่ส่งกลับมาจากหน้า เพิ่มข้อมูล
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MainAddDatachicken()),
          );

          // ถ้ารับข้อมูลมาได้ ให้อัปเดต UI เพิ่มการ์ดใหม่
          if (result != null) {
            setState(() {
              coopList.add(result);
            });
          }
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.playlist_add_circle, color: Colors.black, size: 50),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: CustomBottomBar(
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected,
      ),
    );
  }

  // --- Widget Helpers ---

  // ฟังก์ชันสร้างการ์ดคอกไก่
  Widget _buildCoopCard(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Card Title
            Container(
              padding: const EdgeInsets.only(bottom: 5),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.redAccent.shade200, width: 2),
                ),
              ),
              child: Text(
                'คอกไก่คอกที่ ${data["number"]}', 
                style: GoogleFonts.kanit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent.shade200,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Linear Progress Targets
            Row(
              children: [
                Expanded(
                  child: _buildLinearTarget(
                    title: "อุณหภูมิที่ตั้งไว้คงที่",
                    value: "${data["temp"]}", 
                    unit: "C",
                    percent: 0.8,
                    color: Colors.cyan,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildLinearTarget(
                    title: "ปริมาณแอมโมเนียที่ตั้งไว้คงที่",
                    value: "${data["ppm"]}", 
                    unit: "PPM",
                    percent: 0.8,
                    color: const Color(0xFFD35400),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // Circular Gauges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPercentGauge(
                  title: "อุณหภูมิ",
                  value: "${data["temp"]}", 
                  unit: "°",
                  percent: 0.7,
                  color: Colors.cyan,
                ),
                _buildPercentGauge(
                  title: "ปริมาณแอมโมเนีย",
                  value: "${data["ppm"]}", 
                  unit: "PPM",
                  percent: 0.4,
                  color: const Color(0xFFD35400),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // Number Of Chickens Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA2A2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        const Icon(Icons.cruelty_free, size: 40, color: Colors.black87), 
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Number Of Chickens", style: GoogleFonts.kanit(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 13)),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("120", style: GoogleFonts.oswald(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, height: 1)),
                                const SizedBox(width: 5),
                                Text("ตัว", style: GoogleFonts.kanit(color: Colors.white, fontSize: 16)),
                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildSmallStatBox("Healthy", "115", Colors.blue.shade800),
                        const SizedBox(height: 6),
                        _buildSmallStatBox("Poor Health", "5", Colors.blue.shade800),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- นำ Bar Chart จากหน้า ShowChart มาแสดงแทนกราฟเดิม ---
            EggCollectionChart(coopNumber: "${data["number"]}"),

          ],
        ),
      ),
    );
  }

  Widget _buildLinearTarget({required String title, required String value, required String unit, required double percent, required Color color}) {
    return Column(
      children: [
        Text(title, style: GoogleFonts.kanit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
        Text(value, style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, height: 1.2)),
        Row(
          children: [
            Expanded(
              child: LinearPercentIndicator(
                lineHeight: 12.0,
                percent: percent,
                backgroundColor: Colors.grey.shade700,
                progressColor: color,
                barRadius: const Radius.circular(10),
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 5),
            Text(unit, style: GoogleFonts.kanit(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallStatBox(String title, String value, Color titleColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8B8B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.kanit(color: titleColor, fontSize: 10, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Text(value, style: GoogleFonts.oswald(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text("ตัว", style: GoogleFonts.kanit(color: Colors.white, fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPercentGauge({required String title, required String value, required String unit, required double percent, required Color color}) {
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 65.0, 
          lineWidth: 15.0,
          animation: true,
          percent: percent,
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (unit == "PPM") Text("PPM", style: GoogleFonts.oswald(fontSize: 16, fontWeight: FontWeight.bold, height: 1.2)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: GoogleFonts.oswald(fontSize: 40, fontWeight: FontWeight.bold, height: 1.0, color: Colors.black87)),
                  if (unit == "°") Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Container(width: 10, height: 10, decoration: BoxDecoration(border: Border.all(width: 3.0, color: Colors.black87), shape: BoxShape.circle)),
                  ),
                ],
              ),
            ],
          ),
          circularStrokeCap: CircularStrokeCap.square, 
          backgroundColor: Colors.grey.shade700, 
          progressColor: color,
        ),
        const SizedBox(height: 12),
        // นำตัวหนังสือมาแสดงด้านล่างวงกลมแทน
        Text(title, style: GoogleFonts.kanit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}

// =======================================================
// แยกส่วนกราฟออกมาเป็น StatefulWidget เพื่อไม่ให้ State ไปทับกับคอกอื่น
// =======================================================
class EggCollectionChart extends StatefulWidget {
  final String coopNumber; // รับหมายเลขคอกมาแสดงที่ Title กราฟ

  const EggCollectionChart({Key? key, required this.coopNumber}) : super(key: key);

  @override
  State<EggCollectionChart> createState() => _EggCollectionChartState();
}

class _EggCollectionChartState extends State<EggCollectionChart> {
  bool isMonthly = true; 
  String selectedYear = '2024'; 

  final Map<String, List<double>> mockMonthlyData = {
    '2020': [15, 20, 25, 22, 30, 35, 40, 38, 45, 50, 48, 55],
    '2021': [20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75],
    '2022': [25, 40, 35, 60, 50, 70, 45, 55, 40, 65, 30, 75],
    '2023': [30, 50, 45, 70, 60, 85, 55, 65, 50, 75, 40, 80],
    '2024': [40, 65, 50, 85, 70, 90, 60, 75, 55, 80, 45, 95],
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white, // ให้พื้นหลังสีขาวเพื่อตัดกับกรอบสีเทาของการ์ด
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // หัวข้อกราฟ และ Dropdown เลือกปี
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สถิติการเก็บไข่ (คอกที่ ${widget.coopNumber})',
                      style: GoogleFonts.kanit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    if (isMonthly)
                      Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedYear,
                            isDense: true,
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.orange),
                            style: GoogleFonts.kanit(
                              color: Colors.orange.shade800, 
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedYear = newValue!;
                              });
                            },
                            items: mockMonthlyData.keys.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text('ปี $value'),
                              );
                            }).toList(),
                          ),
                        ),
                      )
                    else
                      Text(
                        'แตะที่กราฟเพื่อดูรายเดือน',
                        style: GoogleFonts.kanit(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              // ปุ่มสลับโหมด รายเดือน / รายปี
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => isMonthly = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isMonthly ? const Color.fromARGB(255, 172, 24, 24) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'เดือน',
                          style: GoogleFonts.kanit(
                            fontSize: 10,
                            color: isMonthly ? Colors.white : Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => isMonthly = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: !isMonthly ? const Color.fromARGB(255, 172, 24, 24) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ปี',
                          style: GoogleFonts.kanit(
                            fontSize: 10,
                            color: !isMonthly ? Colors.white : Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ตัวกราฟที่เลื่อนซ้ายขวาได้
          SizedBox(
            height: 200,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: isMonthly ? 650 : MediaQuery.of(context).size.width - 100,
                padding: const EdgeInsets.only(right: 15), 
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100, 
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => Colors.black87,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.toInt()}\n',
                            GoogleFonts.kanit(color: Colors.white, fontWeight: FontWeight.bold),
                            children: [
                              TextSpan(
                                text: isMonthly ? 'ฟอง' : 'แตะดูรายเดือน',
                                style: GoogleFonts.kanit(
                                  color: Colors.orangeAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      touchCallback: (FlTouchEvent event, barTouchResponse) {
                        if (!event.isInterestedForInteractions || barTouchResponse == null || barTouchResponse.spot == null) {
                          return;
                        }
                        if (event is FlTapUpEvent && !isMonthly) {
                          int index = barTouchResponse.spot!.touchedBarGroupIndex;
                          String tappedYear = (2020 + index).toString();
                          setState(() {
                            selectedYear = tappedYear;
                            isMonthly = true; 
                          });
                        }
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final style = GoogleFonts.kanit(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 11, 
                            );
                            String text = '';
                            if (isMonthly) {
                              switch (value.toInt()) {
                                case 0: text = 'ม.ค.'; break;
                                case 1: text = 'ก.พ.'; break;
                                case 2: text = 'มี.ค.'; break;
                                case 3: text = 'เม.ย.'; break;
                                case 4: text = 'พ.ค.'; break;
                                case 5: text = 'มิ.ย.'; break;
                                case 6: text = 'ก.ค.'; break;
                                case 7: text = 'ส.ค.'; break;
                                case 8: text = 'ก.ย.'; break;
                                case 9: text = 'ต.ค.'; break;
                                case 10: text = 'พ.ย.'; break;
                                case 11: text = 'ธ.ค.'; break;
                                default: text = ''; break;
                              }
                            } else {
                              switch (value.toInt()) {
                                case 0: text = '2020'; break;
                                case 1: text = '2021'; break;
                                case 2: text = '2022'; break;
                                case 3: text = '2023'; break;
                                case 4: text = '2024'; break;
                                default: text = ''; break;
                              }
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(text, style: style),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                value.toInt().toString(),
                                style: GoogleFonts.kanit(
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            );
                          },
                        ),
                      ),
                      // ช่วยแก้เลข 100 โดนตัดขอบบน
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 15,
                          getTitlesWidget: (value, meta) => const SizedBox.shrink(),
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey[300],
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: isMonthly 
                    ? List.generate(
                        12, 
                        (index) => _makeBarData(index, mockMonthlyData[selectedYear]![index])
                      )
                    : [
                        _makeBarData(0, 30), 
                        _makeBarData(1, 55), 
                        _makeBarData(2, 45), 
                        _makeBarData(3, 80), 
                        _makeBarData(4, 95), 
                      ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: const Color.fromARGB(255, 230, 150, 40), 
          width: 18, 
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100, 
            color: Colors.grey[200],
          ),
        ),
      ],
    );
  }
}