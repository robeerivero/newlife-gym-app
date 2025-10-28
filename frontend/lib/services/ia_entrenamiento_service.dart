// services/ia_entrenamiento_service.dart
// ¡NUEVO ARCHIVO!

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../config.dart';
import '../models/plan_entrenamiento.dart'; // Importa el nuevo modelo
class IAEntrenamientoService {
  final _storage = const FlutterSecureStorage();
  final String _apiUrl = '${AppConstants.baseUrl}/api/entrenamiento'; // Ruta base

  // Helper para obtener headers con token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'jwt_token');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
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

  /// [CLIENTE] Obtiene el estado actual del plan del mes (para saber si mostrar el form o no).
  Future<String> obtenerEstadoPlanDelMes() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_apiUrl/mi-plan-del-mes'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['estado'] ?? 'pendiente_solicitud';
    } else if (response.statusCode == 404) {
      return 'pendiente_solicitud'; // Si no hay plan, se puede solicitar
    }
    throw Exception('Error al obtener estado del plan');
  }

  /// [CLIENTE] Obtiene la rutina detallada para un día específico.
  /// Devuelve el objeto `DiaEntrenamiento` correspondiente a ese día.
  Future<DiaEntrenamiento> obtenerRutinaDelDia(DateTime fecha) async {
    final headers = await _getHeaders();
    final String fechaQuery = fecha.toIso8601String().split('T')[0];
    
    final response = await http.get(
  Uri.parse('$_apiUrl/mi-rutina-del-dia?fecha=$fechaQuery'), // <--- ¡AÑADE "DEL" AQUÍ!
  headers: headers,
);

    // --- ¡¡LOGS DE FRONTEND CON PRINT!! ---
    print('--- [FRONTEND DEBUG: SERVICIO] ---');
    print('Status Code: ${response.statusCode}');
    print('Respuesta (body) RAW: ${response.body}');
    // --- FIN DE LOGS ---

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // --- ¡¡LOG 2 CON PRINT!! ---
      print('Datos (body) DECODIFICADOS: $data');
      // --- FIN DE LOG 2 ---

      return DiaEntrenamiento.fromJson(data); 
    } else {
      final errorData = json.decode(response.body);
      print('Error del servidor: ${errorData['mensaje']}');
      throw Exception(errorData['mensaje'] ?? 'Error al cargar la rutina.');
    }
  }

  // --- MÉTODOS PARA EL ADMIN ---

  /// [ADMIN] Obtiene la lista de planes pendientes de revisión.
  Future<List<PlanEntrenamiento>> obtenerPlanesPendientes() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_apiUrl/admin/planes-pendientes'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => PlanEntrenamiento.fromJson(json)).toList();
    }
    throw Exception('Error al obtener planes pendientes');
  }

  // --- ¡NUEVA FUNCIÓN! ---
  /// [ADMIN] Obtiene el prompt para un plan pendiente.
  Future<Map<String, dynamic>> obtenerPromptParaRevision(String idPlan) async {
    final headers = await _getHeaders();
     headers.remove('Content-Type');
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
  /// [ADMIN] Aprueba un plan, enviando JSON string y días asignados.
  Future<bool> aprobarPlanManual(String idPlan, String jsonString, List<String> diasAsignados) async {
    final headers = await _getHeaders();
    final body = json.encode({
      'jsonString': jsonString, // El JSON como string
      'diasAsignados': diasAsignados,
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

   // --- ELIMINADA (O COMENTADA) ---
   /*
   Future<bool> regenerarBorradorIA(String idPlan) async {
     // ...
   }
   */
}