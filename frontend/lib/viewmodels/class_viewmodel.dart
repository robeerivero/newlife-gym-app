import 'package:flutter/material.dart';
import '../models/clase.dart';
import '../models/usuario.dart';
import '../services/class_service.dart';
import '../services/user_service.dart';

class ClassViewModel extends ChangeNotifier {
  final _classService = ClassService();
  final _userService = UserService();

  List<Clase> nextClasses = [];
  bool isLoading = false;
  String? errorMessage;
  int cancelaciones = 0;

  Future<void> fetchProfile() async {
    final usuario = await _userService.fetchProfile();
    if (usuario != null) {
      cancelaciones = usuario.cancelaciones;
    } else {
      errorMessage = 'Error al obtener el perfil.';
    }
    notifyListeners();
  }

  Future<void> fetchNextClasses() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final data = await _classService.fetchNextClasses();
    if (data != null) {
      nextClasses = data;
    } else {
      errorMessage = 'Error al obtener las próximas clases.';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> cancelClass(String classId, BuildContext context) async {
    final result = await _classService.cancelClass(classId);
    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clase cancelada con éxito.')),
      );
      await fetchNextClasses();
      await fetchProfile();
    } else {
      errorMessage = 'Error al cancelar la clase.';
      notifyListeners();
    }
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }


  Future<void> logout(BuildContext context) async {
    await _userService.logout();
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }
}
