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

  // Selección múltiple
  String? selectedUsuarioId;
  final List<String> selectedDays = [];
  final List<String> selectedHours = [];

  // Constantes
  final List<String> days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
  
  final List<String> availableHours = [
    '08:00', '08:30', '09:00', '09:30', '10:00', '10:30',
    '11:00', '11:30', '12:00', '12:30', '13:00', '13:30',
    '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
    '17:00', '17:30', '18:00', '18:30', '19:00', '19:30',
    '20:00', '20:30', '21:00', '21:30'
  ];

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

  // Lógica de chips
  void toggleDay(String day) {
    if (selectedDays.contains(day)) {
      selectedDays.remove(day);
    } else {
      selectedDays.add(day);
    }
    notifyListeners();
  }

  void toggleHour(String hour) {
    if (selectedHours.contains(hour)) {
      selectedHours.remove(hour);
    } else {
      selectedHours.add(hour);
    }
    notifyListeners();
  }

  bool isDaySelected(String day) => selectedDays.contains(day);
  bool isHourSelected(String hour) => selectedHours.contains(hour);

  Future<String?> addUserToClasses() async {
    if (selectedUsuarioId == null || selectedDays.isEmpty || selectedHours.isEmpty) {
      return 'Por favor selecciona un usuario, al menos un día y una hora.';
    }

    loading = true;
    notifyListeners();
    
    try {
      final result = await _reservationService.asignarMasivo(
        usuarioId: selectedUsuarioId!,
        dias: selectedDays,
        horas: selectedHours,
      );

      loading = false;
      notifyListeners();

      if (result['success']) {
        return null; // Éxito
      } else {
        return result['mensaje'] ?? 'Error desconocido';
      }

    } catch (e) {
      loading = false;
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return error;
    }
  }

  // 👇 MÉTODO NUEVO PARA LIMPIAR EL FORMULARIO
  void clearSelection() {
    selectedDays.clear();
    selectedHours.clear();
    // Nota: No borramos el usuario (selectedUsuarioId) para que puedas 
    // seguir añadiéndole más horas si quieres. Si prefieres borrarlo también,
    // descomenta la siguiente línea:
    // selectedUsuarioId = null; 
    notifyListeners();
  }
}