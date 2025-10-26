// viewmodels/edit_profile_viewmodel.dart
// ¡CORREGIDO! Ahora pasa 'tiposDeClases' al servicio.

import 'package:flutter/material.dart';
import '../services/user_service.dart';

class EditProfileViewModel extends ChangeNotifier {
  final _userService = UserService();

  bool loading = false;
  String? error;

  /// Edita el nombre, correo y tipos de clases del usuario.
  Future<bool> editarPerfilBasico({
    required String nombre,
    required String correo,
    required List<String> tiposDeClases // <-- ¡AÑADIDO!
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    // Llama a la función de servicio con TODOS los parámetros requeridos
    final success = await _userService.editarMiPerfil(
      nombre: nombre,
      correo: correo,
      tiposDeClases: tiposDeClases // <-- ¡AÑADIDO!
    );

    if (!success) {
      error = 'No se pudo actualizar el perfil. ¿El correo ya está en uso?';
    }
    loading = false;
    notifyListeners();
    return success;
  }

  /// Cambia la contraseña del usuario.
  Future<bool> cambiarContrasena(String actual, String nueva) async {
    loading = true;
    error = null;
    notifyListeners();
    final success = await _userService.cambiarContrasena(actual, nueva);
    if (!success) {
      error = 'No se pudo cambiar la contraseña. ¿Contraseña actual incorrecta?';
    }
    loading = false;
    notifyListeners();
    return success;
  }
}