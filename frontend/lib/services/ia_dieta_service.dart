// services/ia_dieta_service.dart
// ¡MODIFICADO! Aseguramos que incluye 'obtenerListaCompra'.

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../config.dart';
import '../models/plan_dieta.dart'; // Importa el nuevo modelo

class IADietaService {
  final _storage = const FlutterSecureStorage();
  final String _apiUrl = '${AppConstants.baseUrl}/api/dietas'; // Ruta base

  // --- ¡MEJORADO! ---
  /// Obtiene los headers, con 'Content-Type' opcional
  Future<Map<String, String>> _getHeaders({bool includeContentType = true}) async {
    final token = await _storage.read(key: 'jwt_token');
    final headers = {'Authorization': 'Bearer $token'};
    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }
    return headers;
  }

  /// [CLIENTE] Envía las preferencias de dieta para solicitar un plan.
  Future<bool> solicitarPlanDieta(Map<String, dynamic> datosPreferencias) async {
    final headers = await _getHeaders(); // PUT sí necesita Content-Type
    final response = await http.put(
      Uri.parse('$_apiUrl/solicitud'),
      headers: headers,
      body: json.encode(datosPreferencias),
    );
    return response.statusCode == 200;
  }

  /// [CLIENTE] Obtiene el estado actual del plan de dieta del mes.
  Future<String> obtenerEstadoPlanDelMes() async {
    final headers = await _getHeaders(includeContentType: false); // GET
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
  Future<DiaDieta?> obtenerDietaDelDia(DateTime fecha) async {
    final headers = await _getHeaders(includeContentType: false); // GET
    final fechaQuery = fecha.toIso8601String().split('T')[0];
    final response = await http.get(
      Uri.parse('$_apiUrl/mi-dieta-del-dia?fecha=$fechaQuery'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return DiaDieta.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      return null; // Sin plan aprobado para ese mes/día
    }
    throw Exception('Error al obtener dieta del día');
  }

  // --- ¡NUEVA FUNCIÓN CLIENTE! ---
  /// [CLIENTE] Obtiene la lista de la compra del mes actual.
  Future<Map<String, dynamic>> obtenerListaCompra() async {
    final headers = await _getHeaders(includeContentType: false); // GET
    final response = await http.get(
      Uri.parse('$_apiUrl/mi-lista-compra'),
      headers: headers
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 404) {
      throw Exception('Lista de la compra no encontrada.');
    }
    throw Exception('Error al obtener la lista de la compra');
  }

  // --- MÉTODOS PARA EL ADMIN ---

  /// [ADMIN] Obtiene la lista de planes de dieta pendientes de revisión.
  Future<List<PlanDieta>> obtenerPlanesPendientes() async {
    final headers = await _getHeaders(includeContentType: false); // GET
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
    final headers = await _getHeaders(includeContentType: false); // GET
    final response = await http.get(
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

  /// [ADMIN] Aprueba o Sobrescribe un plan, enviando el JSON.
  Future<bool> aprobarPlanManual(String idPlan, String jsonString) async {
    final headers = await _getHeaders(); // PUT sí necesita Content-Type
    final body = json.encode({
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

  /// [ADMIN] Obtiene la lista de planes de dieta APROBADOS.
  Future<List<PlanDieta>> obtenerPlanesAprobados() async {
    final headers = await _getHeaders(includeContentType: false);
    final response = await http.get(
      Uri.parse('$_apiUrl/admin/planes-aprobados'), // <-- Nueva ruta
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => PlanDieta.fromJson(json)).toList();
    }
    throw Exception('Error al obtener planes de dieta aprobados');
  }

  /// [ADMIN] Elimina un plan de dieta permanentemente.
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