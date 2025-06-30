import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config.dart';
import '../models/rutina.dart';

class RutinasService {
  final _storage = const FlutterSecureStorage();

  Future<List<Rutina>> fetchRutinas() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return [];
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/rutinas'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Rutina.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<Rutina>> fetchRutinasUsuario() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return [];
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/rutinas/usuario'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Rutina.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> deleteRutina(String id) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) throw Exception('Token no encontrado.');
    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/api/rutinas/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar la rutina');
    }
  }

  Future<void> addRutina(String usuarioId, String diaSemana, List<EjercicioRutina> ejercicios) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) throw Exception('Token no encontrado');
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/rutinas'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'usuario': usuarioId,
        'diaSemana': diaSemana,
        'ejercicios': ejercicios.map((e) => e.toJson()).toList(),
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Error al crear rutina');
    }
  }

  Future<Rutina?> fetchRutinaById(String id) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return null;
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/rutinas/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return Rutina.fromJson(json.decode(response.body));
    }
    return null;
  }

  Future<void> updateRutina(Rutina rutina) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      print('❌ Token no encontrado');
      throw Exception('Token no encontrado');
    }

    final url = Uri.parse('${AppConstants.baseUrl}/api/rutinas/${rutina.id}');
    final payload = {
      'usuario': rutina.usuario.id,
      'diaSemana': rutina.diaSemana,
      'ejercicios': rutina.ejercicios.map((e) => e.toJson()).toList(),
    };

    print('📡 PUT → $url');
    print('🔑 Authorization: Bearer $token');
    print('📦 Payload:\n${jsonEncode(payload)}');

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    print('📥 Status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar la rutina');
    }
  }

}
