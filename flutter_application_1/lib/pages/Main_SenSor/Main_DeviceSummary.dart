import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../services/backend_config.dart';
import '../../utils/thai_date.dart';
import '../../widgets/ez_header.dart';
import '../bottombar.dart';
import '../main_dash.dart';
import '../Data_AdoptChicken/Main_DataChicken_2.dart';
import '../Show_chart.dart';
import '../Data_Food/Main_DataFood_ShowDataFood1.dart';
import '../../widgets/device_icon.dart';

/// สรุปอุปกรณ์รวมทั้งฟาร์ม แบ่ง 2 ส่วนเหมือนหน้าเว็บ: "อุปกรณ์บอร์ด" (บอร์ดของแต่ละ
/// คอก ออนไลน์อยู่ไหม ส่งข้อมูลล่าสุดเมื่อไร) และ "เซนเซอร์" (นับแต่ละชนิดรวมทุกคอก
/// กดการ์ดเพื่อกางดูว่าอยู่คอกไหนและทำงานอยู่หรือไม่)
class MainDeviceSummary extends StatefulWidget {
  const MainDeviceSummary({super.key});

  @override
  State<MainDeviceSummary> createState() => _MainDeviceSummaryState();
}

// พัดลม/หลอดไฟ เป็นอุปกรณ์ควบคุม - แสดงเป็น "เปิด/ปิด" แทน "ทำงานอยู่/ออฟไลน์"
bool _isActuatorName(String name) {
  final n = name.toLowerCase();
  return n.contains('พัดลม') ||
      n.contains('หลอดไฟ') ||
      n.contains('fan') ||
      n.contains('bulb');
}

bool _isOnlineDevice(Map<String, dynamic> d) =>
    (d['current_status']?.toString() ?? '').toLowerCase() == 'online';

class _DeviceGroup {
  final String name;
  final bool isActuator;
  int total = 0;
  int online = 0;
  final List<Map<String, dynamic>> devices = [];

  _DeviceGroup(this.name) : isActuator = _isActuatorName(name);
}

/// บอร์ดของคอก 1 คอก = 1 บอร์ด (ระบบไม่มีตารางบอร์ดแยก) สรุปจากอุปกรณ์ในคอกนั้น
class _CoopBoard {
  final String coopId;
  final String name;
  int sensorCount = 0;
  bool online = false;
  DateTime? lastUpdate;

  _CoopBoard(this.coopId, this.name);
}

class _MainDeviceSummaryState extends State<MainDeviceSummary> {
  bool _isLoading = true;
  List<_DeviceGroup> _groups = [];
  List<_CoopBoard> _boards = [];
  int _totalDevices = 0;
  int _totalOnline = 0;
  int selectedIndex = 1;

  // ชนิดอุปกรณ์ที่กางดูรายละเอียดอยู่ - กางได้ทีละชนิดเดียว
  String? _expandedName;

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

  // backend ส่งเวลาที่ยังไม่เคยมีข้อมูลเป็น 0001-01-01 (ค่าว่างของ Go) - ถือว่าไม่มีเวลา
  DateTime? _parseLastUpdate(dynamic raw) {
    final parsed = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (parsed == null || parsed.year < 2000) return null;
    return parsed;
  }

  // เช่น "18 ต.ค. 23:46"
  String _formatLastUpdate(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${kThaiMonthsShort[d.month - 1]} $hh:$mm';
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
        final Map<String, _CoopBoard> boardByCoop = {};

        for (final d in devices) {
          final device = Map<String, dynamic>.from(d as Map<String, dynamic>);
          final isOnline = _isOnlineDevice(device);
          final coopId = device['coop_id']?.toString() ?? '';
          final coopName = coopNames[coopId] ?? 'คอก $coopId';
          device['name_coop'] = coopName;

          // บอร์ดนับทุกอุปกรณ์ในคอก (รวมแถวที่ไม่มีชื่อด้วย)
          if (coopId.isNotEmpty) {
            final board = boardByCoop.putIfAbsent(
              coopId,
              () => _CoopBoard(coopId, coopName),
            );
            board.sensorCount += 1;
            if (isOnline) board.online = true;
            final updated = _parseLastUpdate(device['last_update']);
            if (updated != null &&
                (board.lastUpdate == null ||
                    updated.isAfter(board.lastUpdate!))) {
              board.lastUpdate = updated;
            }
          }

          final name = device['name']?.toString().trim();
          if (name == null || name.isEmpty) continue;
          final group = byName.putIfAbsent(name, () => _DeviceGroup(name));
          group.total += 1;
          if (isOnline) group.online += 1;
          group.devices.add(device);
        }

        // เรียงให้ตัวที่ทำงานอยู่ขึ้นก่อน แล้วตามด้วยชื่อคอก ดูง่ายว่าตัวไหนน่ากังวล
        for (final g in byName.values) {
          g.devices.sort((a, b) {
            final aOn = _isOnlineDevice(a);
            final bOn = _isOnlineDevice(b);
            if (aOn != bOn) return aOn ? -1 : 1;
            return (a['name_coop'] ?? '').toString().compareTo(
              (b['name_coop'] ?? '').toString(),
            );
          });
        }

        final groups = byName.values.toList()
          ..sort((a, b) => b.total.compareTo(a.total));
        final boards = boardByCoop.values.toList()
          ..sort(
            (a, b) => (int.tryParse(a.coopId) ?? 0).compareTo(
              int.tryParse(b.coopId) ?? 0,
            ),
          );

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

  Widget _buildSectionHeader(String title, String description) {
    final ez = ezColors(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.kanit(
              color: ez.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: GoogleFonts.kanit(
              color: ez.textSecondary,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(String label, String value) {
    final ez = ezColors(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
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

  Widget _buildIconChip(Widget icon) {
    final ez = ezColors(context);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: ez.accentGreen.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: icon,
    );
  }

  Widget _buildStatusPill(String label, bool on, {double fontSize = 12}) {
    final ez = ezColors(context);
    final color = on ? ez.accentGreen : ez.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.kanit(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBoardCard(_CoopBoard b) {
    final ez = ezColors(context);
    final last = b.lastUpdate == null
        ? 'ยังไม่เคยส่งข้อมูล'
        : 'ส่งข้อมูลล่าสุด ${_formatLastUpdate(b.lastUpdate!)}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: ezCardDecoration(context, radius: 16),
      child: Row(
        children: [
          _buildIconChip(Icon(Icons.memory, color: ez.accentGreen, size: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'บอร์ดคอก ${b.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.kanit(
                    color: ez.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'ดูแลเซนเซอร์ ${b.sensorCount} ตัว · $last',
                  style: GoogleFonts.kanit(
                    color: ez.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusPill(b.online ? 'ออนไลน์' : 'ออฟไลน์', b.online),
        ],
      ),
    );
  }

  Widget _buildGroupCard(_DeviceGroup g) {
    final ez = ezColors(context);
    final isOpen = _expandedName == g.name;
    final iconDataUri = g.devices.isNotEmpty
        ? g.devices.first['icon']?.toString()
        : null;

    final header = InkWell(
      // กางอยู่ให้มุมล่างเหลี่ยม ต่อกับแผงรายละเอียดเป็นชิ้นเดียวกัน
      borderRadius: isOpen
          ? const BorderRadius.vertical(top: Radius.circular(16))
          : BorderRadius.circular(16),
      onTap: () => setState(() => _expandedName = isOpen ? null : g.name),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ezCardColor(context),
          borderRadius: isOpen
              ? const BorderRadius.vertical(top: Radius.circular(16))
              : BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _buildIconChip(DeviceIcon(iconDataUri: iconDataUri, size: 24)),
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
                    '${g.isActuator ? 'เปิดอยู่' : 'ทำงานอยู่'} ${g.online} / ${g.total} ตัว',
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
                color: ez.accentGreen,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'ตัว',
              style: GoogleFonts.kanit(color: ez.textSecondary, fontSize: 13),
            ),
            const SizedBox(width: 8),
            AnimatedRotation(
              turns: isOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: isOpen ? ez.accentGreen : ez.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          header,
          if (isOpen)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              decoration: BoxDecoration(
                color: ezCardColor(context),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                border: Border(top: BorderSide(color: ez.border)),
              ),
              child: Column(
                children: [for (final d in g.devices) _buildDeviceRow(g, d)],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceRow(_DeviceGroup g, Map<String, dynamic> d) {
    final ez = ezColors(context);
    final on = _isOnlineDevice(d);
    final label = g.isActuator
        ? (on ? 'เปิด' : 'ปิด')
        : (on ? 'ทำงานอยู่' : 'ออฟไลน์');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: on ? ez.accentGreen : ez.danger,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (d['name_coop'] ?? '').toString(),
                  style: GoogleFonts.kanit(
                    color: ez.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (d['slot_index'] != null)
                  Text(
                    'หมายเลข ${d['slot_index']}',
                    style: GoogleFonts.kanit(
                      color: ez.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
              ],
            ),
          ),
          _buildStatusPill(label, on, fontSize: 11.5),
        ],
      ),
    );
  }

  Widget _buildEmptyHint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.kanit(
            color: ezColors(context).textSecondary,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent() {
    final boardsOnline = _boards.where((b) => b.online).length;
    return [
      _buildSectionHeader(
        'อุปกรณ์บอร์ด',
        'บอร์ดที่ติดตั้งในแต่ละคอก ทำหน้าที่อ่านค่าเซนเซอร์และส่งข้อมูลเข้าระบบ',
      ),
      _buildSummaryBar(
        'บอร์ดที่ทำงานอยู่',
        '$boardsOnline / ${_boards.length} บอร์ด',
      ),
      if (_boards.isEmpty)
        _buildEmptyHint('ยังไม่มีบอร์ดในระบบ')
      else
        ..._boards.map(_buildBoardCard),

      const SizedBox(height: 22),
      _buildSectionHeader(
        'เซนเซอร์',
        'เซนเซอร์แต่ละชนิดที่ติดตั้งในฟาร์ม กดเพื่อดูว่าอยู่คอกไหนและทำงานหรือไม่ (พัดลม/หลอดไฟ แสดงเป็นเปิด/ปิด)',
      ),
      _buildSummaryBar(
        'เซนเซอร์ทั้งหมดในฟาร์ม',
        '$_totalOnline / $_totalDevices ทำงานอยู่',
      ),
      if (_groups.isEmpty)
        _buildEmptyHint('ยังไม่มีเซนเซอร์ในระบบ')
      else
        ..._groups.map(_buildGroupCard),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: ezBackgroundColor(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: EzHeader(pageTitle: 'เซนเซอร์ทั้งฟาร์ม'),
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
                    else
                      ..._buildContent(),
                    const SizedBox(height: 100),
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
