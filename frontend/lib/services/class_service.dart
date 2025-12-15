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
      // Usamos el modelo Reserva modificado
      return data.map<Reserva>((json) => Reserva.fromJson(json)).toList();
    }
    return [];
  }



  /// Añade una nueva clase
  Future<bool> addClass(Clase clase) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/clases'),
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

    return response.statusCode == 201;
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
        // Mapeamos la respuesta a una lista de objetos Usuario
        return data.map<Usuario>((json) => Usuario.fromJson(json)).toList();
      }
    } catch (e) {
      print("Error fetching participants: $e");
    }
    return [];
  }
}
