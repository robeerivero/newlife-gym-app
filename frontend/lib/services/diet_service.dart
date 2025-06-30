import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../config.dart';
import '../models/plato.dart';
import '../models/dieta.dart';

class DietService {
  final _storage = const FlutterSecureStorage();

  /// Obtiene todos los platos del sistema
  Future<List<Plato>?> fetchPlatos() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/platos'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map<Plato>((p) => Plato.fromJson(p)).toList();
    }
    return null;
  }

  /// Obtiene todas las dietas de un usuario específico (por su id)
  Future<List<Dieta>?> fetchDietasDeUsuario(String usuarioId) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/dietas/$usuarioId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map<Dieta>((d) => Dieta.fromJson(d)).toList();
    }
    return null;
  }

  /// Añade una dieta para un usuario concreto, en una fecha, con varios platos
  Future<bool> addDieta(String usuarioId, DateTime fecha, List<Plato> platosSeleccionados) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/dietas'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'usuario': usuarioId,
        'fecha': fecha.toIso8601String().split('T')[0],
        'platos': platosSeleccionados.map((p) => p.id).toList(),
      }),
    );
    return response.statusCode == 201;
  }

  /// Elimina una dieta por su id
  Future<void> deleteDieta(String id) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return;

    await http.delete(
      Uri.parse('${AppConstants.baseUrl}/api/dietas/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  /// Elimina todas las dietas
  Future<void> deleteAllDietas() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return;

    await http.delete(
      Uri.parse('${AppConstants.baseUrl}/api/dietas'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  /// Obtiene los platos de la dieta del usuario autenticado para una fecha dada
  Future<List<Plato>?> fetchPlatosPorFecha(DateTime fecha) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/dietas?fecha=${fecha.toIso8601String().split('T')[0]}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      // El backend puede devolver varias dietas, cada una con platos
      final platos = data.expand((dieta) => (dieta['platos'] as List)).toList();
      return platos.map<Plato>((p) => Plato.fromJson(p)).toList();
    }
    return null;
  }
}
