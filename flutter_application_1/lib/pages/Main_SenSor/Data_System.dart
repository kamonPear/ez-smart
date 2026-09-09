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
import '../../utils/thai_date.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DataSystem extends StatefulWidget {
  final String? initialCoopId;

  const DataSystem({super.key, this.initialCoopId});

  @override
  State<DataSystem> createState() => _DataSystemState();
}

class _DataSystemState extends State<DataSystem> {
  int? selectedIndex; // ไม่ใช่หน้าในแถบเมนูล่าง จึงไม่ไฮไลต์เมนูไหน
  List<dynamic> devices = [];
  List<dynamic> coops = [];
  bool isLoading = true;

  String? selectedCoopId;
  String? selectedDeviceId;
  Timer? _timer; // 🔥 ตัวแปรสำหรับควบคุมการดึงข้อมูลแบบ Real-time

  @override
  void initState() {
    super.initState();
    // ไม่เดาคอกให้อัตโนมัติอีกต่อไป (เดิม fallback เป็น "1" ทำให้เข้ามาแล้วเจอ
    // คอกที่ไม่มีจริง) ให้ผู้ใช้เลือกเองก่อน ยกเว้นถูกส่งคอกมาจากหน้าอื่นแล้ว
    selectedCoopId = widget.initialCoopId;
    isLoading = false;
    fetchCoops();
    if (selectedCoopId != null) {
      isLoading = true;
      fetchDevices();
      _startAutoRefresh();
    }
  }

  void _startAutoRefresh() {
    // 🔥 ตั้งเวลาให้แอบดึงข้อมูลใหม่มาอัปเดตหน้าจอทุกๆ 3 วินาทีแบบเนียนๆ
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      fetchDevices(isBackground: true);
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
      final response = await http.get(Uri.parse('$backendBaseUrl/api/coops'));
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
      String hour = parsedDate.hour.toString().padLeft(2, '0');
      String minute = parsedDate.minute.toString().padLeft(2, '0');
      return '${thaiDate(parsedDate)} เวลา $hour:$minute น.';
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
      backgroundColor: ezBackgroundColor(context),

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

                      // 1. ตัวเลือกคอก — ถ้ายังไม่เลือกคอก ให้เป็นการ์ดใหญ่ชัดเจน
                      // ชวนให้เลือกก่อน (ไม่โชว์กริด/ฟอร์มรายละเอียดที่ว่างเปล่า)
                      selectedCoopId == null
                          ? _buildChooseCoopCard()
                          : _buildCoopSwitcherBar(),

                      if (selectedCoopId != null) ...[
                        const SizedBox(height: 20),

                        // 2. Grid สถานะเซนเซอร์แบบ Dynamic (ดึงข้อมูลจาก API จริง)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ezCardColor(context),
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
                              ? Skeletonizer(
                                  enabled: true,
                                  child: GridView.count(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: 2.05,
                                    children: List.generate(
                                      4,
                                      (_) => _buildSensorCard({
                                        'name': 'อุณหภูมิ',
                                        'value': '25',
                                        'status': 'online',
                                      }),
                                    ),
                                  ),
                                )
                              : devices.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24,
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.sensors_off_outlined,
                                        size: 40,
                                        color: ezColors(context).textSecondary,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        "ไม่พบอุปกรณ์ในคอกนี้",
                                        style: GoogleFonts.kanit(
                                          color: ezColors(context).textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "ลองเลือกคอกอื่น หรือติดตั้งเซนเซอร์เพิ่มเติม",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.kanit(
                                          color: ezColors(
                                            context,
                                          ).textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 10,
                                        crossAxisSpacing: 10,
                                        childAspectRatio: 2.05,
                                      ),
                                  itemCount: devices.length,
                                  itemBuilder: (context, index) {
                                    return _buildSensorCard(devices[index]);
                                  },
                                ),
                        ),

                        // 3. ฟอร์มรายละเอียดข้อมูลเซนเซอร์ — โชว์ก็ต่อเมื่อมีอุปกรณ์
                        // ให้เลือกดูจริงๆ เท่านั้น ไม่โชว์ฟอร์มว่างเปล่าเป็น "-" ทุกช่อง
                        if (!isLoading && devices.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildDetailsForm(),
                        ],
                      ],

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

  // สร้างรายการตัวเลือกคอกจากฐานข้อมูล ใช้ร่วมกันทั้งการ์ดเลือกคอก
  // ตอนยังไม่เลือก และแถบสลับคอกตอนเลือกแล้ว
  List<DropdownMenuItem<String>> _coopMenuItems() {
    return coops.map<DropdownMenuItem<String>>((dynamic coop) {
      String id = (coop['coop_id'] ?? coop['id'])?.toString() ?? '?';
      String coopName =
          (coop['name_coop'] ?? coop['coop_name'])?.toString() ?? '';
      String displayName = coopName.trim().isNotEmpty
          ? "คอก $coopName"
          : "คอกที่ $id";
      return DropdownMenuItem<String>(
        value: id,
        child: Text(displayName, style: GoogleFonts.kanit()),
      );
    }).toList();
  }

  void _onCoopChanged(String? newValue) {
    if (newValue == null) return;
    setState(() {
      selectedCoopId = newValue;
      selectedDeviceId = null; // เคลียร์ค่าอุปกรณ์เดิมออกเมื่อสลับคอกใหม่
      isLoading = true;
    });
    fetchDevices();
    _startAutoRefresh();
  }

  /// การ์ดชวนเลือกคอกแบบใหญ่ชัดเจน แสดงตอนยังไม่ได้เลือกคอกใดเลย
  Widget _buildChooseCoopCard() {
    final ez = ezColors(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: ezCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ez.gold.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: ez.gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.sensors, color: ez.gold, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            "เลือกคอกไก่ก่อน",
            style: GoogleFonts.kanit(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: ez.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "เพื่อดูสถานะอุปกรณ์และเซนเซอร์ของคอกนั้น",
            textAlign: TextAlign.center,
            style: GoogleFonts.kanit(fontSize: 13, color: ez.textSecondary),
          ),
          const SizedBox(height: 20),
          coops.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    "กำลังโหลดรายชื่อคอก...",
                    style: GoogleFonts.kanit(
                      fontSize: 13,
                      color: ez.textSecondary,
                    ),
                  ),
                )
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: ez.inputFill,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ez.gold, width: 1.6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: null,
                      hint: Row(
                        children: [
                          Icon(Icons.pets_outlined, color: ez.gold, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            "แตะเพื่อเลือกคอก",
                            style: GoogleFonts.kanit(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: ez.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: ez.gold,
                        size: 24,
                      ),
                      dropdownColor: ezCardColor(context),
                      style: GoogleFonts.kanit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ez.textPrimary,
                      ),
                      items: _coopMenuItems(),
                      onChanged: _onCoopChanged,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  /// แถบสลับคอกแบบกะทัดรัด แสดงตอนเลือกคอกแล้ว เปลี่ยนคอกอื่นได้จากตรงนี้เลย
  Widget _buildCoopSwitcherBar() {
    final ez = ezColors(context);
    final bool hasMatch = coops.any(
      (c) => (c['coop_id'] ?? c['id'])?.toString() == selectedCoopId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: ezCardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ez.border, width: 1.2),
          ),
          child: Row(
            children: [
              Icon(Icons.pets_outlined, color: ez.gold, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: hasMatch ? selectedCoopId : null,
                    icon: Icon(
                      Icons.unfold_more_rounded,
                      color: ez.textSecondary,
                      size: 20,
                    ),
                    dropdownColor: ezCardColor(context),
                    style: GoogleFonts.kanit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ez.textPrimary,
                    ),
                    items: _coopMenuItems(),
                    onChanged: _onCoopChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          "สถานะอุปกรณ์",
          style: GoogleFonts.kanit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: ez.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "แตะที่การ์ดด้านล่างเพื่อดูรายละเอียดอุปกรณ์นั้น",
          style: GoogleFonts.kanit(fontSize: 11, color: ez.textSecondary),
        ),
      ],
    );
  }

  /// แปลงชื่อรุ่นของอุปกรณ์ (เช่น MQ-135, DHT22) เป็นคำที่อ่านแล้วรู้เลยว่าวัดอะไร
  /// พร้อมหน่วยและไอคอนประจำชนิดนั้น
  ({String label, String unit, IconData icon, bool isSwitch}) _sensorMeta(
    String name,
  ) {
    final lower = name.toLowerCase();
    if (lower.contains('mq') || name.contains('แอมโมเนีย')) {
      return (
        label: 'แอมโมเนีย',
        unit: 'ppm',
        icon: Icons.air,
        isSwitch: false,
      );
    }
    if (lower.contains('dht') || name.contains('อุณหภูมิ')) {
      return (
        label: 'อุณหภูมิ',
        unit: '°C',
        icon: Icons.thermostat,
        isSwitch: false,
      );
    }
    if (name.contains('พัดลม')) {
      return (
        label: 'พัดลม',
        unit: '',
        icon: Icons.toys_outlined,
        isSwitch: true,
      );
    }
    if (name.contains('หลอดไฟ') || name.contains('ไฟ')) {
      return (
        label: 'หลอดไฟ',
        unit: '',
        icon: Icons.lightbulb_outline,
        isSwitch: true,
      );
    }
    return (label: name, unit: '', icon: Icons.sensors, isSwitch: false);
  }

  // ฟังก์ชันวาดการ์ดเซนเซอร์แบบดึงข้อมูลจาก Map วัตถุจริง
  Widget _buildSensorCard(dynamic device) {
    final ez = ezColors(context);

    String name = device['name']?.toString() ?? "-";
    String value = device['value']?.toString() ?? "-";
    String status =
        device['current_status']?.toString() ??
        device['status']?.toString() ??
        "Offline";
    bool isOnline = status.toLowerCase() == "online";

    String deviceId = (device['device_id'] ?? device['id'])?.toString() ?? "";
    bool isSelected = selectedDeviceId == deviceId;

    final meta = _sensorMeta(name);
    final bool hasValue = value.isNotEmpty && value != "-";

    // อุปกรณ์ที่เป็นสวิตช์ (พัดลม/หลอดไฟ) อ่านค่า 0/1 เป็น ปิด/เปิด
    String valueText;
    if (!hasValue) {
      valueText = 'ไม่มีข้อมูล';
    } else if (meta.isSwitch) {
      valueText = (value == '0' || value.toLowerCase() == 'off')
          ? 'ปิด'
          : 'เปิด';
    } else {
      valueText = meta.unit.isEmpty ? value : '$value ${meta.unit}';
    }

    final Color accent = isOnline ? ez.success : ez.textSecondary;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDeviceId = deviceId;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? ez.gold.withValues(alpha: 0.12) : ez.inputFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? ez.gold : ez.border,
            width: isSelected ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(meta.icon, color: accent, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          meta.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.kanit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ez.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isOnline ? ez.success : ez.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    valueText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.kanit(
                      fontSize: hasValue ? 17 : 12,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                      color: hasValue ? ez.textPrimary : ez.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$name · ${isOnline ? 'ออนไลน์' : 'ออฟไลน์'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.kanit(
                      fontSize: 10,
                      color: ez.textSecondary,
                    ),
                  ),
                ],
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
        color: ezCardColor(context),
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
                  Icon(
                    Icons.calendar_today_outlined,
                    color: ezColors(context).textPrimary,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    sensorTime,
                    style: GoogleFonts.kanit(
                      fontSize: 12,
                      color: ezColors(context).textSecondary,
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
              color: ezColors(context).textPrimary,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ezColors(context).inputFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ezColors(context).border, width: 1.5),
            ),
            child: Text(
              value,
              style: GoogleFonts.kanit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: ezColors(context).textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
