import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/usuario.dart';

class ProfileViewModel extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();

  Usuario? usuario;
  String? avatarJson;
  bool loading = true;
  String? error;

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
        
        // Obtenemos el avatar (puede ser String JSON o Map)
        avatarJson = data['avatar'] is String
            ? data['avatar']
            : jsonEncode(data['avatar'] ?? {});
            
        // IMPORTANTE: Sincronizar editor local
        // Si lo que viene de la BD es un JSON de opciones (ej. {top:1, eye:3}),
        // lo guardamos en las preferencias para que FluttermojiController lo lea.
        if (avatarJson != null && avatarJson!.isNotEmpty && avatarJson!.contains('{')) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('fluttermojiSelectedOptions', avatarJson!);
        }
      } else {
        error = 'Error al obtener el perfil';
      }
    } catch (e) {
      error = "Error de conexión";
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ---- GUARDAR AVATAR ----
  Future<bool> guardarAvatar(String avatarJsonNew) async {
    loading = true;
    notifyListeners();
    final token = await _storage.read(key: 'jwt_token');
    
    // Aquí 'avatarJsonNew' es el JSON de opciones {top:1...}
    
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/api/usuarios/avatar'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      // Enviamos el objeto JSON tal cual
      body: jsonEncode({'avatar': avatarJsonNew}),
    );

    if (response.statusCode == 200) {
      avatarJson = avatarJsonNew;
      // No necesitamos escribir en SharedPreferences aquí, 
      // porque el dato 'avatarJsonNew' YA viene de SharedPreferences (leído en la vista).
      
      await fetchProfile(); // Refrescar para asegurar sincronía
      loading = false;
      notifyListeners();
      return true;
    } else {
      error = 'Error al guardar el avatar';
      loading = false;
      notifyListeners();
      return false;
    }
  }

  // ---- EDITAR PERFIL (Texto) ----
  Future<bool> editarPerfil({required String nombre, required String correo}) async {
    // ... (Mismo código que tenías) ...
    loading = true;
    notifyListeners();
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
      loading = false;
      notifyListeners();
      return true;
    } else {
      error = 'Error al editar el perfil';
      loading = false;
      notifyListeners();
      return false;
    }
  }

  // ---- LOGOUT ----
  Future<void> logout(BuildContext context) async {
    await _storage.delete(key: 'jwt_token');
    if (context.mounted) {
       Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}