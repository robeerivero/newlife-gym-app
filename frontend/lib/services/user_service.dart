// services/user_service.dart
// ¡VERSIÓN COMPLETA! (Incluye funciones de Cliente + Admin)

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../config.dart';
import '../models/usuario.dart';         
import '../models/usuario_ranking.dart';
import '../models/logro_prenda.dart';

class UserService {
  final _storage = const FlutterSecureStorage();
  final String _apiUrl = '${AppConstants.baseUrl}/api/usuarios';

  Future<Map<String, String>> _getHeaders({bool includeContentType = true}) async {
    final token = await _storage.read(key: 'jwt_token');
    final headers = {'Authorization': 'Bearer $token'};
    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }
    return headers;
  }

  // --- FUNCIONES DE CLIENTE (TU CÓDIGO ORIGINAL) ---

  /// Obtiene el perfil del usuario autenticado
  Future<Usuario?> fetchProfile() async {
    final headers = await _getHeaders(includeContentType: false);
    final response = await http.get(Uri.parse('$_apiUrl/perfil'), headers: headers);
    if (response.statusCode == 200) {
      return Usuario.fromJson(json.decode(response.body));
    }
    return null;
  }

  /// [CLIENTE] Edita su propio perfil (nombre, correo, tiposDeClases)
  Future<bool> editarMiPerfil({
    required String nombre,
    required String correo,
    required List<String> tiposDeClases,
  }) async {
     final headers = await _getHeaders();
     // Esta ruta (PUT /perfil) es diferente de la ruta de admin (PUT /:idUsuario)
     // Por eso no hay conflicto.
     final response = await http.put(
       Uri.parse('$_apiUrl/perfil'), 
       headers: headers,
       body: jsonEncode({
         'nombre': nombre,
         'correo': correo,
         'tiposDeClases': tiposDeClases,
       }),
     );
     return response.statusCode == 200;
  }

  /// [CLIENTE] Cambia su contraseña
  Future<bool> cambiarContrasena(String actual, String nueva) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$_apiUrl/perfil/contrasena'),
      headers: headers,
      body: jsonEncode({
        'contrasenaActual': actual,
        'nuevaContrasena': nueva,
      }),
    );
    return response.statusCode == 200;
  }

  /// [CLIENTE] Actualiza sus datos metabólicos
  Future<Map<String, dynamic>?> actualizarDatosMetabolicos(Map<String, dynamic> datos) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$_apiUrl/metabolicos'),
      headers: headers,
      body: jsonEncode(datos),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }
  
  /// [CLIENTE] Actualiza su avatar
  Future<bool> actualizarAvatar(Map<String, dynamic> avatarJson) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$_apiUrl/avatar'),
      headers: headers,
      body: jsonEncode({'avatar': avatarJson}),
    );
    return response.statusCode == 200;
  }


  // --- FUNCIONES DE DATOS (RANKING, LOGROS, ETC) ---

  /// Ranking mensual
  Future<List<UsuarioRanking>?> getRanking() async {
    final headers = await _getHeaders(includeContentType: false);
    final response = await http.get(
      Uri.parse('$_apiUrl/ranking-mensual'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map<UsuarioRanking>((json) => UsuarioRanking.fromJson(json)).toList();
    }
    return null;
  }

  /// Logros y prendas
  Future<List<LogroPrenda>?> getLogros() async {
    // (Asegúrate de que esta lógica es correcta según tu app)
    final headers = await _getHeaders(includeContentType: false);
    final response = await http.get(
      Uri.parse('$_apiUrl/prendas/progreso'), 
      headers: headers,
    );
     if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map<LogroPrenda>((json) => LogroPrenda.fromJson(json)).toList();
    }
    return null;
  }


  // --- ¡NUEVAS FUNCIONES DE ADMINISTRADOR! ---

  /// [ADMIN] Obtiene TODOS los usuarios (con filtros)
  Future<List<Usuario>?> fetchAllUsuarios({String? nombreGrupo}) async {
    final headers = await _getHeaders(includeContentType: false);
    Map<String, String> queryParams = {};

    // Solo añade el parámetro si tiene valor y NO es "Todos"
    if (nombreGrupo != null && nombreGrupo.isNotEmpty && nombreGrupo != 'Todos') {
       queryParams['nombreGrupo'] = nombreGrupo;
    }

    final uri = Uri.parse(_apiUrl).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    print("[UserService] Fetching users: $uri"); // Log

    try {
        final response = await http.get(uri, headers: headers);
        if (response.statusCode == 200) {
          final List data = json.decode(response.body);
          return data.map((json) => Usuario.fromJson(json)).toList();
        } else {
          print('[UserService] Error fetchAllUsuarios: ${response.statusCode} ${response.body}');
          // Considera lanzar una excepción o devolver un mensaje de error más específico
          throw Exception('Error al obtener usuarios: ${response.statusCode}');
        }
    } catch (e) {
        print('[UserService] Exception fetchAllUsuarios: $e');
        throw Exception('Error de conexión al obtener usuarios'); // Lanza excepción
    }
  }

  // --- ¡NUEVA FUNCIÓN! ---
  Future<List<String>> fetchGrupos() async { // Devuelve lista o lanza excepción
    final uri = Uri.parse('$_apiUrl/grupos');
    print("[Service] Fetching groups: $uri");
    try {
      final headers = await _getHeaders(includeContentType: false);
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.whereType<String>().toList();
      } else {
        print('[Service] Error fetchGrupos: ${response.statusCode} ${response.body}');
        throw Exception('Error al obtener grupos (${response.statusCode})');
      }
    } catch (e) {
      print('[Service] Exception fetchGrupos: $e');
      throw Exception('Error de conexión al obtener grupos');
    }
  }

  /// [ADMIN] Añade un nuevo usuario
  Future<bool> addUsuario({
    required String nombre,
    required String correo,
    required String contrasena, // Sin hashear
    required String rol,
    required List<String> tiposDeClases,
    String? nombreGrupo,
  }) async {
    final headers = await _getHeaders();
    final body = {
        'nombre': nombre,
        'correo': correo,
        'contrasena': contrasena, // Se envía sin hashear
        'rol': rol,
        'tiposDeClases': tiposDeClases,
        if (nombreGrupo != null && nombreGrupo.isNotEmpty) 'nombreGrupo': nombreGrupo,
      };
    print("Sending addUsuario body: ${jsonEncode(body)}"); // Log para depurar

    // Asegúrate que la URL es la correcta para la creación por admin
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/usuarios'), // O la ruta correcta si está en authRoutes
      headers: headers,
      body: jsonEncode(body),
    );
     print("AddUsuario response: ${response.statusCode} ${response.body}"); // Log para depurar
    return response.statusCode == 201;
  }

  /// [ADMIN] Actualiza datos de un usuario (incluyendo pago y grupo)
  /// Esta es la función que usa 'user_management_viewmodel.dart'
  Future<bool> updateUsuario(String usuarioId, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    
    final response = await http.put(
      Uri.parse('$_apiUrl/$usuarioId'), // Ruta de Admin
      headers: headers,
      body: jsonEncode(data),
    );
    
    return response.statusCode == 200;
  }

  /// [ADMIN] Elimina un usuario
  Future<bool> deleteUsuario(String usuarioId) async {
    final headers = await _getHeaders(includeContentType: false);
    
    // --- LOGS AÑADIDOS ---
    final url = Uri.parse('$_apiUrl/$usuarioId');
    print("[SERVICE] 5. Haciendo http.delete a: $url");
    // -------------------

    final response = await http.delete(
      url, // Usamos la variable
      headers: headers,
    );
    
    // --- LOG AÑADIDO ---
    print("[SERVICE] 6. Respuesta recibida: StatusCode=${response.statusCode}, Body=${response.body}");
    // -------------------

    return response.statusCode == 200;
  }
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }
  
}