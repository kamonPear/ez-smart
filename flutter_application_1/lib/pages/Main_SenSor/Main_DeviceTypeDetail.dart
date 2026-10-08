import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/ez_header.dart';
import '../bottombar.dart';
import '../main_dash.dart';
import '../Data_AdoptChicken/Main_DataChicken_2.dart';
import '../Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'Main_DeviceSummary.dart';
import '../Show_chart.dart';
import '../../widgets/device_icon.dart';

/// รายละเอียดอุปกรณ์ชนิดเดียว (เช่น "DHT22") ทั้งฟาร์ม — แสดงทุกตัวที่มี ว่าอยู่
/// คอกไหน ทำงานอยู่หรือไม่ เปิดจากการแตะการ์ดสรุปในหน้า "อุปกรณ์ทั้งฟาร์ม"
class MainDeviceTypeDetail extends StatelessWidget {
  final String deviceName;
  final String? iconDataUri;
  final Color color;
  final List<Map<String, dynamic>> devices;

  const MainDeviceTypeDetail({
    super.key,
    required this.deviceName,
    required this.iconDataUri,
    required this.color,
    required this.devices,
  });

  @override
  Widget build(BuildContext context) {
    final ez = ezColors(context);
    final int onlineCount = devices.where((d) {
      final status = d['current_status']?.toString() ?? 'Offline';
      return status.toLowerCase() == 'online';
    }).length;

    // เรียงให้คอกที่ออนไลน์อยู่ก่อน แล้วค่อยตามด้วยชื่อคอก ดูง่ายว่าตัวไหนน่ากังวล
    final sorted = [...devices]
      ..sort((a, b) {
        final aOnline =
            (a['current_status']?.toString() ?? '').toLowerCase() == 'online';
        final bOnline =
            (b['current_status']?.toString() ?? '').toLowerCase() == 'online';
        if (aOnline != bOnline) return aOnline ? -1 : 1;
        final aName = (a['name_coop'] ?? '').toString();
        final bName = (b['name_coop'] ?? '').toString();
        return aName.compareTo(bName);
      });

    return Scaffold(
      extendBody: true,
      backgroundColor: ezBackgroundColor(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: EzHeader(pageTitle: deviceName),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: ezCardDecoration(context, radius: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DeviceIcon(iconDataUri: iconDataUri, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  deviceName,
                                  style: GoogleFonts.kanit(
                                    color: ez.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'ทั้งหมด ${devices.length} ตัว',
                                  style: GoogleFonts.kanit(
                                    color: ez.textSecondary,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '$onlineCount / ${devices.length}',
                            style: GoogleFonts.kanit(
                              color: onlineCount > 0
                                  ? ez.accentGreen
                                  : ez.danger,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ออนไลน์',
                            style: GoogleFonts.kanit(
                              color: ez.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (sorted.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'ไม่มีอุปกรณ์ชนิดนี้',
                            style: GoogleFonts.kanit(
                              color: ez.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      )
                    else
                      ...sorted.map((d) => _buildDeviceRow(context, d)),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: null,
        onTabSelected: (index) => _onTabSelected(context, index),
      ),
    );
  }

  // ✅ หน้านี้ไม่ใช่ 1 ใน 5 แท็บของแถบเมนูล่าง (เป็นหน้าลึกที่แตะเข้ามาจาก
  // "อุปกรณ์ทั้งฟาร์ม") จึงไม่ต้องเก็บ selectedIndex - กดแท็บไหนก็เด้งไปหน้านั้นเสมอ
  void _onTabSelected(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainDeviceSummary()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ShowChart()),
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
    }
  }

  Widget _buildDeviceRow(BuildContext context, Map<String, dynamic> d) {
    final ez = ezColors(context);
    final String status = d['current_status']?.toString() ?? 'Offline';
    final bool isOnline = status.toLowerCase() == 'online';
    final String coopName =
        (d['name_coop']?.toString().trim().isNotEmpty == true)
        ? d['name_coop'].toString()
        : 'คอก ${d['coop_id'] ?? '-'}';
    final statusColor = isOnline ? ez.accentGreen : ez.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: ezCardDecoration(context, radius: 14),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coopName,
                  style: GoogleFonts.kanit(
                    color: ez.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (d['slot_index'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'ช่องที่ ${d['slot_index']}',
                    style: GoogleFonts.kanit(
                      color: ez.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isOnline ? 'ทำงานอยู่' : 'ออฟไลน์',
              style: GoogleFonts.kanit(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
