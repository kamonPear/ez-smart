import 'dart:convert';
import '../models/coop.dart';
import 'api_client.dart';

class ApiService {
  final String baseUrl;
  ApiService({required this.baseUrl});

  /// Fetch list of adopt chicken coops from endpoint: GET {baseUrl}/api/coops
  Future<List<Coop>> fetchCoops() async {
    final uri = Uri.parse('$baseUrl/api/coops');
    final resp = await ApiClient.get(uri).timeout(const Duration(seconds: 10));

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final body = json.decode(resp.body);
      if (body is List) {
        return body
            .map((e) => Coop.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (body is Map && body['data'] is List) {
        return (body['data'] as List)
            .map((e) => Coop.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Unexpected response format');
    } else {
      throw Exception('API error: ${resp.statusCode}');
    }
  }
}
