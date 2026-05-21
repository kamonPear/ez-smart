import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bottombar.dart'; 

class ShowChart extends StatefulWidget {
  const ShowChart({super.key});

  @override
  State<ShowChart> createState() => _ShowChartState();
}

class _ShowChartState extends State<ShowChart> {
  int selectedIndex = 2;

  // ตัวแปรสำหรับสลับดูกราฟ รายเดือน / รายปี
  bool isMonthly = true; 
  // ตัวแปรเก็บปีที่ถูกเลือกดูข้อมูล
  String selectedYear = '2024'; 

  // ข้อมูลจำลองสำหรับ 12 เดือน แยกตามปี
  final Map<String, List<double>> mockMonthlyData = {
    '2020': [15, 20, 25, 22, 30, 35, 40, 38, 45, 50, 48, 55],
    '2021': [20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75],
    '2022': [25, 40, 35, 60, 50, 70, 45, 55, 40, 65, 30, 75],
    '2023': [30, 50, 45, 70, 60, 85, 55, 65, 50, 75, 40, 80],
    '2024': [40, 65, 50, 85, 70, 90, 60, 75, 55, 80, 45, 95],
  };

  void onTabSelected(int index) {
    if (index == 0) {
     Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else if(index == 3){
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Mainchicken()),
      );
    } else if(index == 4){
       Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainShowDataFood()),
      );
    }else if(index == 1){
       Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CloseOpenDoor()),
      );
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
          child: Stack(
            children: [
              // --- ส่วนที่ 2: เนื้อหา ---
              Column(
                children: [
                  const SizedBox(height: 270), 

                  // --- กราฟสถิติการเก็บไข่ ---
                  _buildChartCard(),

                  const SizedBox(height: 100), 
                ],
              ),

              // --- ส่วนที่ 3: Header (Logo & Text) ---
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
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
                        // 👇 ปรับข้อความและขนาดฟอนต์ให้เหมือนในรูป
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
                        // 👇 ปรับไอคอนกระดิ่งเป็นสีดำและนำไอคอนขีดๆ ออก
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
                ),
              ),
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

  // ==========================================
  // ส่วนสร้าง Widget กราฟที่สวยงาม
  // ==========================================
  Widget _buildChartCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95), 
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'สถิติการเก็บไข่',
                    style: GoogleFonts.kanit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (isMonthly)
                    // แสดง Dropdown ให้เลือกปีเมื่ออยู่ในโหมดรายเดือน
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
                    // ข้อความแนะนำเมื่ออยู่ในโหมดรายปี
                    Text(
                      'แตะที่กราฟเพื่อดูรายเดือน',
                      style: GoogleFonts.kanit(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isMonthly ? const Color.fromARGB(255, 172, 24, 24) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'เดือน',
                          style: GoogleFonts.kanit(
                            fontSize: 12,
                            color: isMonthly ? Colors.white : Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => isMonthly = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: !isMonthly ? const Color.fromARGB(255, 172, 24, 24) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ปี',
                          style: GoogleFonts.kanit(
                            fontSize: 12,
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
          const SizedBox(height: 25),
          // กราฟที่เลื่อนซ้ายขวาได้
          SizedBox(
            height: 200,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: isMonthly ? 650 : MediaQuery.of(context).size.width - 80,
                padding: const EdgeInsets.only(right: 15), 
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100, 
                    barTouchData: BarTouchData(
                      enabled: true,
                      // ตั้งค่า Tooltip เวลากดให้สวยงาม
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
                      // เมื่อผู้ใช้แตะแท่งกราฟในรายปี จะสลับไปดูรายเดือนของปีนั้นทันที
                      touchCallback: (FlTouchEvent event, barTouchResponse) {
                        if (!event.isInterestedForInteractions || barTouchResponse == null || barTouchResponse.spot == null) {
                          return;
                        }
                        // ถ้าคลิกแบบปล่อยนิ้ว (TapUp) ตอนอยู่โหมดปี
                        if (event is FlTapUpEvent && !isMonthly) {
                          int index = barTouchResponse.spot!.touchedBarGroupIndex;
                          String tappedYear = (2020 + index).toString();
                          setState(() {
                            selectedYear = tappedYear;
                            isMonthly = true; // สลับเป็นรายเดือนให้เลย
                          });
                        }
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      // --- แกน X (ด้านล่าง) ---
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
                      // --- แกน Y (ด้านซ้าย) ---
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
                    // สร้างแท่งกราฟโดยดึงข้อมูลตามปี (selectedYear)
                    barGroups: isMonthly 
                    ? List.generate(
                        12, 
                        (index) => _makeBarData(index, mockMonthlyData[selectedYear]![index])
                      )
                    : [
                        _makeBarData(0, 30), // ยอดรวมปี 2020
                        _makeBarData(1, 55), // ยอดรวมปี 2021
                        _makeBarData(2, 45), // ยอดรวมปี 2022
                        _makeBarData(3, 80), // ยอดรวมปี 2023
                        _makeBarData(4, 95), // ยอดรวมปี 2024
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

  // ฟังก์ชันช่วยสร้างแท่งกราฟ (Bar)
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