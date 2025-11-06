import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../models/clase.dart';
import '../models/usuario_reserva.dart';

class ReservationService {
  final _storage = const FlutterSecureStorage();

  Future<List<Clase>> fetchClassesByDate(DateTime? date) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) throw Exception('Token no encontrado.');

    final dateQuery = date != null ? '?fecha=${date.toIso8601String().split('T')[0]}' : '';
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/clases$dateQuery'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((e) => Clase.fromJson(e)).toList();
    } else {
      final data = json.decode(response.body);
      throw Exception(data['mensaje'] ?? 'Error al obtener las clases.');
    }
  }

  Future<void> addUserToClass({required String usuarioId, required String dia, required String hora}) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) throw Exception('Token no encontrado.');

    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/reservas/asignarPorDiaYHora'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'idUsuario': usuarioId,
        'dia': dia,
        'horaInicio': hora,
      }),
    );
    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['mensaje'] ?? 'Error al añadir usuario a clases');
    }
  }

  Future<void> asignarUsuarioAClase(String classId, String userId) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) throw Exception('Token no encontrado.');

    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/reservas/asignar'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'idClase': classId,
        'idUsuario': userId,
      }),
    );
    if (response.statusCode != 201) {
      final data = json.decode(response.body);
      throw Exception(data['mensaje'] ?? 'Error al asignar usuario a clase');
    }
  }

  Future<void> desasignarUsuarioDeClase(String classId, String userId) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) throw Exception('Token no encontrado.');

    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/api/reservas/clase/$classId/usuario/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['mensaje'] ?? 'Error al desasignar usuario de clase');
    }
  }

  
  Future<List<UsuarioReserva>> fetchUsuariosDeClase(String classId) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) throw Exception('Token no encontrado.');

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/clases/usuarios/$classId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map<UsuarioReserva>((json) => UsuarioReserva.fromJson(json)).toList();
    } else {
      final data = json.decode(response.body);
      throw Exception(data['mensaje'] ?? 'Error al obtener usuarios de la clase');
    }
  }

  Future<Map<String, dynamic>?> fetchAsistenciasUsuario(String userId, String token) async {
    print('📡 [FRONTEND] Llamando a fetchAsistenciasUsuario con ID: $userId');

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/reservas/asistencias/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('📨 [FRONTEND] Respuesta status: ${response.statusCode}');
    print('📨 [FRONTEND] Body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }

    print('❌ [FRONTEND] Error en fetchAsistenciasUsuario');
    return null;
  }
}
