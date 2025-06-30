import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/user_service.dart';

class UserManagementViewModel extends ChangeNotifier {
  final UserService _userService = UserService();

  List<Usuario> usuarios = [];
  bool loading = false;
  String? error;

  UserManagementViewModel() {
    fetchUsuarios();
  }

  Future<void> fetchUsuarios() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      usuarios = await _userService.fetchAllUsuarios() ?? [];
    } catch (e) {
      error = 'Error al cargar usuarios';
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> addUsuario({
    required String nombre,
    required String correo,
    required String contrasena,
    required String rol,
    required List<String> tiposDeClases,
  }) async {
    loading = true;
    notifyListeners();
    try {
      final ok = await _userService.addUsuario(
        nombre: nombre,
        correo: correo,
        contrasena: contrasena,
        rol: rol,
        tiposDeClases: tiposDeClases,
      );
      if (ok) await fetchUsuarios();
      loading = false;
      return ok;
    } catch (e) {
      error = "No se pudo crear usuario";
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUsuario({
    required Usuario usuario,
    required String nombre,
    required String correo,
    required String rol,
    required List<String> tiposDeClases,
    String? contrasenaActual,
    String? nuevaContrasena,
  }) async {
    loading = true;
    notifyListeners();
    try {
      final ok = await _userService.updateUsuario(
        id: usuario.id,
        nombre: nombre,
        correo: correo,
        rol: rol,
        tiposDeClases: tiposDeClases,
        contrasenaActual: contrasenaActual,
        nuevaContrasena: nuevaContrasena,
      );
      if (ok) await fetchUsuarios();
      loading = false;
      return ok;
    } catch (e) {
      error = "No se pudo actualizar usuario";
      loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteUsuario(String id) async {
    loading = true;
    notifyListeners();
    try {
      await _userService.deleteUsuario(id);
      await fetchUsuarios();
    } catch (e) {
      error = "No se pudo eliminar usuario";
    }
    loading = false;
    notifyListeners();
  }
}
