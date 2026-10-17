import 'dart:convert';

import 'package:flutter/material.dart';

import '../pages/Chicken_health_information/Main_HealthAppointments.dart';
import '../pages/Data_AdoptChicken/Main_CoopDetail.dart';
import '../pages/Data_AdoptChicken/Main_DataChicken_2.dart';
import '../pages/Data_AdoptChicken/Main_Datadopt_chicken_2.dart';
import '../pages/Data_Food/Main_DataFood_ShowDataFood1.dart';
import '../pages/Main_SenSor/Main_DeviceSummary.dart';
import '../pages/Notifications_.dart';
import '../pages/Settings/Main_FarmThresholds.dart';
import '../pages/Show_chart.dart';
import '../pages/Vaccine/Add_VaccineType.dart';
import '../pages/Vaccine/Main_Vaccine.dart';
import '../utils/thai_date.dart';
import 'api_client.dart';
import 'backend_config.dart';

/// ผลค้นหา 1 รายการ - [haystack] คือข้อความทั้งหมดที่ใช้จับคู่คำค้น (ตัวพิมพ์เล็ก)
class SearchEntry {
  final String category;
  final String emoji;
  final String title;
  final String subtitle;
  final String haystack;
  final void Function(BuildContext context) open;

  const SearchEntry({
    required this.category,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.haystack,
    required this.open,
  });
}

/// ค้นหาข้อมูลทั้งแอป (คอก อุปกรณ์ วัคซีน นัดตรวจ สุขภาพ ไข่ อาหาร และเมนู/หน้าต่างๆ)
/// ดึงข้อมูลจาก backend ครั้งเดียวแล้วเก็บแคชไว้ชั่วครู่ ไม่ยิง API ใหม่ทุกครั้งที่พิมพ์
class GlobalSearchService {
  GlobalSearchService._();
  static final GlobalSearchService instance = GlobalSearchService._();

  static const Duration _ttl = Duration(seconds: 60);

  List<SearchEntry> _dataEntries = [];
  DateTime? _loadedAt;
  Future<void>? _loading;

  Future<void> ensureLoaded() {
    final at = _loadedAt;
    if (at != null && DateTime.now().difference(at) < _ttl) {
      return Future.value();
    }
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<List<dynamic>> _getList(String path) async {
    try {
      final response = await ApiClient.get(Uri.parse('$backendBaseUrl$path'));
      if (response.statusCode != 200) return [];
      final decoded = jsonDecode(response.body);
      return decoded is List ? decoded : [];
    } catch (e) {
      debugPrint('GlobalSearch: โหลด $path ไม่สำเร็จ: $e');
      return [];
    }
  }

  static String _s(dynamic v) => (v ?? '').toString();

  /// วันที่แบบไทย + ค่าดิบ ให้พิมพ์ได้ทั้ง "ส.ค." "2569" หรือ "2026-08"
  static String _dateText(dynamic iso) {
    final raw = _s(iso);
    if (raw.isEmpty) return '';
    final d = thaiDateOnlyFromIso(raw);
    if (d == null) return raw;
    return '${thaiDate(d)} ${kThaiMonthsFull[d.month - 1]} ${d.toIso8601String().substring(0, 10)}';
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _getList('/api/coops'),
      _getList('/api/devices'),
      _getList('/api/healths'),
      _getList('/api/eggs'),
      _getList('/api/foods'),
      _getList('/api/vaccines/alerts'),
      _getList('/api/vaccines/schedule'),
    ]);
    final coops = results[0];
    final devices = results[1];
    final healths = results[2];
    final eggs = results[3];
    final foods = results[4];
    final alerts = results[5];
    final schedules = results[6];

    final entries = <SearchEntry>[];

    String coopId(dynamic row) => _s(row['coop_id'] ?? row['id']);
    final coopNames = <String, String>{};
    for (final c in coops) {
      if (c is! Map) continue;
      final id = coopId(c);
      final name = _s(c['name_coop']).trim();
      coopNames[id] = name.isEmpty ? id : name;
    }
    String nameOf(dynamic id) => coopNames[_s(id)] ?? _s(id);

    // ---- คอกไก่ ----
    for (final c in coops) {
      if (c is! Map) continue;
      final id = coopId(c);
      final rawBirthday = _s(c['Birthday'] ?? c['birthday']);
      final importDate = thaiDateFromIso(_s(c['date_adopt_animals']), fallback: 'ไม่ระบุ');
      final birthDate = thaiDateFromIso(rawBirthday, fallback: 'ไม่ระบุ');
      final ageText = chickenAgeFromIso(rawBirthday);
      final name = nameOf(id);
      final amount = _s(c['amount']);

      final coopHealths = healths
          .whereType<Map>()
          .where((h) => _s(h['coop_id']) == id)
          .toList()
        ..sort((a, b) {
          final da = DateTime.tryParse(_s(a['record_date']));
          final db = DateTime.tryParse(_s(b['record_date']));
          if (da == null || db == null) return 0;
          return da.compareTo(db);
        });
      final latest = coopHealths.isNotEmpty ? coopHealths.last : null;

      final eggStats = <String, List<double>>{};
      for (final e in eggs.whereType<Map>().where((e) => _s(e['coop_id']) == id)) {
        final d = thaiDateOnlyFromIso(_s(e['date_collect_egg']));
        if (d == null) continue;
        final list = eggStats.putIfAbsent(d.year.toString(), () => List.filled(12, 0.0));
        list[d.month - 1] += double.tryParse(_s(e['number_egg'])) ?? 0.0;
      }
      if (eggStats.isEmpty) eggStats['${DateTime.now().year}'] = List.filled(12, 0.0);

      String sensor(bool Function(String) match) {
        for (final d in devices.whereType<Map>()) {
          if (_s(d['coop_id']) == id && match(_s(d['name']).toLowerCase())) {
            return _s(d['value']).isEmpty ? '0' : _s(d['value']);
          }
        }
        return '0';
      }

      final coopMap = <String, dynamic>{
        'id': id,
        'number': id,
        'name': name,
        'amount': amount.isEmpty ? '0' : amount,
        'import_date': importDate,
        'birth_date': birthDate,
        'age_text': ageText,
        'healthy': latest != null ? _s(latest['healthy']) : '0',
        'poor_health': latest != null ? _s(latest['poor_health']) : '0',
        'temp': sensor((n) => n.contains('อุณหภูมิ') || n.contains('dht')),
        'ppm': sensor((n) => n.contains('แอมโมเนีย') || n.contains('mq')),
        'egg_data': eggStats,
        'direction': null,
      };

      entries.add(SearchEntry(
        category: 'คอกไก่',
        emoji: '🐔',
        title: 'คอกไก่ $name',
        subtitle: '$amount ตัว • นำเข้า $importDate${ageText.isEmpty ? '' : ' • อายุ $ageText'}',
        haystack: [
          'คอก คอกไก่ $name $id $amount ตัว',
          _dateText(c['date_adopt_animals']),
          _dateText(rawBirthday),
          ageText,
          coopMap['healthy'],
          coopMap['poor_health'],
        ].join(' ').toLowerCase(),
        open: (ctx) => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => CoopDetailPage(coop: coopMap)),
        ),
      ));
    }

    // ---- อุปกรณ์/เซนเซอร์ ----
    for (final d in devices.whereType<Map>()) {
      final coop = nameOf(d['coop_id']);
      final name = _s(d['name']);
      final status = _s(d['current_status']);
      entries.add(SearchEntry(
        category: 'เซนเซอร์',
        emoji: '📟',
        title: name.isEmpty ? 'เซนเซอร์' : name,
        subtitle: 'คอก $coop${status.isEmpty ? '' : ' • สถานะ $status'}'
            '${_s(d['value']).isEmpty ? '' : ' • ค่า ${_s(d['value'])}'}',
        haystack: 'อุปกรณ์ เซนเซอร์ $name $status $coop ${_s(d['value'])}'.toLowerCase(),
        open: (ctx) => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => const MainDeviceSummary()),
        ),
      ));
    }

    // ---- นัดตรวจ/ฉีดวัคซีน ----
    for (final a in alerts.whereType<Map>()) {
      final coop = nameOf(a['coop_id']);
      final vaccine = _s(a['vaccine_name']);
      final date = thaiDateFromIso(_s(a['date']));
      final done = a['is_completed'] == true;
      entries.add(SearchEntry(
        category: 'นัดวัคซีน',
        emoji: '💉',
        title: vaccine.isEmpty ? 'นัดวัคซีน' : vaccine,
        subtitle: 'คอก $coop • $date • ${done ? 'ฉีดแล้ว' : 'ยังไม่ฉีด'}',
        haystack: [
          'นัด วัคซีน ยา ตรวจสุขภาพ $vaccine $coop',
          _dateText(a['date']),
          _s(a['injection_type']),
          _s(a['description']),
          done ? 'ฉีดแล้ว เสร็จ' : 'ยังไม่ฉีด ค้าง',
        ].join(' ').toLowerCase(),
        open: (ctx) => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => const MainHealthAppointments()),
        ),
      ));
    }

    // ---- ชนิดวัคซีน (ตารางวัคซีนมาตรฐาน) ----
    for (final v in schedules.whereType<Map>()) {
      final name = _s(v['name'] ?? v['vaccine_name']);
      if (name.isEmpty) continue;
      final age = _s(v['recommended_age'] ?? v['chicken_age']);
      final method = _s(v['method'] ?? v['injection_type']);
      entries.add(SearchEntry(
        category: 'ชนิดวัคซีน',
        emoji: '🧪',
        title: name,
        subtitle: [
          if (age.isNotEmpty) 'อายุ $age',
          if (method.isNotEmpty) method,
        ].join(' • '),
        haystack: 'วัคซีน ยา $name $age $method ${_s(v['description'])}'.toLowerCase(),
        open: (ctx) => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => const AddVaccineType()),
        ),
      ));
    }

    // ---- บันทึกสุขภาพไก่ ----
    for (final h in healths.whereType<Map>()) {
      final id = _s(h['coop_id']);
      final coop = nameOf(id);
      final date = thaiDateFromIso(_s(h['record_date']));
      entries.add(SearchEntry(
        category: 'สุขภาพไก่',
        emoji: '🩺',
        title: 'สุขภาพ คอก $coop • $date',
        subtitle: 'แข็งแรง ${_s(h['healthy'])} • ป่วย/อ่อนแอ ${_s(h['poor_health'])}',
        haystack: 'สุขภาพ ตรวจ แข็งแรง ป่วย $coop ${_dateText(h['record_date'])} '
                '${_s(h['healthy'])} ${_s(h['poor_health'])}'
            .toLowerCase(),
        open: (ctx) => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => MainVaccine(initialCoopId: id)),
        ),
      ));
    }

    // ---- ไข่ ----
    for (final e in eggs.whereType<Map>()) {
      final coop = nameOf(e['coop_id']);
      final date = thaiDateFromIso(_s(e['date_collect_egg']));
      entries.add(SearchEntry(
        category: 'ไข่',
        emoji: '🥚',
        title: 'ไข่ ${_s(e['number_egg'])} ฟอง • คอก $coop',
        subtitle: 'เก็บเมื่อ $date',
        haystack: 'ไข่ ฟอง สถิติไข่ เก็บไข่ $coop ${_s(e['number_egg'])} ${_dateText(e['date_collect_egg'])}'
            .toLowerCase(),
        open: (ctx) => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => const ShowChart()),
        ),
      ));
    }

    // ---- สต็อกอาหาร ----
    for (final f in foods.whereType<Map>()) {
      final type = _s(f['food_type']);
      entries.add(SearchEntry(
        category: 'อาหาร',
        emoji: '🌾',
        title: type.isEmpty ? 'อาหาร' : type,
        subtitle: 'คงเหลือ ${_s(f['quantity_current'])} กก. • ขั้นต่ำ ${_s(f['min_quantity'])} กก.',
        haystack: 'อาหาร สต็อก สต๊อก เม็ด $type ${_s(f['quantity_current'])} ${_s(f['min_quantity'])}'
            .toLowerCase(),
        open: (ctx) => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => const MainShowDataFood()),
        ),
      ));
    }

    _dataEntries = entries;
    _loadedAt = DateTime.now();
  }

  /// เมนู/หน้าต่างๆ ของแอป - ค้นหาชื่อหน้าแล้วกดไปได้เลย
  static final List<SearchEntry> _pages = [
    _page('🔔', 'การแจ้งเตือน', 'แจ้งเตือน notification', (_) => const Notifications()),
    _page('🐔', 'คอกไก่', 'จัดการคอกไก่ ข้อมูลคอก', (_) => const Adoptchicken()),
    _page('🎚️', 'ค่ามาตรฐานทุกคอก', 'ตั้งค่า อุณหภูมิ แอมโมเนีย threshold', (_) => const MainFarmThresholds()),
    _page('📅', 'นัดตรวจสุขภาพ', 'นัด ตรวจ สุขภาพ', (_) => const MainHealthAppointments()),
    _page('💉', 'เพิ่มยาวัคซีน', 'วัคซีน ยา', (_) => const AddVaccineType()),
    _page('📟', 'เซนเซอร์รวม', 'เซนเซอร์ อุปกรณ์', (_) => const MainDeviceSummary()),
    _page('📊', 'สถิติไข่รวม', 'กราฟ สถิติ ไข่', (_) => const ShowChart()),
    _page('🗓️', 'ปฏิทินรวม', 'ปฏิทิน วัน นัด', (_) => const Mainchicken()),
    _page('🌾', 'สต็อกอาหาร', 'อาหาร สต็อก', (_) => const MainShowDataFood()),
  ];

  static SearchEntry _page(
    String emoji,
    String title,
    String keywords,
    Widget Function(BuildContext) builder,
  ) {
    return SearchEntry(
      category: 'เมนู',
      emoji: emoji,
      title: title,
      subtitle: 'ไปที่หน้า$title',
      haystack: '$title $keywords'.toLowerCase(),
      open: (ctx) => Navigator.push(ctx, MaterialPageRoute(builder: builder)),
    );
  }

  List<SearchEntry> search(String query, {int limit = 40}) {
    final terms = query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (terms.isEmpty) return [];
    bool matches(SearchEntry e) => terms.every(e.haystack.contains);
    // เมนูมาก่อน แล้วตามด้วยข้อมูล (เรียงตามหมวดตามลำดับที่โหลดมา)
    return [
      ..._pages.where(matches),
      ..._dataEntries.where(matches),
    ].take(limit).toList();
  }
}
