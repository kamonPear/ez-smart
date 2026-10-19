import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../services/backend_config.dart';
import '../../widgets/ez_header.dart';
import '../bottombar.dart';
import '../main_dash.dart';
import '../Data_AdoptChicken/Main_DataChicken_2.dart';
import '../Show_chart.dart';
import '../Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'Main_DeviceTypeDetail.dart';
import '../../widgets/device_icon.dart';

/// สถานะการทำงานของอุปกรณ์และเซนเซอร์ (ตรงกับหน้าเว็บ Device_summary) แบ่ง 2 ส่วน:
/// 1) อุปกรณ์ = บอร์ด ESP32 ของแต่ละคอก ทำงานอยู่หรือไม่
/// 2) เซนเซอร์ = เซนเซอร์แต่ละชนิดรวมทุกคอก มีกี่ตัว ทำงานกี่ตัว (พัดลม/หลอดไฟ แสดงเป็นเปิด/ปิด)
class MainDeviceSummary extends StatefulWidget {
  const MainDeviceSummary({super.key});

  @override
  State<MainDeviceSummary> createState() => _MainDeviceSummaryState();
}

class _DeviceGroup {
  final String name;
  int total = 0;
  int online = 0;
  // พัดลม/หลอดไฟ (Actuator): "ออนไลน์" ของมันแปลว่ากำลังเปิดอยู่
  bool actuator = false;
  final List<Map<String, dynamic>> devices = [];

  _DeviceGroup(this.name);
}

/// บอร์ด ESP32 ของคอกหนึ่ง - ระบบไม่มีตารางบอร์ดแยก (บอร์ด 1 ตัวดูแล 1 คอก และส่งค่าของทุก
/// อุปกรณ์ในคอกนั้นมาพร้อมกันทาง MQTT) จึงคิดสถานะจากอุปกรณ์ในคอก: ถ้ามีอุปกรณ์ชื่อ ESP32 วางไว้
/// ใช้สถานะของตัวนั้น ไม่งั้นถือว่าบอร์ดทำงานถ้าอุปกรณ์ตัวไหนในคอกยังออนไลน์ หรือเพิ่งส่งข้อมูลมา
/// ไม่เกิน 1 นาที (คิดแบบเดียวกับหน้าเว็บ)
class _Board {
  final String coopName;
  final bool online;
  final DateTime? lastUpdate;
  final int deviceCount;

  _Board(this.coopName, this.online, this.lastUpdate, this.deviceCount);
}

bool _isBoardDevice(Map d) => RegExp(
  r'esp\s*-?\s*32',
  caseSensitive: false,
).hasMatch(d['name']?.toString() ?? '');
bool _isOnlineDevice(Map d) =>
    (d['current_status']?.toString() ?? '').toLowerCase() == 'online';

class _MainDeviceSummaryState extends State<MainDeviceSummary> {
  bool _isLoading = true;
  List<_DeviceGroup> _groups = [];
  List<_Board> _boards = [];
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

  // สีพื้นหลังวงกลมหลังไอคอน แยกตามชนิดอุปกรณ์เพื่อให้กวาดตาแยกชนิดง่าย - ไม่
  // เกี่ยวกับตัวไอคอนเองอีกต่อไป (ไอคอนใช้ SVG จริงจาก backend ผ่าน DeviceIcon)
  Color _colorFor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('mq') || name.contains('แอมโมเนีย')) {
      return Colors.orange.shade700;
    }
    if (lower.contains('dht') || name.contains('อุณหภูมิ')) {
      return Colors.cyan;
    }
    if (name.contains('พัดลม')) return Colors.blueAccent;
    if (name.contains('หลอดไฟ') || name.contains('ไฟ')) return Colors.amber;
    if (lower.contains('pir')) return Colors.purpleAccent;
    if (lower.contains('mc-38') || lower.contains('mc38')) return Colors.teal;
    if (lower.contains('esp')) return Colors.green;
    return Colors.grey;
  }

  Future<void> _fetchDevices() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiClient.get(Uri.parse('$backendBaseUrl/api/devices')),
        ApiClient.get(Uri.parse('$backendBaseUrl/api/coops')),
      ]);
      final devicesResp = results[0];
      final coopsResp = results[1];

      // ✅ ห้ามพึ่ง name_coop ที่ติดมากับตัว device เอง (backend ส่งเป็นค่าว่าง
      // เสมอ) ต้องดึงชื่อจริงจาก /api/coops มาจับคู่กับ coop_id เอง
      Map<String, String> coopNames = {};
      if (coopsResp.statusCode == 200) {
        final List<dynamic> coops = json.decode(coopsResp.body);
        coopNames = {
          for (final c in coops)
            (c['coop_id'] ?? c['id']).toString():
                (c['name_coop']?.toString().trim().isNotEmpty == true)
                ? c['name_coop'].toString()
                : (c['coop_id'] ?? c['id']).toString(),
        };
      }

      if (devicesResp.statusCode == 200) {
        final List<dynamic> devices = json.decode(devicesResp.body);
        final Map<String, _DeviceGroup> byName = {};

        final boards = _buildBoards(devices, coopNames);
        for (final d in devices) {
          final name = d['name']?.toString().trim();
          if (name == null || name.isEmpty || _isBoardDevice(d as Map))
            continue;
          final status = d['current_status']?.toString() ?? 'Offline';
          final isOnline = status.toLowerCase() == 'online';

          final group = byName.putIfAbsent(name, () => _DeviceGroup(name));
          group.total += 1;
          if (isOnline) group.online += 1;
          if ((d['device_type']?.toString() ?? '').toLowerCase() ==
              'actuator') {
            group.actuator = true;
          }
          final device = Map<String, dynamic>.from(d as Map<String, dynamic>);
          final coopId = device['coop_id']?.toString() ?? '';
          device['name_coop'] = coopNames[coopId] ?? 'คอก $coopId';
          group.devices.add(device);
        }

        final groups = byName.values.toList()
          ..sort((a, b) => b.total.compareTo(a.total));

        if (!mounted) return;
        setState(() {
          _groups = groups;
          _boards = boards;
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

  List<_Board> _buildBoards(
    List<dynamic> devices,
    Map<String, String> coopNames,
  ) {
    final Map<String, List<Map>> byCoop = {};
    for (final d in devices) {
      final coopId = (d as Map)['coop_id']?.toString();
      if (coopId == null) continue;
      byCoop.putIfAbsent(coopId, () => []).add(d);
    }
    final now = DateTime.now();
    final boards = <_Board>[];
    byCoop.forEach((coopId, list) {
      DateTime? last;
      for (final d in list) {
        final t = DateTime.tryParse(
          d['last_update']?.toString() ?? '',
        )?.toLocal();
        if (t != null && t.year > 1900 && (last == null || t.isAfter(last)))
          last = t;
      }
      final esp = list.where(_isBoardDevice).toList();
      final online = esp.isNotEmpty
          ? _isOnlineDevice(esp.first)
          : list.any(_isOnlineDevice) ||
                (last != null && now.difference(last).inSeconds <= 60);
      boards.add(
        _Board(
          coopNames[coopId] ?? 'คอก $coopId',
          online,
          last,
          list.where((d) => !_isBoardDevice(d)).length,
        ),
      );
    });
    boards.sort(
      (a, b) => a.online == b.online
          ? a.coopName.compareTo(b.coopName)
          : (a.online ? -1 : 1),
    );
    return boards;
  }

  String _lastSeen(_Board b) {
    final t = b.lastUpdate;
    if (t == null) return 'ยังไม่เคยส่งข้อมูล';
    const m = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return 'ส่งข้อมูลล่าสุด ${t.day} ${m[t.month - 1]} $hh:$mm';
  }

  Widget _sectionTitle(String title, String hint) {
    final ez = ezColors(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.kanit(
              color: ez.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: GoogleFonts.kanit(color: ez.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _summaryBar(String label, String value) {
    final ez = ezColors(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: ezCardDecoration(context, radius: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.kanit(color: ez.textSecondary, fontSize: 13),
          ),
          Text(
            value,
            style: GoogleFonts.kanit(
              color: ez.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardCard(_Board b) {
    final ez = ezColors(context);
    final statusColor = b.online ? ez.accentGreen : Colors.redAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: ezCardDecoration(context, radius: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ez.accentGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.memory_rounded, color: ez.accentGreen, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'บอร์ดคอก ${b.coopName}',
                  style: GoogleFonts.kanit(
                    color: ez.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'ดูแลเซนเซอร์ ${b.deviceCount} ตัว · ${_lastSeen(b)}',
                  style: GoogleFonts.kanit(
                    color: ez.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              b.online ? 'ทำงานอยู่' : 'ออฟไลน์',
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

  Widget _buildGroupCard(_DeviceGroup g) {
    final ez = ezColors(context);
    final color = _colorFor(g.name);
    final iconDataUri = g.devices.isNotEmpty
        ? g.devices.first['icon']?.toString()
        : null;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MainDeviceTypeDetail(
            deviceName: g.name,
            iconDataUri: iconDataUri,
            color: color,
            devices: g.devices,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
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
                    g.name,
                    style: GoogleFonts.kanit(
                      color: ez.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${g.actuator ? 'เปิดอยู่' : 'ทำงานอยู่'} ${g.online} / ${g.total} ตัว',
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
              child: EzHeader(pageTitle: 'สถานะอุปกรณ์และเซนเซอร์'),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
                              child: _buildGroupCard(
                                _DeviceGroup('DHT22')
                                  ..total = 4
                                  ..online = 3,
                              ),
                            ),
                          ),
                        ),
                      )
                    else ...[
                      _sectionTitle(
                        'อุปกรณ์บอร์ด',
                        'บอร์ดที่ติดตั้งในแต่ละคอก ทำหน้าที่อ่านค่าเซนเซอร์และส่งข้อมูลเข้าระบบ',
                      ),
                      _summaryBar(
                        'บอร์ดที่ทำงานอยู่',
                        '${_boards.where((b) => b.online).length} / ${_boards.length} บอร์ด',
                      ),
                      if (_boards.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'ยังไม่มีคอกที่ติดตั้งอุปกรณ์',
                              style: GoogleFonts.kanit(
                                color: ez.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._boards.map(_buildBoardCard),
                      const SizedBox(height: 18),
                      _sectionTitle(
                        'เซนเซอร์',
                        'เซนเซอร์แต่ละชนิดในฟาร์ม แตะเพื่อดูว่าอยู่คอกไหน (พัดลม/หลอดไฟ แสดงเป็นเปิด/ปิด)',
                      ),
                      _summaryBar(
                        'เซนเซอร์ทั้งหมดในฟาร์ม',
                        '$_totalOnline / $_totalDevices ทำงานอยู่',
                      ),
                      if (_groups.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'ยังไม่มีเซนเซอร์ในระบบ',
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
