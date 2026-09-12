import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import 'package:flutter_application_1/pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import 'package:flutter_application_1/pages/Notifications_.dart';
import 'package:flutter_application_1/pages/Show_chart.dart';
import 'package:flutter_application_1/pages/Main_SenSor/Main_DeviceSummary.dart';
import 'package:flutter_application_1/pages/main_dash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../bottombar.dart';
import 'Main_CoopDetail.dart';
import 'Main_Dataadd_adopt2.dart';
import 'Main_EditData_adoptchicken2.dart';
import '../../models/coop.dart';
import '../../services/api_service.dart';
import '../../services/backend_config.dart';
import '../../widgets/ez_header.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../utils/thai_date.dart';

class Adoptchicken extends StatefulWidget {
  const Adoptchicken({super.key});

  @override
  State<Adoptchicken> createState() => _AdoptchickenState();
}

class _AdoptchickenState extends State<Adoptchicken> {
  int? selectedIndex; // ไม่ใช่หน้าในแถบเมนูล่าง จึงไม่ไฮไลต์เมนูไหน
  List<Coop> coopDataList = [];
  bool isLoading = true;
  String? errorMessage;

  // ข้อมูลสุขภาพ/เซนเซอร์ล่าสุดของแต่ละคอก (key = coop_id)
  final Map<String, int> _healthyByCoop = {};
  final Map<String, int> _poorByCoop = {};
  final Map<String, String> _tempByCoop = {};
  final Map<String, String> _ppmByCoop = {};
  // สถิติไข่รายเดือนของแต่ละคอก (key = coop_id -> ปี -> 12 เดือน) ใช้ส่งต่อให้หน้ารายละเอียดคอก
  final Map<String, Map<String, List<double>>> _eggStatsByCoop = {};

  final ApiService api = ApiService(baseUrl: backendBaseUrl);

  String _formatDateFromAPI(String? apiDate) {
    return thaiDateFromIso(apiDate);
  }

  void onTabSelected(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainShowDataFood()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Mainchicken()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainDeviceSummary()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
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
  void initState() {
    super.initState();
    _fetchCoops();
  }

  Future<void> _fetchCoops() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final list = await api.fetchCoops();
      setState(() {
        coopDataList = list;
      });
      await _fetchCoopMetrics();
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// ดึงผลตรวจสุขภาพล่าสุด + ค่าเซนเซอร์ (อุณหภูมิ/แอมโมเนีย) ของแต่ละคอก
  /// ถ้าดึงไม่ได้จะปล่อยว่างไว้ แล้วการ์ดจะแสดงว่ายังไม่มีข้อมูล
  Future<void> _fetchCoopMetrics() async {
    try {
      final healthResponse = await http.get(
        Uri.parse('$backendBaseUrl/api/healths'),
      );
      final deviceResponse = await http.get(
        Uri.parse('$backendBaseUrl/api/devices'),
      );
      final eggResponse = await http.get(Uri.parse('$backendBaseUrl/api/eggs'));

      _healthyByCoop.clear();
      _poorByCoop.clear();
      _tempByCoop.clear();
      _ppmByCoop.clear();
      _eggStatsByCoop.clear();

      if (healthResponse.statusCode == 200) {
        final List<dynamic> healthData = jsonDecode(healthResponse.body);
        for (final h in healthData) {
          final coopId = h['coop_id']?.toString();
          if (coopId == null) continue;
          // รายการหลังสุดของแต่ละคอกคือผลตรวจล่าสุด
          _healthyByCoop[coopId] =
              int.tryParse(h['healthy']?.toString() ?? '') ?? 0;
          _poorByCoop[coopId] =
              int.tryParse(h['poor_health']?.toString() ?? '') ?? 0;
        }
      }

      if (deviceResponse.statusCode == 200) {
        final List<dynamic> deviceData = jsonDecode(deviceResponse.body);
        for (final d in deviceData) {
          final coopId = d['coop_id']?.toString();
          if (coopId == null) continue;
          final name = (d['name'] ?? '').toString().toLowerCase();
          final value = d['value']?.toString() ?? '';
          if (name.contains('อุณหภูมิ') || name.contains('dht')) {
            _tempByCoop[coopId] = value;
          } else if (name.contains('แอมโมเนีย') || name.contains('mq')) {
            _ppmByCoop[coopId] = value;
          }
        }
      }

      if (eggResponse.statusCode == 200) {
        final List<dynamic> eggData = jsonDecode(eggResponse.body);
        for (final egg in eggData) {
          final coopId = egg['coop_id']?.toString();
          if (coopId == null) continue;

          String year = DateTime.now().year.toString();
          int month = DateTime.now().month;
          if (egg['date_collect_egg'] != null) {
            try {
              final parsedDate = DateTime.parse(
                egg['date_collect_egg'].toString(),
              ).toLocal();
              year = parsedDate.year.toString();
              month = parsedDate.month;
            } catch (_) {
              // ใช้วันที่ปัจจุบันแทนถ้าพาร์สไม่ได้
            }
          }

          final amount =
              double.tryParse((egg['number_egg'] ?? '0').toString()) ?? 0.0;

          final coopStats = _eggStatsByCoop.putIfAbsent(coopId, () => {});
          coopStats.putIfAbsent(year, () => List.filled(12, 0.0));
          if (month >= 1 && month <= 12) {
            coopStats[year]![month - 1] += amount;
          }
        }
      }

      if (mounted) setState(() {});
    } catch (_) {
      // ข้อมูลเสริม ดึงไม่ได้ก็ยังแสดงรายการคอกได้ตามปกติ
    }
  }

  /// อายุไก่ (วัน) คำนวณจากวันเกิดจริงในฐานข้อมูล คืน null ถ้าไม่มีวันเกิดที่ใช้ได้
  String? _chickenAgeText(String? isoBirthDate) {
    if (isoBirthDate == null || isoBirthDate.isEmpty) return null;
    final datePart = isoBirthDate.split('T').first;
    if (datePart == '0001-01-01') return null; // ค่าว่างที่ backend (Go) ส่งมา
    final birth = DateTime.tryParse(isoBirthDate);
    if (birth == null) return null;
    final days = DateTime.now().difference(birth).inDays;
    if (days < 0) return null;
    final months = days ~/ 30;
    final remainderDays = days % 30;
    if (months < 1) return '$days วัน';
    return '$days วัน / $months เดือน $remainderDays วัน';
  }

  /// แถวข้อมูลในการ์ด: ไอคอน + ชื่อหัวข้อทางซ้าย, ค่าทางขวา
  Widget _buildInfoRow(IconData icon, String label, String value) {
    final ez = ezColors(context);
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: ez.textSecondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.kanit(fontSize: 12.5, color: ez.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.kanit(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: ez.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// แถบสุขภาพไก่ของคอก แบ่งสัดส่วนตามจำนวนตัวที่แข็งแรง/ไม่แข็งแรงจริง
  Widget _buildHealthSection(int healthy, int poor) {
    final ez = ezColors(context);
    final total = healthy + poor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.favorite_outline, size: 15, color: ez.textSecondary),
            const SizedBox(width: 8),
            Text(
              'สุขภาพไก่',
              style: GoogleFonts.kanit(fontSize: 12.5, color: ez.textSecondary),
            ),
            const Spacer(),
            if (total == 0)
              Text(
                'ยังไม่มีผลตรวจ',
                style: GoogleFonts.kanit(fontSize: 12, color: ez.textSecondary),
              )
            else ...[
              Icon(Icons.sentiment_satisfied_alt, size: 15, color: ez.success),
              const SizedBox(width: 4),
              Text(
                '$healthy',
                style: GoogleFonts.kanit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: ez.success,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.sentiment_dissatisfied, size: 15, color: ez.danger),
              const SizedBox(width: 4),
              Text(
                '$poor',
                style: GoogleFonts.kanit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: ez.danger,
                ),
              ),
            ],
          ],
        ),
        if (total > 0) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                // ต้อง stretch ไม่งั้น ColoredBox ที่ไม่มี child จะยุบเหลือสูง 0
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (healthy > 0)
                    Expanded(
                      flex: healthy,
                      child: ColoredBox(color: ez.success),
                    ),
                  if (poor > 0)
                    Expanded(
                      flex: poor,
                      child: ColoredBox(color: ez.danger),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// ป้ายค่าเซนเซอร์ (อุณหภูมิ / แอมโมเนีย) แสดงค่าล่าสุดของคอกนั้น
  Widget _buildSensorChip({
    required IconData icon,
    required String label,
    required String? value,
    required String unit,
    required Color color,
  }) {
    final ez = ezColors(context);
    final hasValue = value != null && value.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.kanit(
                    fontSize: 10.5,
                    color: ez.textSecondary,
                  ),
                ),
                Text(
                  hasValue ? '$value $unit' : 'ไม่มีข้อมูล',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.kanit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: hasValue ? ez.textPrimary : ez.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// สรุปภาพรวมด้านบน: จำนวนคอกทั้งหมด และจำนวนไก่รวมทุกคอก
  Widget _buildSummaryBar() {
    final ez = ezColors(context);
    final totalChickens = coopDataList.fold<int>(
      0,
      (sum, c) =>
          sum + (int.tryParse(c.count.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ez.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.home_work_outlined, size: 18, color: ez.gold),
          const SizedBox(width: 8),
          Text(
            'ทั้งหมด ${coopDataList.length} คอก',
            style: GoogleFonts.kanit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ez.textPrimary,
            ),
          ),
          const Spacer(),
          Text('🐔', style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 6),
          Text(
            'รวม $totalChickens ตัว',
            style: GoogleFonts.kanit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ez.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final ez = ezColors(context);
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Text('🐔', style: const TextStyle(fontSize: 54)),
          const SizedBox(height: 14),
          Text(
            'ยังไม่มีข้อมูลคอกไก่',
            style: GoogleFonts.kanit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ez.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'กดปุ่ม + ด้านล่างขวาเพื่อเพิ่มคอกไก่',
            style: GoogleFonts.kanit(fontSize: 13, color: ez.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCoopCard({required int index, required Coop coop}) {
    final ez = ezColors(context);

    // ✅ ลบคำว่า "ตัว" และช่องว่าง ออกจากตัวแปร count เผื่อมีบันทึกติดมาในฐานข้อมูล
    final String cleanCount = coop.count.replaceAll(RegExp(r'ตัว|\s'), '');
    final String importDate = _formatDateFromAPI(coop.importDate);
    final String birthDate = _formatDateFromAPI(coop.birthDate);
    final String? ageText = _chickenAgeText(coop.birthDate);
    final String note = coop.note.trim();
    final bool hasNote = note.isNotEmpty && note != '-';

    // ส่งวันที่แบบ ISO ดิบเข้าไปให้หน้าแก้ไข (ไม่ใช่ข้อความไทยที่ใช้แสดงผล)
    // ไม่งั้นหน้าแก้ไขจะแปลงกลับไม่ได้ แล้วบันทึกทับวันที่เป็นค่าว่าง
    void openActions() => _showActionDialog(
      index: index,
      id: coop.id,
      name: coop.name,
      importDate: coop.importDate,
      count: coop.count,
      birthDate: coop.birthDate,
      note: coop.note,
    );

    void openDetail() => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoopDetailPage(
          coop: {
            "id": coop.id,
            "name": coop.name,
            "amount": coop.count,
            "import_date": importDate,
            "birth_date": birthDate,
            "healthy": (_healthyByCoop[coop.id] ?? 0).toString(),
            "poor_health": (_poorByCoop[coop.id] ?? 0).toString(),
            "temp": _tempByCoop[coop.id] ?? "0",
            "ppm": _ppmByCoop[coop.id] ?? "0",
            "egg_data": _eggStatsByCoop[coop.id] ?? {},
          },
        ),
      ),
    );

    return Material(
      color: ezCardColor(context),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: openDetail,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          // แตะที่การ์ดเพื่อดูข้อมูลของคอกนี้ กดปุ่ม 3 จุดเพื่อจัดการ (แก้ไข/ลบ)
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // แถวบน: รูปไก่ + ชื่อคอก + จำนวนไก่ + ปุ่มจัดการ
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: ez.textPrimary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text('🐔', style: TextStyle(fontSize: 23)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'คอกไก่ ${coop.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.kanit(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: ez.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                cleanCount,
                                style: GoogleFonts.kanit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                  color: ez.danger,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'ตัว',
                                style: GoogleFonts.kanit(
                                  fontSize: 13,
                                  color: ez.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: openActions,
                      tooltip: 'จัดการคอกไก่',
                      icon: Icon(Icons.more_vert, color: ez.textSecondary),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 6, top: 10),
                  child: Column(
                    children: [
                      Divider(color: ez.border, height: 1),
                      if (ageText != null)
                        _buildInfoRow(
                          Icons.hourglass_bottom_outlined,
                          'อายุไก่',
                          ageText,
                        ),
                      _buildInfoRow(
                        Icons.calendar_today_outlined,
                        'วันที่นำเข้า',
                        importDate,
                      ),
                      _buildInfoRow(
                        Icons.egg_outlined,
                        'วันเกิดไก่',
                        birthDate,
                      ),
                      if (hasNote)
                        _buildInfoRow(
                          Icons.sticky_note_2_outlined,
                          'หมายเหตุ',
                          note,
                        ),
                      const SizedBox(height: 14),
                      _buildHealthSection(
                        _healthyByCoop[coop.id] ?? 0,
                        _poorByCoop[coop.id] ?? 0,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSensorChip(
                              icon: Icons.thermostat,
                              label: 'อุณหภูมิ',
                              value: _tempByCoop[coop.id],
                              unit: '°C',
                              color: const Color(0xFF33C7CC),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildSensorChip(
                              icon: Icons.air,
                              label: 'แอมโมเนีย',
                              value: _ppmByCoop[coop.id],
                              unit: 'PPM',
                              color: const Color(0xFFE58940),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showActionDialog({
    required int index,
    required String id,
    required String name,
    required String importDate,
    required String count,
    required String birthDate,
    required String note,
  }) {
    final ez = ezColors(context);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: ezCardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'จัดการคอกไก่ $name',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.kanit(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: ez.textPrimary,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    // แก้ไขข้อมูล
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditDataAdoptchicken(
                                initialData: {
                                  "id": id,
                                  "name": name,
                                  "importDate": importDate,
                                  "count": count,
                                  "birthDate": birthDate,
                                  "note": note,
                                },
                              ),
                            ),
                          );

                          if (result != null && result is Map<String, String>) {
                            setState(() {
                              coopDataList[index] = Coop(
                                id: result['id'] ?? '',
                                name: result['name'] ?? name,
                                importDate: result['importDate'] ?? '',
                                count: result['count'] ?? '',
                                birthDate: result['birthDate'] ?? '',
                                note: result['note'] ?? '',
                              );
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ez.gold,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                          size: 19,
                        ),
                        label: Text(
                          'แก้ไขข้อมูล',
                          style: GoogleFonts.kanit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: ezBackgroundColor(context),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: EzHeader(pageTitle: 'ข้อมูลคอกไก่'),
              ),
            ),
          ),

          Positioned(
            top: 180,
            left: 0,
            right: 0,
            bottom: 80,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  if (!isLoading && coopDataList.isNotEmpty) ...[
                    _buildSummaryBar(),
                    const SizedBox(height: 16),
                  ],

                  if (isLoading)
                    Skeletonizer(
                      enabled: true,
                      child: Column(
                        children: List.generate(
                          3,
                          (index) => _buildCoopCard(
                            index: index,
                            coop: Coop(
                              id: 'placeholder-$index',
                              name: 'คอกไก่',
                              importDate: '2026-08-19T00:00:00Z',
                              count: '200',
                              birthDate: '2026-07-31T00:00:00Z',
                              note: '',
                            ),
                          ),
                        ),
                      ),
                    ),

                  if (!isLoading &&
                      errorMessage == null &&
                      coopDataList.isEmpty)
                    _buildEmptyState(),

                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'เกิดข้อผิดพลาด: $errorMessage',
                        style: GoogleFonts.kanit(color: Colors.red),
                      ),
                    ),

                  ...coopDataList.asMap().entries.map((entry) {
                    int index = entry.key;
                    Coop data = entry.value;
                    return _buildCoopCard(index: index, coop: data);
                  }),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20, right: 8),
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddDataadopt()),
            );

            if (result != null && result is Map<String, String>) {
              setState(() {
                coopDataList.add(
                  Coop(
                    id: result['id'] ?? '',
                    name: result['name'] ?? result['id'] ?? '',
                    importDate: result['importDate'] ?? '',
                    count: result['count'] ?? '',
                    birthDate: result['birthDate'] ?? '',
                    note: result['note'] ?? '',
                  ),
                );
              });
            }
          },
          backgroundColor: const Color(0xFFE74C3C),
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 36, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: CustomBottomBar(
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected,
      ),
    );
  }
}
