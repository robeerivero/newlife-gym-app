// services/ia_entrenamiento_service.dart
// ¡ACTUALIZADO! Con nuevas funciones de Admin y 'aprobarPlanManual' corregido.

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../config.dart';
import '../models/plan_entrenamiento.dart';

class IAEntrenamientoService {
  final _storage = const FlutterSecureStorage();
  final String _apiUrl = '${AppConstants.baseUrl}/api/entrenamiento'; // Ruta base

  // Helper para obtener headers con token (mejorado)
  Future<Map<String, String>> _getHeaders({bool includeContentType = true}) async {
    final token = await _storage.read(key: 'jwt_token');
    final headers = {'Authorization': 'Bearer $token'};
    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }
    return headers;
  }

  /// [CLIENTE] Envía las preferencias de entrenamiento para solicitar un plan.
  Future<bool> solicitarPlanEntrenamiento(Map<String, dynamic> datosPreferencias) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$_apiUrl/solicitud'),
      headers: headers,
      body: json.encode(datosPreferencias),
    );
    return response.statusCode == 200;
  }

  /// [CLIENTE] Obtiene el estado actual del plan del mes.
  Future<String> obtenerEstadoPlanDelMes() async {
    final headers = await _getHeaders(includeContentType: false);
    final response = await http.get(
      Uri.parse('$_apiUrl/mi-plan-del-mes'),
      headers: headers
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['estado'] ?? 'pendiente_solicitud';
    } else if (response.statusCode == 404) {
      return 'pendiente_solicitud';
    }
    throw Exception('Error al obtener estado del plan de entrenamiento');
  }

  /// [CLIENTE] Obtiene la rutina de entrenamiento para un día específico.
  Future<DiaEntrenamiento?> obtenerRutinaDelDia(DateTime fecha) async {
    final headers = await _getHeaders(includeContentType: false);
    final fechaQuery = fecha.toIso8601String().split('T')[0];
    final response = await http.get(
      Uri.parse('$_apiUrl/mi-rutina-del-dia?fecha=$fechaQuery'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return DiaEntrenamiento.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      return null; // Día de descanso o sin plan
    }
    throw Exception('Error al obtener rutina del día');
  }

  // --- MÉTODOS DE ADMINISTRADOR ---

  /// [ADMIN] Obtiene la lista de planes pendientes de revisión.
  Future<List<PlanEntrenamiento>> obtenerPlanesPendientes() async {
    final headers = await _getHeaders(includeContentType: false);
    final response = await http.get(
      Uri.parse('$_apiUrl/admin/planes-pendientes'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => PlanEntrenamiento.fromJson(json)).toList();
    }
    throw Exception('Error al obtener planes de entrenamiento pendientes');
  }

  /// [ADMIN] Obtiene el prompt para un plan pendiente.
  Future<Map<String, dynamic>> obtenerPromptParaRevision(String idPlan) async {
    final headers = await _getHeaders(includeContentType: false);
    final response = await http.get(
      Uri.parse('$_apiUrl/admin/plan/$idPlan/prompt'),
      headers: headers,
    );
     if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
       final errorData = json.decode(response.body);
       throw Exception(errorData['mensaje'] ?? 'Error al obtener el prompt.');
    }
  }

  // --- ¡FUNCIÓN MODIFICADA! ---
  /// [ADMIN] Aprueba un plan, enviando UN solo string JSON.
  Future<bool> aprobarPlanManual(String idPlan, String jsonString) async {
    final headers = await _getHeaders();
    final body = json.encode({
      'jsonString': jsonString, // El JSON como string
      // 'diasAsignados' ya no se envía por separado, va DENTRO del jsonString
    });
    final response = await http.put(
      Uri.parse('$_apiUrl/admin/aprobar/$idPlan'),
      headers: headers,
      body: body,
    );
     if (response.statusCode >= 400) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['mensaje'] ?? 'Error desconocido al aprobar plan.');
     }
    return response.statusCode == 200;
  }
  
  // --- ¡NUEVAS FUNCIONES DE ADMIN! ---
  
  /// [ADMIN] Obtiene la lista de planes de entrenamiento APROBADOS.
  Future<List<PlanEntrenamiento>> obtenerPlanesAprobados() async {
    final headers = await _getHeaders(includeContentType: false);
    final response = await http.get(
      Uri.parse('$_apiUrl/admin/planes-aprobados'), // <-- Nueva ruta
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => PlanEntrenamiento.fromJson(json)).toList();
    }
    throw Exception('Error al obtener planes de entrenamiento aprobados');
  }
  
  /// [ADMIN] Obtiene el JSON de un plan ya aprobado para poder editarlo.
  Future<Map<String, dynamic>> obtenerPlanParaEditar(String idPlan) async {
    final headers = await _getHeaders(includeContentType: false); // GET
    final response = await http.get(
      Uri.parse('$_apiUrl/admin/plan/$idPlan/para-editar'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      // Devuelve {'jsonStringParaEditar': '...', 'inputsUsuario': {...}}
      return json.decode(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['mensaje'] ?? 'Error al obtener el JSON para editar.');
    }
  }

  /// [ADMIN] Elimina un plan de entrenamiento permanentemente.
  Future<bool> eliminarPlan(String idPlan) async {
    final headers = await _getHeaders(includeContentType: false); // DELETE
    final response = await http.delete(
      Uri.parse('$_apiUrl/admin/plan/$idPlan'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['mensaje'] ?? 'Error al eliminar el plan.');
    }
    return response.statusCode == 200;
  }
}