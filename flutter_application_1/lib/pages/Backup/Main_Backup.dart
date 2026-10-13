import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../services/api_client.dart';
import '../../services/backend_config.dart';
import '../../widgets/ez_header.dart';

/// ตารางข้อมูลที่สำรองได้: (ชื่อไทย, key/ชื่อตาราง, path ของ API)
const List<(String, String, String)> _kBackupSources = [
  ('คอกไก่', 'coops', '/api/coops'),
  ('อุปกรณ์/เซนเซอร์', 'devices', '/api/devices'),
  ('สุขภาพไก่', 'healths', '/api/healths'),
  ('ข้อมูลไข่', 'eggs', '/api/eggs'),
  ('สต็อกอาหาร', 'foods', '/api/foods'),
  ('ประวัติอาหาร', 'food_history', '/api/food_history'),
  ('นัดวัคซีน', 'vaccine_alerts', '/api/vaccines/alerts'),
  ('ชนิดวัคซีน', 'vaccine_schedule', '/api/vaccines/schedule'),
  ('ค่ามาตรฐานฟาร์ม', 'farm_threshold', '/api/farm-threshold'),
];

// ประวัติวัคซีนต้องขอรายคอก จึงไม่อยู่ในรายการ path ตรงๆ ด้านบน
const String _kVaccineHistoryKey = 'vaccine_history';

/// กลุ่มข้อมูลที่ผู้ใช้เลือกสำรอง 1 กลุ่ม = 1 การ์ด (อาจรวมหลายตารางข้างใน)
class _BackupGroup {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final List<String> keys;
  const _BackupGroup(
    this.id,
    this.emoji,
    this.title,
    this.description,
    this.keys,
  );
}

const List<_BackupGroup> _kGroups = [
  _BackupGroup(
    'coops',
    '🏠',
    'คอกไก่',
    'ชื่อคอก จำนวนไก่ วันเกิดไก่ วันรับเข้าเลี้ยง หมายเหตุ ตำแหน่งบนผังฟาร์ม',
    ['coops'],
  ),
  _BackupGroup(
    'devices',
    '📡',
    'อุปกรณ์ / เซนเซอร์',
    'อุปกรณ์ที่วางไว้ในแต่ละคอก ชนิด หมายเลข ตำแหน่งบนผัง',
    ['devices'],
  ),
  _BackupGroup(
    'eggs',
    '🥚',
    'ข้อมูลไข่ไก่',
    'จำนวนไข่ที่เก็บได้ในแต่ละวันของทุกคอก',
    ['eggs'],
  ),
  _BackupGroup(
    'healths',
    '🩺',
    'ประวัติตรวจสุขภาพ',
    'ผลตรวจสุขภาพไก่ (จำนวนไก่ดี/ป่วย) ของทุกคอก',
    ['healths'],
  ),
  _BackupGroup(
    'vaccine_history',
    '💉',
    'วัคซีนที่ให้แล้ว',
    'ประวัติการให้วัคซีน/ยาของแต่ละคอก',
    ['vaccine_history'],
  ),
  _BackupGroup(
    'vaccine_schedule',
    '📋',
    'ประเภทวัคซีน/ยา',
    'รายการวัคซีน/ยาที่ตั้งไว้ พร้อมช่วงอายุที่ให้',
    ['vaccine_schedule'],
  ),
  _BackupGroup(
    'vaccine_alerts',
    '📅',
    'นัดตรวจสุขภาพ',
    'วันนัดตรวจสุขภาพที่กำหนดเอง',
    ['vaccine_alerts'],
  ),
  _BackupGroup(
    'foods',
    '🌾',
    'คลังอาหาร',
    'สต็อกคงเหลือ ประวัตินำเข้า และนำออก/แจกจ่ายอาหาร',
    ['foods', 'food_history'],
  ),
  _BackupGroup(
    'farm_threshold',
    '🌡️',
    'ค่ามาตรฐานของฟาร์ม',
    'อุณหภูมิและแอมโมเนียมาตรฐาน',
    ['farm_threshold'],
  ),
];

enum _BackupFormat { pdf, excel, zip }

/// หน้าสำรองข้อมูล: เลือกรูปแบบไฟล์ + เลือกตาราง แล้วส่งออกเป็นไฟล์ให้แชร์/บันทึก
class MainBackup extends StatefulWidget {
  const MainBackup({super.key});

  @override
  State<MainBackup> createState() => _MainBackupState();
}

class _MainBackupState extends State<MainBackup> {
  _BackupFormat _format = _BackupFormat.pdf;
  bool _loading = true;
  bool _exporting = false;
  String? _error;

  /// key -> ข้อมูลที่ดึงมา (null = ดึงไม่สำเร็จ)
  final Map<String, dynamic> _data = {};
  final Set<String> _failed = {};
  final Set<String> _selected = {};

  /// กลุ่มที่มีข้อมูลจริง (ดึงมาได้อย่างน้อย 1 ตาราง)
  List<_BackupGroup> get _availableGroups =>
      _kGroups.where((g) => g.keys.any(_data.containsKey)).toList();

  List<String> _keysOf(_BackupGroup g) =>
      g.keys.where(_data.containsKey).toList();

  int _groupCount(_BackupGroup g) =>
      _keysOf(g).fold(0, (sum, k) => sum + _countOf(k));

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<dynamic> _fetch(String path) async {
    final response = await ApiClient.get(Uri.parse('$backendBaseUrl$path'));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
      _data.clear();
      _failed.clear();
    });

    await Future.wait(
      _kBackupSources.map((s) async {
        try {
          _data[s.$2] = await _fetch(s.$3);
        } catch (e) {
          debugPrint('Backup: ดึง ${s.$3} ไม่สำเร็จ: $e');
          _failed.add(s.$2);
        }
      }),
    );

    // ประวัติการให้วัคซีน: GET /api/vaccines?coop_id=X ต้องขอทีละคอก
    final coops = _data['coops'];
    if (coops is List) {
      final history = <dynamic>[];
      for (final c in coops.whereType<Map>()) {
        final id = (c['coop_id'] ?? c['id'])?.toString();
        if (id == null) continue;
        try {
          final rows = await _fetch('/api/vaccines?coop_id=$id');
          if (rows is List) history.addAll(rows);
        } catch (e) {
          debugPrint('Backup: ประวัติวัคซีนคอก $id ไม่สำเร็จ: $e');
          _failed.add(_kVaccineHistoryKey);
        }
      }
      _data[_kVaccineHistoryKey] = history;
    } else {
      _failed.add(_kVaccineHistoryKey);
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _selected.clear();
      if (_data.isEmpty) _error = 'ดึงข้อมูลจากเซิร์ฟเวอร์ไม่ได้';
    });
  }

  // ---------- แปลงข้อมูลเป็นตาราง (แถว/คอลัมน์) ----------

  List<Map<String, dynamic>> _rowsOf(dynamic value) {
    if (value is List) {
      return [
        for (final r in value)
          if (r is Map) r.map((k, v) => MapEntry(k.toString(), v)),
      ];
    }
    if (value is Map) {
      return [value.map((k, v) => MapEntry(k.toString(), v))];
    }
    return [];
  }

  String _cell(dynamic v) {
    if (v == null) return '';
    if (v is Map || v is List) return jsonEncode(v);
    return v.toString();
  }

  List<String> _columnsOf(List<Map<String, dynamic>> rows) {
    final cols = <String>[];
    for (final r in rows) {
      for (final k in r.keys) {
        if (!cols.contains(k)) cols.add(k);
      }
    }
    return cols;
  }

  int _countOf(String key) => _rowsOf(_data[key]).length;

  // ---------- สร้างไฟล์ ----------

  List<int> _buildExcel(List<String> keys) {
    final excel = Excel.createExcel();
    for (final key in keys) {
      final rows = _rowsOf(_data[key]);
      final cols = _columnsOf(rows);
      final sheet = excel[key];
      sheet.appendRow([for (final c in cols) TextCellValue(c)]);
      for (final r in rows) {
        sheet.appendRow([for (final c in cols) TextCellValue(_cell(r[c]))]);
      }
    }
    // ลบชีตเริ่มต้นที่ไม่ได้ใช้
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && !keys.contains(defaultSheet)) {
      excel.delete(defaultSheet);
    }
    return excel.encode() ?? <int>[];
  }

  /// รายงาน PDF: หัวเรื่อง + ตารางข้อมูลของแต่ละกลุ่มที่เลือก (A4 แนวนอน)
  /// ฝังฟอนต์ Sarabun เพราะฟอนต์เริ่มต้นของ PDF แสดงภาษาไทยไม่ได้
  Future<List<int>> _buildPdf(List<String> keys, DateTime now) async {
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Sarabun-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Sarabun-Bold.ttf'),
    );
    final labels = {
      for (final g in _kGroups)
        for (final k in g.keys) k: g.title,
    };

    String clip(String v) => v.length > 60 ? '${v.substring(0, 57)}...' : v;

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );
    final stamp =
        '${now.day}/${now.month}/${now.year + 543} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} น.';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'หน้า ${ctx.pageNumber}/${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
        build: (ctx) {
          final widgets = <pw.Widget>[
            pw.Text(
              'EZ - SMART FARM : สำรองข้อมูล',
              style: pw.TextStyle(font: bold, fontSize: 20),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'สร้างเมื่อ $stamp',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
          ];
          for (final key in keys) {
            final rows = _rowsOf(_data[key]);
            final cols = _columnsOf(rows);
            widgets.add(pw.SizedBox(height: 16));
            widgets.add(
              pw.Text(
                '${labels[key] ?? key} ($key) - ${rows.length} รายการ',
                style: pw.TextStyle(font: bold, fontSize: 13),
              ),
            );
            widgets.add(pw.SizedBox(height: 6));
            if (cols.isEmpty) {
              widgets.add(pw.Text('ไม่มีข้อมูล'));
              continue;
            }
            widgets.add(
              pw.TableHelper.fromTextArray(
                headers: cols,
                data: [
                  for (final r in rows)
                    [for (final c in cols) clip(_cell(r[c]))],
                ],
                headerStyle: pw.TextStyle(font: bold, fontSize: 8),
                cellStyle: const pw.TextStyle(fontSize: 8),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 3,
                  vertical: 2,
                ),
                border: pw.TableBorder.all(
                  color: PdfColors.grey500,
                  width: 0.4,
                ),
              ),
            );
          }
          return widgets;
        },
      ),
    );
    return doc.save();
  }

  Future<void> _export() async {
    final keys = [
      for (final g in _kGroups)
        if (_selected.contains(g.id)) ..._keysOf(g),
    ];
    if (keys.isEmpty) return;

    setState(() {
      _exporting = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final stamp =
          '${now.year}${two(now.month)}${two(now.day)}-${two(now.hour)}${two(now.minute)}';
      final base = 'ez-smart-backup-$stamp';

      late final List<int> bytes;
      late final String name;
      late final String mime;

      switch (_format) {
        case _BackupFormat.pdf:
          bytes = await _buildPdf(keys, now);
          name = '$base.pdf';
          mime = 'application/pdf';
        case _BackupFormat.excel:
          bytes = _buildExcel(keys);
          name = '$base.xlsx';
          mime =
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        case _BackupFormat.zip:
          final archive = Archive();
          final pdf = await _buildPdf(keys, now);
          final xlsx = _buildExcel(keys);
          archive.addFile(ArchiveFile('$base.pdf', pdf.length, pdf));
          archive.addFile(ArchiveFile('$base.xlsx', xlsx.length, xlsx));
          bytes = ZipEncoder().encode(archive) ?? <int>[];
          name = '$base.zip';
          mime = 'application/zip';
      }

      if (bytes.isEmpty) throw Exception('สร้างไฟล์ไม่สำเร็จ');

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(Uint8List.fromList(bytes), mimeType: mime)],
          fileNameOverrides: [name],
          subject: 'สำรองข้อมูล EZ-SMART FARM',
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = 'สำรองข้อมูลไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final ez = ezColors(context);
    final available = _availableGroups;
    final allSelected =
        available.isNotEmpty && _selected.length == available.length;
    final badge = switch (_format) {
      _BackupFormat.pdf => 'PDF',
      _BackupFormat.excel => 'XLSX',
      _BackupFormat.zip => 'ZIP',
    };

    return Scaffold(
      backgroundColor: ezBackgroundColor(context),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: EzHeader(pageTitle: 'สำรองข้อมูล'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                children: [
                  _card(
                    context,
                    title: 'เลือกรูปแบบไฟล์',
                    child: Row(
                      children: [
                        _formatTile(
                          _BackupFormat.pdf,
                          Icons.picture_as_pdf_outlined,
                          'PDF',
                          '.pdf',
                          'เอกสารอ่าน/พิมพ์ได้',
                        ),
                        const SizedBox(width: 10),
                        _formatTile(
                          _BackupFormat.excel,
                          Icons.table_chart_outlined,
                          'Excel',
                          '.xlsx',
                          'หนึ่งชีตต่อหนึ่งตาราง',
                        ),
                        const SizedBox(width: 10),
                        _formatTile(
                          _BackupFormat.zip,
                          Icons.archive_outlined,
                          'ทั้ง 2 รูปแบบ',
                          '.zip',
                          'รวม PDF และ Excel ในไฟล์ ZIP',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: ez.accentGreen,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'เลือกข้อมูลที่ต้องการสำรอง',
                          style: GoogleFonts.kanit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ez.textPrimary,
                          ),
                        ),
                      ),
                      if (available.isNotEmpty)
                        InkWell(
                          onTap: () => setState(() {
                            if (allSelected) {
                              _selected.clear();
                            } else {
                              _selected
                                ..clear()
                                ..addAll(available.map((g) => g.id));
                            }
                          }),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              allSelected ? 'ยกเลิกทั้งหมด' : 'เลือกทั้งหมด',
                              style: GoogleFonts.kanit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: ez.accentGreen,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    for (final g in _kGroups) _groupCard(context, g, badge),
                  if (_failed.isNotEmpty && !_loading) ...[
                    const SizedBox(height: 10),
                    Text(
                      'ดึงข้อมูลบางตารางไม่สำเร็จ จึงไม่รวมในการสำรอง',
                      style: GoogleFonts.kanit(fontSize: 12, color: ez.danger),
                    ),
                    TextButton.icon(
                      onPressed: _loadAll,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text('ลองใหม่', style: GoogleFonts.kanit()),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: GoogleFonts.kanit(fontSize: 13, color: ez.danger),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: (_loading || _exporting || _selected.isEmpty)
                      ? null
                      : _export,
                  icon: _exporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_rounded),
                  label: Text(
                    _exporting
                        ? 'กำลังสร้างไฟล์...'
                        : 'สำรองข้อมูล (${_selected.length} รายการ)',
                    style: GoogleFonts.kanit(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(
    BuildContext context, {
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    final ez = ezColors(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ezCardDecoration(context, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.kanit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ez.textPrimary,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _formatTile(
    _BackupFormat format,
    IconData icon,
    String title,
    String ext,
    String desc,
  ) {
    final ez = ezColors(context);
    final selected = _format == format;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _format = format),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected
                ? ez.accentGreen.withValues(alpha: 0.1)
                : ez.inputFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? ez.accentGreen : ez.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: selected ? ez.accentGreen : ez.textSecondary),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: title,
                  style: GoogleFonts.kanit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: ez.textPrimary,
                  ),
                  children: [
                    TextSpan(
                      text: ' $ext',
                      style: GoogleFonts.kanit(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: ez.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.kanit(fontSize: 10, color: ez.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _groupCard(BuildContext context, _BackupGroup g, String badge) {
    final ez = ezColors(context);
    final ok = g.keys.any(_data.containsKey);
    final selected = _selected.contains(g.id);
    void toggle() => setState(() {
      if (!_selected.add(g.id)) _selected.remove(g.id);
    });
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: ok ? toggle : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? ez.accentGreen.withValues(alpha: 0.08) : ez.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? ez.accentGreen : ez.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Checkbox(
                value: selected,
                onChanged: ok ? (_) => toggle() : null,
                activeColor: ez.accentGreen,
                visualDensity: VisualDensity.compact,
              ),
              Text(g.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.title,
                      style: GoogleFonts.kanit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: ok ? ez.textPrimary : ez.textSecondary,
                      ),
                    ),
                    Text(
                      ok ? g.description : 'ดึงข้อมูลไม่สำเร็จ',
                      style: GoogleFonts.kanit(
                        fontSize: 11,
                        color: ok ? ez.textSecondary : ez.danger,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    ok ? '${_groupCount(g)} รายการ' : '-',
                    style: GoogleFonts.kanit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ez.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ez.inputFill,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ez.border),
                    ),
                    child: Text(
                      badge,
                      style: GoogleFonts.kanit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ez.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
