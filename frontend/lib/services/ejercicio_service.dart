import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../models/ejercicio.dart';

class EjercicioService {
  final _storage = const FlutterSecureStorage();

  Future<List<Ejercicio>?> fetchEjercicios() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/ejercicios'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data as List)
          .map<Ejercicio>((json) => Ejercicio.fromJson(json))
          .toList();
    }
    return null;
  }

  Future<bool> addEjercicio(Ejercicio ejercicio) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return false;
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/ejercicios'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nombre': ejercicio.nombre,
        'video': ejercicio.video,
        'descripcion': ejercicio.descripcion,
        'dificultad': ejercicio.dificultad,
      }),
    );
    return response.statusCode == 201;
  }

  Future<bool> editEjercicio(Ejercicio ejercicio) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return false;
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/api/ejercicios/${ejercicio.id}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nombre': ejercicio.nombre,
        'video': ejercicio.video,
        'descripcion': ejercicio.descripcion,
        'dificultad': ejercicio.dificultad,
      }),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteEjercicio(String id) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return false;
    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/api/ejercicios/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return response.statusCode == 200;
  }
}
