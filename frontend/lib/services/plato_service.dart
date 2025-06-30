import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../config.dart';
import '../models/plato.dart';

class PlatoService {
  final _storage = const FlutterSecureStorage();

  Future<List<Plato>> fetchPlatos() async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/platos'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Plato.fromJson(json)).toList();
    }
    throw Exception('Error al cargar platos');
  }

  Future<bool> deletePlato(String id) async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/api/platos/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  Future<bool> addOrUpdatePlato(Plato plato, {String? id}) async {
    final token = await _storage.read(key: 'jwt_token');
    final isEdit = id != null;
    final url = isEdit
        ? Uri.parse('${AppConstants.baseUrl}/api/platos/$id')
        : Uri.parse('${AppConstants.baseUrl}/api/platos');
    final body = json.encode(plato.toJson());

    final response = isEdit
        ? await http.put(url, headers: _headers(token), body: body)
        : await http.post(url, headers: _headers(token), body: body);

    return response.statusCode == 201 || response.statusCode == 200;
  }

  Map<String, String> _headers(String? token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
}
