import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/backend_config.dart';

/// จัดการค่ามาตรฐาน (อุณหภูมิ/แอมโมเนีย) ที่เจ้าของฟาร์มตั้งไว้ใช้ร่วมกันทุกคอก
/// เก็บที่ backend แล้ว (ไม่ใช่ SharedPreferences ในเครื่องอีกต่อไป) เพื่อให้ค่า
/// ตรงกันทั้งแอปมือถือและเว็บเสมอ ไม่ว่าจะปรับค่าจากฝั่งไหนก็ตาม - เว็บอ่าน/เขียน
/// endpoint เดียวกันนี้ (GET/PUT /api/farm-threshold)
// ค่าเริ่มต้นแนะนำ ใช้เป็นแค่ draft ตั้งต้นในหน้าตั้งค่าตอนยังไม่เคยตั้งค่าเลย
// (ห้ามเอาไปโชว์เป็นค่าที่ "ตั้งไว้แล้ว" ที่หน้าแรก - ดู isConfigured)
const double kDefaultDraftTemp = 25;
const double kDefaultDraftAmmonia = 35;

class FarmThresholdController extends ChangeNotifier {
  double _temperature = 0;
  double _ammonia = 0;
  bool _isLoaded = false;
  bool _isConfigured = false;

  double get temperature => _temperature;
  double get ammonia => _ammonia;
  bool get isLoaded => _isLoaded;
  // ผู้ใช้เคยกดบันทึกค่ามาตรฐานจริงหรือยัง (มีแถวใน backend แล้ว) - แยกจาก
  // "ตั้งค่าไว้เป็น 0" เพราะยังไม่เคยตั้งค่าเลย backend จะตอบ id/temperature/ammonia
  // เป็น 0 ทั้งหมด เอาไปโชว์ตรงๆ จะดูเหมือนมีคนตั้งค่าไว้แล้วทั้งที่ยังไม่ได้ตั้ง
  bool get isConfigured => _isConfigured;

  Future<void> load() async {
    try {
      final response = await ApiClient.get(
        Uri.parse('$backendBaseUrl/api/farm-threshold'),
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final temp = (decoded['temperature'] as num?)?.toDouble();
        final ammonia = (decoded['ammonia'] as num?)?.toDouble();
        final id = (decoded['id'] as num?)?.toInt() ?? 0;
        if (temp != null) _temperature = temp;
        if (ammonia != null) _ammonia = ammonia;
        _isConfigured = id > 0;
      } else {
        debugPrint('โหลดค่ามาตรฐานของฟาร์มไม่สำเร็จ: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('เชื่อมต่อ backend ไม่สำเร็จ (farm threshold): $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> save({
    required double temperature,
    required double ammonia,
  }) async {
    _temperature = temperature;
    _ammonia = ammonia;
    _isConfigured = true;
    notifyListeners();

    try {
      final response = await ApiClient.put(
        Uri.parse('$backendBaseUrl/api/farm-threshold'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: json.encode({'temperature': temperature, 'ammonia': ammonia}),
      );
      if (response.statusCode != 200) {
        debugPrint('บันทึกค่ามาตรฐานของฟาร์มไม่สำเร็จ: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('เชื่อมต่อ backend ไม่สำเร็จ (บันทึกค่ามาตรฐานของฟาร์ม): $e');
    }
  }
}

final farmThresholdController = FarmThresholdController();
