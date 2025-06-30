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
        avatarJson = data['avatar'] is String
            ? data['avatar']
            : jsonEncode(data['avatar'] ?? {});
        // Guarda el avatar para fluttermoji
        if (avatarJson != null && avatarJson!.isNotEmpty) {
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

  // ---- EDITAR PERFIL ----
  Future<bool> editarPerfil({required String nombre, required String correo}) async {
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

  // ---- GUARDAR AVATAR ----
  Future<bool> guardarAvatar(String avatarJsonNew) async {
    loading = true;
    notifyListeners();
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
      // Actualiza local para fluttermoji
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('fluttermojiSelectedOptions', avatarJsonNew);
      await fetchProfile(); // Vuelve a traer datos actualizados
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

  // ---- PRENDAS DESBLOQUEADAS ----
  Future<Map<String, Set<int>>> fetchPrendasDesbloqueadas() async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/usuarios/prendas/desbloqueadas'),
      headers: { 'Authorization': 'Bearer $token' },
    );
    if (response.statusCode == 200) {
      final prendas = jsonDecode(response.body) as List;
      Map<String, Set<int>> map = {};
      for (final prenda in prendas) {
        final key = prenda['key'];
        final idx = prenda['idx'];
        if (idx != null && idx is int) {
          map.putIfAbsent(key, () => <int>{}).add(idx);
        }
      }
      return map;
    }
    throw Exception('Error al cargar prendas desbloqueadas');
  }

  // ---- LOGOUT ----
  Future<void> logout(BuildContext context) async {
    await _storage.delete(key: 'jwt_token');
    Navigator.of(context).pushReplacementNamed('/login');
  }
}
