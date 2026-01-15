import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/usuario.dart';

// IMPORTANTE: Asegúrate de que esta ruta sea correcta según dónde guardaste tu carpeta fluttermoji
import '../../fluttermoji/fluttermojiFunctions.dart'; 

class ProfileViewModel extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();

  Usuario? usuario;
  String? avatarJson;
  bool loading = true;
  String? error;

  // 👇 Getter de compatibilidad
  bool get isLoading => loading; 

  // ---- CARGAR PERFIL ----
  Future<void> fetchProfile() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/usuarios/perfil'),
        headers: { 'Authorization': 'Bearer $token' },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        usuario = Usuario.fromJson(data);
        
        // 1. Obtener el JSON del avatar (o un objeto vacío serializado si es null)
        avatarJson = data['avatar'] is String
            ? data['avatar']
            : jsonEncode(data['avatar'] ?? {});
            
        // 2. SINCRONIZACIÓN CON FLUTTERMOJI
        // Si el avatar tiene datos válidos, forzamos a la librería a actualizarse.
        // Esto actualiza tanto el SharedPreferences local como el controlador visual (GetX).
        if (avatarJson != null && avatarJson!.contains('topType')) {
           await FluttermojiFunctions().decodeFluttermojifromString(avatarJson!);
        }

      } else {
        error = 'Error al obtener el perfil';
      }
    } catch (e) {
      error = "Error de conexión: $e";
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ---- GUARDAR AVATAR ----
  Future<bool> guardarAvatar(String avatarJsonNew) async {
    loading = true;
    notifyListeners();
    
    try {
      final token = await _storage.read(key: 'jwt_token');
      
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/api/usuarios/avatar'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'avatar': avatarJsonNew}),
      );

      if (response.statusCode == 200) {
        avatarJson = avatarJsonNew;
        // Al guardar, también actualizamos el estado local de la librería por seguridad
        await FluttermojiFunctions().decodeFluttermojifromString(avatarJsonNew);
        
        await fetchProfile(); // Recargamos para asegurar coherencia
        return true;
      } else {
        error = 'Error al guardar el avatar';
        return false;
      }
    } catch (e) {
      error = 'Error de conexión al guardar avatar';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ---- EDITAR PERFIL ----
  Future<bool> editarPerfil({required String nombre, required String correo}) async {
    loading = true;
    notifyListeners();
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/api/usuarios/perfil'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'nombre': nombre, 'correo': correo}),
      );
      if (response.statusCode == 200) {
        await fetchProfile();
        return true;
      } else {
        error = 'Error al editar el perfil';
        return false;
      }
    } catch (e) {
       error = 'Error de conexión';
       return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ---- SOLICITAR PREMIUM ----
  Future<bool> solicitarPremium() async {
    loading = true;
    notifyListeners(); 

    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/usuarios/solicitar-premium'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await fetchProfile(); 
        return true;
      } else {
        error = 'Error al solicitar premium: ${response.body}';
        return false;
      }
    } catch (e) {
      error = 'Error de conexión';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ---- LOGOUT ----
  Future<void> logout(BuildContext context) async {
    await _storage.delete(key: 'jwt_token');
    // Opcional: Limpiar también las preferencias de Fluttermoji al salir
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // await prefs.remove('fluttermojiSelectedOptions');
    
    if (context.mounted) {
       Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}