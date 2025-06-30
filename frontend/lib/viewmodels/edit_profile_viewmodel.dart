import 'package:flutter/material.dart';
import '../services/user_service.dart';

class EditProfileViewModel extends ChangeNotifier {
  final _userService = UserService();

  bool loading = false;
  String? error;

  Future<bool> editarPerfil({required String nombre, required String correo}) async {
    loading = true;
    error = null;
    notifyListeners();
    final success = await _userService.editarPerfil(nombre: nombre, correo: correo);
    if (!success) error = 'No se pudo actualizar el usuario';
    loading = false;
    notifyListeners();
    return success;
  }

  Future<bool> cambiarContrasena(String actual, String nueva) async {
    loading = true;
    error = null;
    notifyListeners();
    final success = await _userService.cambiarContrasena(actual, nueva);
    if (!success) error = 'No se pudo cambiar la contraseña';
    loading = false;
    notifyListeners();
    return success;
  }
}
