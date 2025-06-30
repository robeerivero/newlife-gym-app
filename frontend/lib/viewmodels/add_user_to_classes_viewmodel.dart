import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/reservation_service.dart';
import '../services/user_service.dart';

class AddUserToClassesViewModel extends ChangeNotifier {
  final ReservationService _reservationService = ReservationService();
  final UserService _userService = UserService();  
  List<Usuario> usuarios = [];
  bool loading = false;
  String? error;

  String? selectedUsuarioId;
  String? selectedDay;
  TimeOfDay? selectedTime;

  final List<String> days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];

  Future<void> fetchUsuarios() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      usuarios = await _userService.fetchAllUsuarios() ?? [];
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      usuarios = [];
    }
    loading = false;
    notifyListeners();
  }

  void setUsuario(String? id) {
    selectedUsuarioId = id;
    notifyListeners();
  }

  void setDay(String? day) {
    selectedDay = day;
    notifyListeners();
  }

  void setTime(TimeOfDay? time) {
    selectedTime = time;
    notifyListeners();
  }

  Future<String?> addUserToClasses() async {
    if (selectedUsuarioId == null || selectedDay == null || selectedTime == null) {
      return 'Por favor selecciona todos los campos requeridos.';
    }
    loading = true;
    notifyListeners();
    try {
      final hora = '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
      await _reservationService.addUserToClass(
        usuarioId: selectedUsuarioId!,
        dia: selectedDay!,
        hora: hora,
      );
      loading = false;
      notifyListeners();
      return null; // No error
    } catch (e) {
      loading = false;
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return error;
    }
  }
}
