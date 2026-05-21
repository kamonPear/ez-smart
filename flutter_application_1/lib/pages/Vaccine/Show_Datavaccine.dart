import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:google_fonts/google_fonts.dart';
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
  
  // *** 1. เพิ่มตัวแปรสำหรับเก็บค่า Dropdown ที่ถูกเลือก ***
  String selectedCoop = "ทั้งหมด"; // เริ่มต้นให้แสดง "ทั้งหมด"

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
    } else if(index == 1){

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CloseOpenDoor()),
      );
    }else if(index == 2){
       Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ShowChart()),
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

    List<Map<String, dynamic>> allVaccineData = [
      {
        "coopId": "KC001", // ปรับตัวพิมพ์ใหญ่ให้ตรงกับ Dropdown
        "chickenCount": "100 ตัว",
        "birthDate": "2026-12-10",
        "vaccineDate": "2026-12-30",
        "vaccineType": "ละลายน้ำดื่ม",
        "medName": "วัคซีนกัมโปโร (Gumboro/IBD)",
        "healthyCount": "",
        "unhealthyCount": "",
        "remark": "",
      },
      {
        "coopId": "KC002", 
        "chickenCount": "120 ตัว",
        "birthDate": "2026-12-10",
        "vaccineDate": "2026-12-15",
        "vaccineType": "หยอดตา/จมูก/ปาก",
        "medName": "วัคซีน ND+IB",
        "healthyCount": "115",
        "unhealthyCount": "5",
        "remark": "ไก่ซึมเล็กน้อย",
      },
       {
        "coopId": "KC001",
        "chickenCount": "100 ตัว",
        "birthDate": "2026-12-10",
        "vaccineDate": "2026-12-15",
        "vaccineType": "แทงปีก",
        "medName": "วัคซีนฝีดาษ",
        "healthyCount": "",
        "unhealthyCount": "",
        "remark": "",
      },
      {
        "coopId": "KC001",
        "chickenCount": "100 ตัว",
        "birthDate": "2026-12-10",
        "vaccineDate": "2027-04-01",
        "vaccineType": "ฉีดเข้ากล้ามเนื้อ",
        "medName": "วัคซีนเชื้อตาย เพื่อสร้างภูมิคุ้มกันระยะยาว",
        "healthyCount": "",
        "unhealthyCount": "",
        "remark": "",
      },
      {
        "coopId": "KC001",
        "chickenCount": "100 ตัว",
        "birthDate": "2026-12-10",
        "vaccineDate": "2027-02-01",
        "vaccineType": "ละลายน้ำดื่ม หรือ การพ่นละออง และ ฉีดเข้ากล้ามเนื้อ",
        "medName": "วัคซีนนิวคาสเซิล (ครั้งที่ 2) และหวัดหน้าบวม",
        "healthyCount": "",
        "unhealthyCount": "",
        "remark": "งดน้ำก่อนให้: หากใช้วิธีละลายน้ำ ควรงดน้ำไก่อย่างน้อย 1-2 ชั่วโมงก่อนให้ เพื่อให้ไก่กระหายและกินวัคซีนจนหมดอย่างรวดเร็ว",
      },
      // เพิ่มตัวอย่าง KC003 เพื่อให้เห็นผลการ Filter
      {
        "coopId": "KC003",
        "chickenCount": "80 ตัว",
        "birthDate": "2026-11-05",
        "vaccineDate": "2026-11-20",
        "vaccineType": "ละลายน้ำดื่ม",
        "medName": "วัคซีน ND",
        "healthyCount": "80",
        "unhealthyCount": "0",
        "remark": "แข็งแรงดี",
      },
    ];

    // *** 2. กรองข้อมูลตาม "ประเภทวัคซีน" และ "รหัสคอก" ที่เลือก ***
    List<Map<String, dynamic>> filteredData = allVaccineData.where((data) {
      bool matchType = data["vaccineType"].toString().contains(widget.vaccineTypeFilter);
      bool matchCoop = selectedCoop == "ทั้งหมด" || data["coopId"] == selectedCoop;
      
      return matchType && matchCoop;
    }).toList();


    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            height: screenHeight,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/back1.png'),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),

          Positioned(
            top: 0, 
            left: 0,
            right: 0,
            bottom: 80,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 270), 

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCC850), 
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      "การให้วัคซีน",
                      style: GoogleFonts.kanit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // *** 3. ปรับปรุงปุ่ม "เลือกคอกไก่" ให้ใช้ PopupMenuButton (Dropdown) ***
                  Align(
                    alignment: Alignment.centerRight,
                    child: PopupMenuButton<String>(
                      onSelected: (String value) {
                        setState(() {
                          selectedCoop = value; // อัปเดตค่าเมื่อผู้ใช้เลือก
                        });
                      },
                      // กำหนดสไตล์ของกรอบ Popup ที่เด้งขึ้นมา
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Colors.black, width: 2),
                      ),
                      offset: const Offset(0, 45), // ระยะห่างจากปุ่มตอนเด้งลงมา
                      // ส่วนของปุ่มที่ใช้กด
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4EE3D0), 
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selectedCoop == "ทั้งหมด" ? 'เลือกคอกไก่' : selectedCoop,
                              style: GoogleFonts.kanit(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                          ],
                        ),
                      ),
                      // สร้างรายการตัวเลือก (KC001 - KC004)
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        _buildDropdownItem('ทั้งหมด'), // เพิ่มตัวเลือก "ทั้งหมด" เพื่อล้างฟิลเตอร์
                        _buildDropdownItem('KC001'),
                        _buildDropdownItem('KC002'),
                        _buildDropdownItem('KC003'),
                        _buildDropdownItem('KC004'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "หมวดหมู่: ${widget.vaccineTypeFilter}",
                      style: GoogleFonts.kanit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (filteredData.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Text(
                        "ไม่พบข้อมูลที่ตรงกับเงื่อนไข",
                        style: GoogleFonts.kanit(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  else
                    ...filteredData.map((data) {
                      return _buildVaccineCard(
                        coopId: data["coopId"],
                        chickenCount: data["chickenCount"],
                        birthDate: data["birthDate"],
                        vaccineDate: data["vaccineDate"],
                        vaccineType: data["vaccineType"],
                        medName: data["medName"],
                        healthyCount: data["healthyCount"],
                        unhealthyCount: data["unhealthyCount"],
                        remark: data["remark"],
                      );
                    }),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

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

      bottomNavigationBar: CustomBottomBar(
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected,
      ),
    );
  }

  // *** 4. Widget Helper: สำหรับสร้างรายการตัวเลือกใน Dropdown แบบกำหนดสไตล์ ***
  PopupMenuItem<String> _buildDropdownItem(String value) {
    return PopupMenuItem<String>(
      value: value,
      height: 45, // ปรับความสูงของแต่ละตัวเลือก
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFB4C4F9), // สีฟ้าม่วงอ่อน ตามแบบในรูป
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 2),
              blurRadius: 2,
            ),
          ],
        ),
        child: Text(
          value,
          style: GoogleFonts.kanit(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildVaccineCard({
    required String coopId,
    required String chickenCount,
    required String birthDate,
    required String vaccineDate,
    required String vaccineType,
    required String medName,
    required String healthyCount,
    required String unhealthyCount,
    required String remark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 1.5), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 4),
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
              Expanded(
                child: Text(
                  'รหัสคอก : $coopId',
                  style: GoogleFonts.kanit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      // Action เมื่อกดแก้ไข
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCC850), 
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'แก้ไขข้อมูล',
                        style: GoogleFonts.kanit(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      // Action เมื่อกดลบ
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red, 
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ลบข้อมูล',
                        style: GoogleFonts.kanit(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          _buildInfoText('จำนวนไก่ : $chickenCount'),
          _buildInfoText('วันที่ไก่เกิด : $birthDate'),
          _buildInfoText('วันที่รับวัคซีน : $vaccineDate'),
          _buildInfoText('ประเภทการให้วัคซีน : $vaccineType'),
          _buildInfoText('ชื่อยา : $medName'),
          _buildInfoText('จำนวนไก่ที่สุขภาพดี : $healthyCount'),
          
          // โชว์ฟิลด์เหล่านี้ต่อเมื่อมีข้อมูล หรือรหัสคอกเป็น KC001
          if (unhealthyCount.isNotEmpty || coopId.contains("001")) 
            _buildInfoText('จำนวนไก่ที่สุขภาพไม่ดี : $unhealthyCount'),
          if (remark.isNotEmpty || coopId.contains("001")) 
            _buildInfoText('หมายเหตุ : $remark'),
        ],
      ),
    );
  }

  Widget _buildInfoText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.kanit(
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }
}