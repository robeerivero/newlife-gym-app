import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/user_service.dart';

class OnlineClientViewModel extends ChangeNotifier {
  final _userService = UserService();

  Usuario? usuario;
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchProfile() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    usuario = await _userService.fetchProfile();
    if (usuario == null) {
      errorMessage = 'No se pudo obtener el perfil o el token no es válido.';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> logout(BuildContext context) async {
    await _userService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }
}
