import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'backend_config.dart';

/// จัดการการเข้าสู่ระบบ/ออกจากระบบ และเก็บ token ของผู้ใช้ไว้ในเครื่อง
/// (SharedPreferences) ใช้ร่วมกันทั้งแอป — ทุก service ที่เรียก API ควรใช้
/// [authHeaders] จากคลาสนี้แทนการประกอบ header เอง เพื่อไม่ให้ตรรกะ token
/// กระจัดกระจายอยู่หลายที่
class AuthService {
  static const String tokenKey = 'auth_token';
  static const String usernameKey = 'auth_username';
  static const String roleKey = 'auth_role';

  /// เข้าสู่ระบบด้วย username/password ตาม API contract:
  /// POST /api/auth/login -> { token, user: { id, username, role } }
  /// สำเร็จแล้วจะบันทึก token/username/role ลง SharedPreferences ให้อัตโนมัติ
  /// ไม่สำเร็จจะโยน Exception ที่มีข้อความผิดพลาดจากเซิร์ฟเวอร์ (หรือข้อความ
  /// อธิบายทั่วไปถ้าเชื่อมต่อไม่ได้/รูปแบบข้อมูลผิด) ให้หน้า Login แสดงต่อได้เลย
  Future<Map<String, dynamic>> login(String username, String password) async {
    final uri = Uri.parse('$backendBaseUrl/api/auth/login');

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw Exception('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้ กรุณาลองใหม่อีกครั้ง');
    }

    Map<String, dynamic> body = const {};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) body = decoded;
      } catch (_) {
        // เซิร์ฟเวอร์ตอบกลับไม่ใช่ JSON ที่ถูกต้อง จะจัดการด้วยข้อความ error ด้านล่าง
      }
    }

    if (response.statusCode == 200) {
      final token = body['token']?.toString();
      final user = body['user'];
      if (token == null || token.isEmpty || user is! Map) {
        throw Exception('รูปแบบข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง');
      }

      final resolvedUsername = user['username']?.toString() ?? username;
      final role = user['role']?.toString() ?? '';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(tokenKey, token);
      await prefs.setString(usernameKey, resolvedUsername);
      await prefs.setString(roleKey, role);

      return body;
    }

    final errorMessage = body['error']?.toString();
    throw Exception(
      (errorMessage == null || errorMessage.isEmpty)
          ? 'เข้าสู่ระบบไม่สำเร็จ (รหัส ${response.statusCode})'
          : errorMessage,
    );
  }

  /// ล้างข้อมูลการเข้าสู่ระบบทั้งหมดที่เก็บไว้ในเครื่อง
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(usernameKey);
    await prefs.remove(roleKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(usernameKey);
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(roleKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Header มาตรฐานที่ทุกคำขอไปยัง backend ควรแนบไปด้วย รวม Authorization
  /// (ถ้ามี token อยู่) — เรียกใช้ตัวนี้แทนการประกอบ header เองทุกที่
  Future<Map<String, String>> authHeaders() async {
    final token = await getToken();
    return {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }
}
