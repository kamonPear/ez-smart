import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/backend_config.dart';

/// จัดการค่ามาตรฐาน (อุณหภูมิ/แอมโมเนีย) ที่เจ้าของฟาร์มตั้งไว้ใช้ร่วมกันทุกคอก
/// เก็บที่ backend แล้ว (ไม่ใช่ SharedPreferences ในเครื่องอีกต่อไป) เพื่อให้ค่า
/// ตรงกันทั้งแอปมือถือและเว็บเสมอ ไม่ว่าจะปรับค่าจากฝั่งไหนก็ตาม - เว็บอ่าน/เขียน
/// endpoint เดียวกันนี้ (GET/PUT /api/farm-threshold)
class FarmThresholdController extends ChangeNotifier {
  double _temperature = 25;
  double _ammonia = 35;
  bool _isLoaded = false;

  double get temperature => _temperature;
  double get ammonia => _ammonia;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    try {
      final response = await ApiClient.get(
        Uri.parse('$backendBaseUrl/api/farm-threshold'),
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final temp = (decoded['temperature'] as num?)?.toDouble();
        final ammonia = (decoded['ammonia'] as num?)?.toDouble();
        if (temp != null) _temperature = temp;
        if (ammonia != null) _ammonia = ammonia;
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
