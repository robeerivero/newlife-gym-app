import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class ClassReserveService {
  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/usuarios/perfil'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  Future<List<dynamic>> fetchClassesForDate(DateTime date) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return [];

    final dateQuery = '?fecha=${date.toIso8601String().split('T')[0]}';

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/clases/clases$dateQuery'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  Future<bool> reserveClass(String classId) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/reservas/reservar'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'idClase': classId}),
    );

    return response.statusCode == 201;
  }
}
