// services/ia_dieta_service.dart
// ¡NUEVO ARCHIVO!

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../config.dart';
import '../models/plan_dieta.dart'; // Importa el nuevo modelo

class IADietaService {
  final _storage = const FlutterSecureStorage();
  final String _apiUrl = '${AppConstants.baseUrl}/api/dietas'; // Ruta base

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'jwt_token');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// [CLIENTE] Envía las preferencias de dieta para solicitar un plan.
  Future<bool> solicitarPlanDieta(Map<String, dynamic> datosPreferencias) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$_apiUrl/solicitud'),
      headers: headers,
      body: json.encode(datosPreferencias),
    );
    return response.statusCode == 200;
  }

  /// [CLIENTE] Obtiene el estado actual del plan de dieta del mes.
  Future<String> obtenerEstadoPlanDelMes() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_apiUrl/mi-plan-del-mes'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['estado'] ?? 'pendiente_solicitud';
    } else if (response.statusCode == 404) {
      return 'pendiente_solicitud';
    }
    throw Exception('Error al obtener estado del plan de dieta');
  }

  /// [CLIENTE] Obtiene la dieta detallada para un día específico.
  /// Devuelve el objeto `DiaDieta` correspondiente (ej. "L-V" o "Fin de Semana").
  Future<DiaDieta?> obtenerDietaDelDia(DateTime fecha) async {
    final headers = await _getHeaders();
    final fechaQuery = fecha.toIso8601String().split('T')[0];
    final response = await http.get(
      Uri.parse('$_apiUrl/mi-dieta-del-dia?fecha=$fechaQuery'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      // El backend devuelve directamente el objeto DiaDieta
      return DiaDieta.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      return null; // Sin plan aprobado para ese mes/día
    }
    throw Exception('Error al obtener dieta del día');
  }

  // --- MÉTODOS PARA EL ADMIN ---

  /// [ADMIN] Obtiene la lista de planes de dieta pendientes de revisión.
  Future<List<PlanDieta>> obtenerPlanesPendientes() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_apiUrl/admin/planes-pendientes'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => PlanDieta.fromJson(json)).toList();
    }
    throw Exception('Error al obtener planes de dieta pendientes');
  }

  /// [ADMIN] Obtiene el prompt para un plan pendiente.
  Future<Map<String, dynamic>> obtenerPromptParaRevision(String idPlan) async {
    final headers = await _getHeaders();
    headers.remove('Content-Type'); // GET no necesita Content-Type
    final response = await http.get(
      // Nuevo endpoint del backend
      Uri.parse('$_apiUrl/admin/plan/$idPlan/prompt'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body); // Devuelve {'prompt': '...'}
    } else {
       final errorData = json.decode(response.body);
       throw Exception(errorData['mensaje'] ?? 'Error al obtener el prompt.');
    }
  }

  /// [ADMIN] Aprueba un plan de dieta, enviando la versión editada.
  Future<bool> aprobarPlanManual(String idPlan, String jsonString) async {
    final headers = await _getHeaders();
    final body = json.encode({
      // El backend ahora espera 'jsonString'
      'jsonString': jsonString,
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

}