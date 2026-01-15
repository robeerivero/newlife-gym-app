import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../models/clase.dart';
import '../models/reserva.dart';
import '../models/usuario.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ClassService {
  final _storage = const FlutterSecureStorage();

  /// Trae TODAS las clases, opcionalmente filtradas por fecha.
  Future<List<Clase>> fetchClasses({DateTime? fecha}) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return [];

    final String dateQuery = fecha != null
        ? '?fecha=${fecha.toIso8601String().split('T')[0]}'
        : '';
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/clases$dateQuery'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map<Clase>((json) => Clase.fromJson(json)).toList();
    }
    return [];
  }

  /// Trae las reservas del usuario para un rango de fechas (para el calendario)
  Future<List<Reserva>> fetchReservasPorRango(DateTime fechaInicio, DateTime fechaFin) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return [];

    // Formateamos las fechas como YYYY-MM-DD
    final String inicio = fechaInicio.toIso8601String().split('T')[0];
    final String fin = fechaFin.toIso8601String().split('T')[0];
    
    // Usamos el nuevo endpoint del backend
    final uri = Uri.parse('${AppConstants.baseUrl}/api/reservas/mis-reservas?fechaInicio=$inicio&fechaFin=$fin');

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map<Reserva>((json) => Reserva.fromJson(json)).toList();
    }
    return [];
  }

  /// Añade una nueva clase (INDIVIDUAL)
  Future<bool> addClass(Clase clase) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return false;

    // Nota: Usamos el endpoint individual que ya deberías tener o adaptar en backend
    // Si tu backend unifica todo en un solo POST, usa el método de abajo.
    // Asumiendo que POST /api/clases maneja creación individual si no se pasan arrays
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/clases'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        // Adaptamos el envío para una sola clase
        'nombre': clase.nombre,
        'dias': [clase.dia], // Enviamos como lista de 1 elemento
        'horas': [clase.horaInicio], // Enviamos como lista de 1 elemento
        'maximoParticipantes': clase.maximoParticipantes
        // La fecha exacta se calculará en backend si usas la lógica recurrente,
        // o necesitas un endpoint específico para clase única con fecha fija.
      }),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// Crea clases de forma MASIVA (Recurrente)
  Future<Map<String, dynamic>> crearClasesRecurrentes({
    required String nombre,
    required List<String> dias,
    required List<String> horas,
    required int maximoParticipantes,
  }) async {
    final token = await _storage.read(key: 'jwt_token');
    
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/clases'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'nombre': nombre,
        'dias': dias,
        'horas': horas,
        'maximoParticipantes': maximoParticipantes
      }),
    );

    final data = json.decode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'mensaje': data['mensaje']};
    } else {
      return {'success': false, 'mensaje': data['mensaje'] ?? 'Error al crear clases'};
    }
  }

  /// Edita una clase existente
  Future<bool> editClass(String id, Clase clase) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return false;

    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/api/clases/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'nombre': clase.nombre,
        'dia': clase.dia,
        'horaInicio': clase.horaInicio,
        'horaFin': clase.horaFin,
        'fecha': clase.fecha.toIso8601String(),
        'maximoParticipantes': clase.maximoParticipantes,
      }),
    );

    return response.statusCode == 200;
  }

  /// Elimina una clase por su id
  Future<bool> deleteClass(String id) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/api/clases/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  /// Elimina TODAS las clases
  Future<bool> deleteAllClasses() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/api/clases'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  /// Cancela una reserva (pantalla cliente)
  Future<bool> cancelClass(String classId) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/api/reservas/cancelar'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'idClase': classId}),
    );
    return response.statusCode == 200;
  }

  /// Obtiene la lista de usuarios apuntados a una clase específica
  Future<List<Usuario>> fetchUsuariosPorClase(String classId) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/reservas/clase/$classId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map<Usuario>((json) => Usuario.fromJson(json)).toList();
      }
    } catch (e) {
      print("Error fetching participants: $e");
    }
    return [];
  }
}