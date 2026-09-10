import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// จัดการค่ามาตรฐาน (อุณหภูมิ/แอมโมเนีย) ที่เจ้าของฟาร์มตั้งไว้ใช้ร่วมกันทุกคอก
/// เก็บไว้ในเครื่อง (SharedPreferences) เหมือนกับ ThemeController
class FarmThresholdController extends ChangeNotifier {
  static const _tempKey = 'ez_target_temp';
  static const _ammoniaKey = 'ez_target_ammonia';

  double _temperature = 28;
  double _ammonia = 20;

  double get temperature => _temperature;
  double get ammonia => _ammonia;

  Future<void> load() async {
    final prefs = SharedPreferencesAsync();
    final savedTemp = await prefs.getDouble(_tempKey);
    final savedAmmonia = await prefs.getDouble(_ammoniaKey);
    if (savedTemp != null) _temperature = savedTemp;
    if (savedAmmonia != null) _ammonia = savedAmmonia;
    if (savedTemp != null || savedAmmonia != null) notifyListeners();
  }

  Future<void> save({
    required double temperature,
    required double ammonia,
  }) async {
    _temperature = temperature;
    _ammonia = ammonia;
    notifyListeners();
    final prefs = SharedPreferencesAsync();
    await prefs.setDouble(_tempKey, temperature);
    await prefs.setDouble(_ammoniaKey, ammonia);
  }
}

final farmThresholdController = FarmThresholdController();
