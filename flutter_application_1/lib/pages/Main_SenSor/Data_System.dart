import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';

import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/close_open_Door.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async'; // 🔥 เพิ่มเข้ามาเพื่อรองรับการทำระบบ Real-time
import '../bottombar.dart';
import '../../widgets/ez_header.dart';
import '../../services/backend_config.dart';

class DataSystem extends StatefulWidget {
  final String? initialCoopId;

  const DataSystem({super.key, this.initialCoopId});

  @override
  State<DataSystem> createState() => _DataSystemState();
}

class _DataSystemState extends State<DataSystem> {
  int selectedIndex = 0;
  List<dynamic> devices = [];
  List<dynamic> coops = [];
  bool isLoading = true;

  String? selectedCoopId;
  String? selectedDeviceId;
  Timer? _timer; // 🔥 ตัวแปรสำหรับควบคุมการดึงข้อมูลแบบ Real-time

  // ✅ หาชื่อคอกจริงของคอกที่เลือกอยู่ ถ้าไม่มีชื่อค่อย fallback เป็นเลขคอก
  String get _selectedCoopName {
    final match = coops.firstWhere(
      (c) => (c['coop_id'] ?? c['id'])?.toString() == selectedCoopId,
      orElse: () => null,
    );
    if (match == null) return selectedCoopId ?? '-';
    String name = (match['name_coop'] ?? match['coop_name'])?.toString() ?? '';
    return name.trim().isNotEmpty ? name : (selectedCoopId ?? '-');
  }

  @override
  void initState() {
    super.initState();
    selectedCoopId =
        widget.initialCoopId ??
        "1"; // ใช้คอกที่ส่งเข้ามา ถ้าไม่มีค่อย fallback เป็น "1"
    fetchCoops().then((_) {
      fetchDevices();

      // 🔥 ตั้งเวลาให้แอบดึงข้อมูลใหม่มาอัปเดตหน้าจอทุกๆ 3 วินาทีแบบเนียนๆ
      _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        fetchDevices(isBackground: true);
      });
    });
  }

  @override
  void dispose() {
    _timer
        ?.cancel(); // 🔥 สำคัญมาก! ต้องเคลียร์ Timer ทิ้งเมื่อออกจากหน้านี้ แอปจะได้ไม่ค้าง
    super.dispose();
  }

  Future<void> fetchCoops() async {
    try {
      final response = await http.get(
        Uri.parse('$backendBaseUrl/api/coops'),
      );
      if (response.statusCode == 200) {
        setState(() {
          coops = json.decode(response.body);
        });
      }
    } catch (e) {
      print(e);
    }
  }

  // 🔥 ปรับปรุงฟังก์ชันให้รองรับการโหลดแบบเบื้องหลัง (isBackground)
  Future<void> fetchDevices({bool isBackground = false}) async {
    if (!isBackground) {
      setState(() {
        isLoading = true;
      });
    }
    try {
      String url = '$backendBaseUrl/api/devices';
      if (selectedCoopId != null && selectedCoopId!.isNotEmpty) {
        url = '$backendBaseUrl/api/devices?coop_id=$selectedCoopId';
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // 🔥 เพิ่มบรรทัดนี้เข้าไปชั่วคราวเพื่อดูข้อมูลที่ส่งมาจากหลังบ้าน
        print("📡 ข้อมูลจาก API: ${response.body}");

        setState(() {
          devices = json.decode(response.body);
          isLoading = false;

          // เลือกอุปกรณ์ตัวแรกเป็น Default ถ้ามีข้อมูล และยังไม่มีการเลือกอุปกรณ์ค้างไว้
          if (devices.isNotEmpty) {
            if (selectedDeviceId == null) {
              final firstId = (devices[0]['device_id'] ?? devices[0]['id'])
                  ?.toString();
              selectedDeviceId = firstId;
            }
          } else {
            selectedDeviceId = null;
          }
        });
      } else {
        if (!isBackground) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (!isBackground) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String formatDateTime(String rawDate) {
    if (rawDate == '-' || rawDate.isEmpty) return '-';
    try {
      DateTime parsedDate = DateTime.parse(rawDate).toLocal();
      String day = parsedDate.day.toString().padLeft(2, '0');
      String month = parsedDate.month.toString().padLeft(2, '0');
      String year = parsedDate.year.toString();
      String hour = parsedDate.hour.toString().padLeft(2, '0');
      String minute = parsedDate.minute.toString().padLeft(2, '0');
      return '$day/$month/$year เวลา $hour:$minute น.';
    } catch (e) {
      return rawDate;
    }
  }

  void onTabSelected(int index) {
    if (selectedIndex == index) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CloseOpenDoor()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Mainchicken()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainShowDataFood()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ShowChart()),
      );
    } else {
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
      backgroundColor: ezBackgroundColor,

      body: SafeArea(
        child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          constraints: BoxConstraints(minHeight: screenHeight),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const EzHeader(pageTitle: 'อุปกรณ์เซนเซอร์'),
                    const SizedBox(height: 20),

                    // 1. ส่วนหัว เลือกคอก
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              // 🔥 1. เช็ค Value ให้ดึง ID ออกมาให้ถูกต้อง (รองรับทั้ง coop_id และ id)
                              value:
                                  coops.any(
                                    (c) =>
                                        (c['coop_id'] ?? c['id'])?.toString() ==
                                        selectedCoopId,
                                  )
                                  ? selectedCoopId
                                  : null,
                              hint: Text(
                                "เลือกคอก",
                                style: GoogleFonts.kanit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.black,
                                size: 20,
                              ),
                              dropdownColor: Colors.white,
                              style: GoogleFonts.kanit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),

                              // 🔥 2. สร้างรายการตัวเลือก โดยดึงข้อมูลจาก Database
                              items: coops.map<DropdownMenuItem<String>>((
                                dynamic coop,
                              ) {
                                // ดึงเลขคอก (ID) จากฐานข้อมูล
                                String id =
                                    (coop['coop_id'] ?? coop['id'])
                                        ?.toString() ??
                                    '?';

                                // ดึงชื่อคอกจริงจากฐานข้อมูล (name_coop) ถ้าไม่มีค่อย fallback เป็นเลขคอก
                                String coopName =
                                    (coop['name_coop'] ?? coop['coop_name'])
                                        ?.toString() ??
                                    '';
                                String displayName = coopName.trim().isNotEmpty
                                    ? "คอก $coopName"
                                    : "คอกที่ $id";

                                return DropdownMenuItem<String>(
                                  value: id,
                                  child: Text(displayName),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    selectedCoopId = newValue;
                                    selectedDeviceId =
                                        null; // เคลียร์ค่าอุปกรณ์เดิมออกเมื่อสลับคอกใหม่
                                  });
                                  fetchDevices();
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "สถานะ (บอร์ดคอก $_selectedCoopName)",
                          style: GoogleFonts.kanit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 2. Grid สถานะเซนเซอร์แบบ Dynamic (ดึงข้อมูลจาก API จริง)
                    Container(
                      padding: const EdgeInsets.all(16),
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
                      child: isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : devices.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text(
                                  "ไม่พบอุปกรณ์ในคอกนี้",
                                  style: GoogleFonts.kanit(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 0.85,
                                  ),
                              itemCount: devices.length,
                              itemBuilder: (context, index) {
                                return _buildSensorCard(devices[index]);
                              },
                            ),
                    ),

                    const SizedBox(height: 20),

                    // 3. ฟอร์มรายละเอียดข้อมูลเซนเซอร์
                    _buildDetailsForm(),

                    const SizedBox(height: 120),
                  ],
                ),
              ),
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

  // ====================== WIDGET COMPONENTS ======================

  // ฟังก์ชันวาดการ์ดเซนเซอร์แบบดึงข้อมูลจาก Map วัตถุจริง
  Widget _buildSensorCard(dynamic device) {
    String name = device['name']?.toString() ?? "-";
    String value = device['value']?.toString() ?? "-";
    String status =
        device['current_status']?.toString() ??
        device['status']?.toString() ??
        "Offline";
    bool isOnline = status.toLowerCase() == "online";

    String deviceId = (device['device_id'] ?? device['id'])?.toString() ?? "";
    bool isSelected = selectedDeviceId == deviceId;

    // เลือก Icon อัตโนมัติตามชื่อเซนเซอร์
    IconData icon = Icons.device_thermostat; // ค่าเริ่มต้นเป็น อุณหภูมิ
    if (name.toLowerCase().contains('mq') || name.contains('แอมโมเนีย')) {
      icon = Icons.shower_outlined;
    } else if (name.contains('พัดลม')) {
      icon = Icons.toys_outlined;
    } else if (name.contains('หลอดไฟ')) {
      icon = Icons.lightbulb_outline;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDeviceId = deviceId;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF334155) : const Color(0xFF2A3A4C),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: Colors.blueAccent, width: 2)
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 32),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    style: GoogleFonts.kanit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value != "-" ? "$value" : "-",
                    style: GoogleFonts.kanit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.greenAccent : Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsForm() {
    dynamic selectedDeviceData;
    try {
      selectedDeviceData = devices.firstWhere((device) {
        String id = (device['device_id'] ?? device['id'])?.toString() ?? '';
        return id == selectedDeviceId;
      });
    } catch (_) {
      selectedDeviceData = null;
    }

    String sensorName = selectedDeviceData?['name']?.toString() ?? "-";
    String sensorValue = selectedDeviceData?['value']?.toString() ?? "-";
    String sensorStatus =
        selectedDeviceData?['current_status']?.toString() ??
        selectedDeviceData?['status']?.toString() ??
        "-";

    // ดึงเวลาอัปเดตล่าสุดจาก API
    String rawDate =
        selectedDeviceData?['timestamp']?.toString() ??
        selectedDeviceData?['last_update']?.toString() ??
        "";
    String sensorTime = rawDate.isNotEmpty ? formatDateTime(rawDate) : "-";

    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value:
                        devices.any(
                          (d) =>
                              (d['device_id'] ?? d['id'])?.toString() ==
                              selectedDeviceId,
                        )
                        ? selectedDeviceId
                        : null,
                    hint: Text(
                      "เลือกอุปกรณ์",
                      style: GoogleFonts.kanit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.black,
                      size: 16,
                    ),
                    dropdownColor: Colors.white,
                    style: GoogleFonts.kanit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    items: devices.map<DropdownMenuItem<String>>((
                      dynamic device,
                    ) {
                      String id =
                          (device['device_id'] ?? device['id'])?.toString() ??
                          '';
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text(
                          device['name']?.toString() ?? "อุปกรณ์ $id",
                          style: GoogleFonts.kanit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedDeviceId = newValue;
                      });
                    },
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    sensorTime,
                    style: GoogleFonts.kanit(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildInputRow("ชื่อเซนเซอร์", sensorName),
          const SizedBox(height: 12),
          _buildInputRow("ค่าที่วัดได้", sensorValue),
          const SizedBox(height: 12),
          _buildInputRow("สถานะ", sensorStatus),
        ],
      ),
    );
  }

  Widget _buildInputRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: GoogleFonts.kanit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF131D2A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2B3A4A), width: 1.5),
            ),
            child: Text(
              value,
              style: GoogleFonts.kanit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
