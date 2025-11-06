// viewmodels/premium_diet_display_viewmodel.dart
// ¡¡VERSIÓN FINAL!!
// Ahora es autónomo, como ClassViewModel.
// Carga su propio perfil de usuario.

import 'package:flutter/material.dart';
import '../models/plan_dieta.dart';
import '../models/usuario.dart'; // <-- Importante
import '../services/ia_dieta_service.dart';
import '../services/user_service.dart'; // <-- Importante

// Helper para comparar días
bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class PremiumDietDisplayViewModel extends ChangeNotifier {
  // --- Servicios ---
  final IADietaService _dietaService = IADietaService();
  final UserService _userService = UserService(); // <-- Como ClassViewModel

  // --- Estado del Usuario ---
  Usuario? _currentUser; // <-- Como ClassViewModel
  Usuario? get currentUser => _currentUser;
  bool get esPremium => _currentUser?.esPremium ?? false;
  bool get incluyePlanDieta => _currentUser?.incluyePlanDieta ?? false;

  // --- Estado de la Dieta ---
  DiaDieta? _dietaDelDia;
  DiaDieta? get dietaDelDia => _dietaDelDia;

  bool _isLoading = true; // Empieza cargando (para el perfil)
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  DateTime _fechaSeleccionada = DateTime.now();
  DateTime get fechaSeleccionada => _fechaSeleccionada;

  DateTime _focusedDay = DateTime.now();
  DateTime get focusedDay => _focusedDay;

  // --- Constructor ---
  PremiumDietDisplayViewModel() {
    // Al crearse, inicializa todo
    _initialize();
  }

  /// Carga el perfil y, si aplica, la dieta.
  Future<void> _initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Carga el perfil del usuario (¡igual que ClassViewModel!)
      _currentUser = await _userService.fetchProfile();

      // 2. Si tiene el servicio de dieta, carga la dieta de hoy
      if (incluyePlanDieta) {
        await fetchDietaParaDia(DateTime.now());
      }
      // Si no tiene el servicio, _isLoading se pondrá en false
      // y la UI mostrará el estado vacío (el banner de "Hazte Premium")

    } catch (e) {
      _error = "Error al inicializar: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga la dieta para una fecha específica (función pública)
  Future<void> fetchDietaParaDia(DateTime fecha) async {
    // Solo carga si tiene el plan
    if (!incluyePlanDieta) return;

    _isLoading = true;
    _error = null;
    _fechaSeleccionada = fecha;
    notifyListeners(); // Muestra el loader

    try {
      _dietaDelDia = await _dietaService.obtenerDietaDelDia(fecha);
    } catch (e) {
      // Maneja "dia de descanso" silenciosamente
      if (e.toString().toLowerCase().contains('descans')) {
        _error = null;
        _dietaDelDia = null;
      } else {
        _error = 'Error al cargar la dieta: ${e.toString()}';
        _dietaDelDia = null;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cambia el día y recarga la dieta. (onDaySelected)
  void cambiarDia(DateTime nuevaFecha) {
    if (!isSameDay(_fechaSeleccionada, nuevaFecha)) {
      _fechaSeleccionada = nuevaFecha;
      _focusedDay = nuevaFecha;
      fetchDietaParaDia(nuevaFecha); // Llama a fetch
    }
  }

  /// Actualiza el 'focusedDay' (onPageChanged).
  void setFocusedDay(DateTime newFocusedDay) {
    _focusedDay = newFocusedDay;
    notifyListeners();
  }
}