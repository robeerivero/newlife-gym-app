import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../config.dart';
import '../models/usuario.dart';         
import '../models/usuario_ranking.dart';
import '../models/logro_prenda.dart';

class UserService {
  final _storage = const FlutterSecureStorage();

  /// Obtiene el perfil del usuario autenticado (¡Devuelve Usuario!)
  Future<Usuario?> fetchProfile() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/usuarios/perfil'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return Usuario.fromJson(json.decode(response.body));
    }
    return null;
  }

  /// Obtiene todos los usuarios (para administración)
  Future<List<Usuario>?> fetchAllUsuarios() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/usuarios'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map<Usuario>((json) => Usuario.fromJson(json)).toList();
    }
    return null;
  }

  /// Añade un nuevo usuario (admin)
  Future<bool> addUsuario({
    required String nombre,
    required String correo,
    required String contrasena,
    required String rol,
    required List<String> tiposDeClases,
  }) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/usuarios'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'nombre': nombre,
        'correo': correo,
        'contrasena': contrasena,
        'rol': rol,
        'tiposDeClases': tiposDeClases,
      }),
    );
    return response.statusCode == 201;
  }

  /// Actualiza un usuario (admin)
  Future<bool> updateUsuario({
    required String id,
    required String nombre,
    required String correo,
    required String rol,
    required List<String> tiposDeClases,
    String? contrasenaActual,
    String? nuevaContrasena,
  }) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return false;

    final Map<String, dynamic> body = {
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
      'tiposDeClases': tiposDeClases,
    };

    // Solo añade los campos de contraseña si el admin quiere cambiarlas
    if (contrasenaActual != null && nuevaContrasena != null) {
      body['contrasenaActual'] = contrasenaActual;
      body['nuevaContrasena'] = nuevaContrasena;
    }

    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/api/usuarios/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );
    return response.statusCode == 200;
  }

  /// Elimina un usuario (admin)
  Future<bool> deleteUsuario(String id) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/api/usuarios/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  /// Guarda el avatar del usuario
  Future<bool> guardarAvatar(String avatarJson) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return false;

    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/api/usuarios/avatar'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'avatar': avatarJson}),
    );
    return response.statusCode == 200;
  }

  /// Edita el perfil (solo para el usuario actual)
  Future<bool> editarPerfil({required String nombre, required String correo}) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return false;

    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/api/usuarios/perfil'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'nombre': nombre, 'correo': correo}),
    );
    return response.statusCode == 200;
  }

  Future<bool> cambiarContrasena(String actual, String nueva) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return false;

    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/api/usuarios/perfil/contrasena'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contrasenaActual': actual,
        'nuevaContrasena': nueva,
      }),
    );
    return response.statusCode < 400;
  }

  /// Ranking mensual
  Future<List<UsuarioRanking>?> getRanking() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/usuarios/ranking-mensual'),
      headers: { 'Authorization': 'Bearer $token' },
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map<UsuarioRanking>((json) => UsuarioRanking.fromJson(json)).toList();
    }
    return null;
  }

  /// Logros y prendas
  Future<List<LogroPrenda>?> getLogros() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/usuarios/prendas/progreso'),
      headers: { 'Authorization': 'Bearer $token' },
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map<LogroPrenda>((json) => LogroPrenda.fromJson(json)).toList();
    }
    return null;
  }

  /// Logout helper (opcional, para centralizar)
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }
}
