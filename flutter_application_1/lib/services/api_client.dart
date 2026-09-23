import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

/// เรียก HTTP API แทนการเรียก `package:http` ตรงๆ ทุกจุดในแอป
///
/// ทำหน้าที่แทน service/หน้าจอทุกตัวที่เรียก backend สองอย่าง:
/// 1) แนบ Authorization header (Bearer token) ให้อัตโนมัติทุกคำขอ
///    (ผ่าน [AuthService.authHeaders]) โดยไม่ต้องเขียนซ้ำทุกไฟล์
/// 2) เมื่อ backend ตอบ 401 (token ไม่ถูกต้อง/หมดอายุ) จะล้าง token ที่เก็บไว้
///    แล้วพากลับไปหน้า Login ให้อัตโนมัติ — ทำได้จากทุกที่แม้จะอยู่ลึกใน
///    service function ที่ไม่มี BuildContext เพราะอาศัย [navigatorKey] ที่ผูก
///    กับ MaterialApp แทนการส่ง context ผ่านหลายชั้น
///
/// วิธีใช้: เดิมเรียก `http.get(uri)` / `http.post(uri, headers: ..., body: ...)`
/// เปลี่ยนเป็น `ApiClient.get(uri)` / `ApiClient.post(uri, headers: ..., body: ...)`
/// พารามิเตอร์ตรงกับของ `package:http` ทุกตัว (headers ที่ส่งมาเองจะถูกรวมกับ
/// auth header อัตโนมัติ ไม่ทับ Authorization ที่ ApiClient ใส่ให้)
class ApiClient {
  ApiClient._();

  /// ผูกกับ [MaterialApp.navigatorKey] ใน main.dart เพื่อให้นำทางไปหน้า Login
  /// ได้จากทุกที่ในแอปเมื่อเจอ 401 โดยไม่ต้องพึ่ง BuildContext ของหน้าปัจจุบัน
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final AuthService _authService = AuthService();

  static Future<Map<String, String>> _mergedHeaders(
    Map<String, String>? headers,
  ) async {
    final authHeaders = await _authService.authHeaders();
    return {...authHeaders, ...?headers};
  }

  static Future<http.Response> _finish(Future<http.Response> future) async {
    final response = await future;
    if (response.statusCode == 401) {
      await _authService.logout();
      _redirectToLogin();
    }
    return response;
  }

  static void _redirectToLogin() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    navigator.pushNamedAndRemoveUntil('/login', (route) => false);
  }

  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final mergedHeaders = await _mergedHeaders(headers);
    return _finish(http.get(url, headers: mergedHeaders));
  }

  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final mergedHeaders = await _mergedHeaders(headers);
    return _finish(
      http.post(url, headers: mergedHeaders, body: body, encoding: encoding),
    );
  }

  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final mergedHeaders = await _mergedHeaders(headers);
    return _finish(
      http.put(url, headers: mergedHeaders, body: body, encoding: encoding),
    );
  }

  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final mergedHeaders = await _mergedHeaders(headers);
    return _finish(
      http.delete(url, headers: mergedHeaders, body: body, encoding: encoding),
    );
  }

  static Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final mergedHeaders = await _mergedHeaders(headers);
    return _finish(
      http.patch(url, headers: mergedHeaders, body: body, encoding: encoding),
    );
  }
}
