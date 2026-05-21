import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Chicken_health_information/Add_Datachicken_health.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Main_SenSor/Data_System.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart'; 
import '../bottombar.dart'; 

class Datasensor extends StatefulWidget {
  const Datasensor({super.key});

  @override
  State<Datasensor> createState() => _DatasensorState();
}

class _DatasensorState extends State<Datasensor> {
  int selectedIndex = 0;

  void onTabSelected(int index) {
    if ( selectedIndex == index ) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else if(index == 1){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CloseOpenDoor()),
      );
    } else if(index == 3){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Mainchicken()),
      );
    } else if(index == 4){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainShowDataFood()),
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
      backgroundColor: Colors.white, 

      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), 
        child: Container(
          constraints: BoxConstraints(minHeight: screenHeight),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/back1.png'),
              fit: BoxFit.fitWidth, 
              alignment: Alignment.topCenter,
            ),
          ),
          child: Stack(
            children: [
              // --- ส่วนที่ 2: เนื้อหาหลัก (Column) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 270), 
                    
                    // --- การ์ดข้อมูลเซนเซอร์ ---
                    // 🌟 อัปเดตข้อมูลให้ตรงกับโครงสร้างใหม่ (รหัสเซนเซอร์, ค่าที่วัดได้, วันเวลา)
                    const SensorDataCard(
                      recordNumber: '1',
                      sensorId: 'SEN-001',
                      measuredValue: '32 °C',
                      recordedDateTime: '27 / 04 / 2569 10:30',
                    ),
                    const SizedBox(height: 15),
                    const SensorDataCard(
                      recordNumber: '2',
                      sensorId: 'SEN-002',
                      measuredValue: '45 %',
                      recordedDateTime: '27 / 04 / 2569 10:35',
                    ),
                    
                    const SizedBox(height: 30), // ระยะห่างก่อนถึงปุ่มเพิ่มข้อมูล

                    // 👇 ปุ่ม "เพิ่มข้อมูล"
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddDatachickenHealth()), 
                      );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 40),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9DE088), 
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          'เพิ่มข้อมูล',
                          style: GoogleFonts.kanit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 120), // เผื่อระยะด้านล่างไม่ให้ปุ่มบัง BottomBar
                  ],
                ),
              ),

              // --- ส่วนที่ 3: Header (Logo + Icons) ---
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
}

// --- เปลี่ยนชื่อ Widget เป็น SensorDataCard และปรับพารามิเตอร์ ---
class SensorDataCard extends StatelessWidget {
  final String recordNumber;
  final String sensorId;
  final String measuredValue;
  final String recordedDateTime;

  // 🌟 ปรับรับค่า Parameters ให้ตรงกับโครงสร้างข้อมูลการวัดค่าเซนเซอร์
  const SensorDataCard({
    super.key,
    required this.recordNumber,
    required this.sensorId,
    required this.measuredValue,
    required this.recordedDateTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFC0D6E4), 
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ข้อมูลเซนเซอร์ ที่ $recordNumber',
            style: GoogleFonts.kanit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // 🌟 ปรับ Label ข้อความให้ตรงตามลำดับในรูปภาพ
          _buildInfoRow('รหัสเซนเซอร์ :', sensorId),
          _buildInfoRow('ค่าที่วัดได้ :', measuredValue),
          _buildInfoRow('วันและเวลาที่บันทึกค่า :', recordedDateTime),

          const SizedBox(height: 10),

          // ปุ่ม Action ด้านล่างขวา
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionButton(
                title: 'แก้ไขข้อมูล', 
                bgColor: const Color(0xFFF1C40F),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const  DataSystem(), // เปลี่ยนเป็นหน้า Edit ที่ถูกต้องได้ในอนาคต
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                title: 'ลบข้อมูล', 
                bgColor: const Color(0xFFFF0000),
                onTap: () {
                  // ใส่คำสั่งลบข้อมูล หรือ Popup Confirm การลบที่นี่
                },
              ),    
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {String? suffixText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.kanit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: GoogleFonts.kanit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          if (suffixText != null) ...[
            const SizedBox(width: 8),
            Text(
              suffixText,
              style: GoogleFonts.kanit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title, 
    required Color bgColor, 
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: GoogleFonts.kanit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}