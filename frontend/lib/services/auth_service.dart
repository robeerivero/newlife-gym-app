import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class AuthResult {
  final bool success;
  final String? accessToken;
  final String? role;

  AuthResult({required this.success, this.accessToken, this.role});
}

class AuthLoginResult {
  final bool success;
  final String? accessToken;
  final String? role;
  final String? error;

  AuthLoginResult({required this.success, this.accessToken, this.role, this.error});
}

class AuthService {
  Future<AuthResult> verifyToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/auth/verificar-token'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AuthResult(
          success: true,
          accessToken: data['accessToken'],
          role: data['usuario']['rol'],
        );
      }
      return AuthResult(success: false);
    } catch (e) {
      return AuthResult(success: false);
    }
  }

  Future<AuthLoginResult> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'correo': email, 'contrasena': password}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['accessToken'];
        final role = data['usuario']?['rol'];
        if (token != null && role != null) {
          return AuthLoginResult(success: true, accessToken: token, role: role);
        }
        return AuthLoginResult(success: false, error: 'Token vacío recibido');
      } else {
        final data = json.decode(response.body);
        return AuthLoginResult(success: false, error: data['mensaje'] ?? 'Error desconocido');
      }
    } catch (e) {
      return AuthLoginResult(success: false, error: 'Error al conectar con el servidor');
    }
  }
}
