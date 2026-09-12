import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../services/backend_config.dart';
import '../../widgets/ez_header.dart';
import '../bottombar.dart';
import '../main_dash.dart';
import '../Data_AdoptChicken/Main_DataChicken_2.dart';
import '../Show_chart.dart';
import '../Data_Food/Main_DataFood_ShowDataFood1.dart';

/// สรุปอุปกรณ์/เซนเซอร์รวมทั้งฟาร์ม - นับจำนวนอุปกรณ์แต่ละชนิดรวมทุกคอก
/// ไม่แสดงซ้ำแยกทีละคอก เอาแค่ยอดรวมทั้งฟาร์มว่ามีกี่ตัว ออนไลน์กี่ตัว
class MainDeviceSummary extends StatefulWidget {
  const MainDeviceSummary({super.key});

  @override
  State<MainDeviceSummary> createState() => _MainDeviceSummaryState();
}

class _DeviceGroup {
  final String name;
  int total = 0;
  int online = 0;

  _DeviceGroup(this.name);
}

class _MainDeviceSummaryState extends State<MainDeviceSummary> {
  bool _isLoading = true;
  List<_DeviceGroup> _groups = [];
  int _totalDevices = 0;
  int _totalOnline = 0;
  int selectedIndex = 1;

  void onTabSelected(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
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
    } else {
      setState(() {
        selectedIndex = index;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  ({IconData icon, Color color}) _iconFor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('mq') || name.contains('แอมโมเนีย')) {
      return (icon: Icons.air, color: Colors.orange.shade700);
    }
    if (lower.contains('dht') || name.contains('อุณหภูมิ')) {
      return (icon: Icons.thermostat, color: Colors.cyan);
    }
    if (name.contains('พัดลม')) {
      return (icon: Icons.toys_outlined, color: Colors.blueAccent);
    }
    if (name.contains('หลอดไฟ') || name.contains('ไฟ')) {
      return (icon: Icons.lightbulb_outline, color: Colors.amber);
    }
    if (lower.contains('pir')) {
      return (icon: Icons.sensors, color: Colors.purpleAccent);
    }
    if (lower.contains('mc-38') || lower.contains('mc38')) {
      return (icon: Icons.door_front_door_outlined, color: Colors.teal);
    }
    if (lower.contains('esp')) {
      return (icon: Icons.developer_board_outlined, color: Colors.green);
    }
    return (icon: Icons.sensors, color: Colors.grey);
  }

  Future<void> _fetchDevices() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$backendBaseUrl/api/devices'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> devices = json.decode(response.body);
        final Map<String, _DeviceGroup> byName = {};

        for (final d in devices) {
          final name = d['name']?.toString().trim();
          if (name == null || name.isEmpty) continue;
          final status = d['current_status']?.toString() ?? 'Offline';
          final isOnline = status.toLowerCase() == 'online';

          final group = byName.putIfAbsent(name, () => _DeviceGroup(name));
          group.total += 1;
          if (isOnline) group.online += 1;
        }

        final groups = byName.values.toList()
          ..sort((a, b) => b.total.compareTo(a.total));

        if (!mounted) return;
        setState(() {
          _groups = groups;
          _totalDevices = groups.fold(0, (sum, g) => sum + g.total);
          _totalOnline = groups.fold(0, (sum, g) => sum + g.online);
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ โหลดข้อมูลอุปกรณ์ไม่สำเร็จ: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildGroupCard(_DeviceGroup g) {
    final ez = ezColors(context);
    final meta = _iconFor(g.name);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ezCardDecoration(context, radius: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(meta.icon, color: meta.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  g.name,
                  style: GoogleFonts.kanit(
                    color: ez.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'ออนไลน์ ${g.online} / ${g.total} ตัว',
                  style: GoogleFonts.kanit(
                    color: ez.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${g.total}',
            style: GoogleFonts.kanit(
              color: ez.gold,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'ตัว',
            style: GoogleFonts.kanit(color: ez.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ez = ezColors(context);
    return Scaffold(
      extendBody: true,
      backgroundColor: ezBackgroundColor(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: EzHeader(pageTitle: 'อุปกรณ์ทั้งฟาร์ม'),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isLoading)
                      Skeletonizer(
                        enabled: true,
                        child: Column(
                          children: List.generate(
                            4,
                            (_) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildGroupCard(_DeviceGroup('DHT22')
                                ..total = 4
                                ..online = 3),
                            ),
                          ),
                        ),
                      )
                    else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        decoration: ezCardDecoration(context, radius: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'อุปกรณ์ทั้งหมดในฟาร์ม',
                              style: GoogleFonts.kanit(
                                color: ez.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '$_totalOnline / $_totalDevices ออนไลน์',
                              style: GoogleFonts.kanit(
                                color: ez.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_groups.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'ยังไม่มีอุปกรณ์ในระบบ',
                              style: GoogleFonts.kanit(
                                color: ez.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._groups.map(
                          (g) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildGroupCard(g),
                          ),
                        ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected,
      ),
    );
  }
}
