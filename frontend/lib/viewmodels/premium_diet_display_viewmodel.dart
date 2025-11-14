// viewmodels/premium_diet_display_viewmodel.dart
// ¡CORREGIDO! Añadida función 'refreshData' pública.

import 'package:flutter/material.dart';
import '../models/plan_dieta.dart';
import '../models/usuario.dart';
import '../services/ia_dieta_service.dart';
import '../services/user_service.dart';

// Helper para comparar días
bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class PremiumDietDisplayViewModel extends ChangeNotifier {
  // --- Servicios ---
  final IADietaService _dietaService = IADietaService();
  final UserService _userService = UserService();

  // --- Estado del Usuario ---
  Usuario? _currentUser;
  Usuario? get currentUser => _currentUser;
  bool get esPremium => _currentUser?.esPremium ?? false;
  bool get incluyePlanDieta => _currentUser?.incluyePlanDieta ?? false;

  // --- Estado de la Dieta ---
  DiaDieta? _dietaDelDia;
  DiaDieta? get dietaDelDia => _dietaDelDia;
  
  // --- Estado Lista de Compra ---
  Map<String, dynamic> _listaCompra = {};
  Map<String, dynamic> get listaCompra => _listaCompra;
  bool get tieneListaCompra => _listaCompra.isNotEmpty;
  // ------------------------------------

  bool _isLoading = true;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;

  // --- Lógica de calendario (la que preferías) ---
  DateTime _fechaSeleccionada = DateTime.now();
  DateTime get fechaSeleccionada => _fechaSeleccionada;
  DateTime _focusedDay = DateTime.now();
  DateTime get focusedDay => _focusedDay;
  // --------------------------------------------------
  
  // --- Estado del Plan ---
  String _estadoPlan = 'cargando';
  String get estadoPlan => _estadoPlan;

  // --- Constructor ---
  PremiumDietDisplayViewModel() {
    _initialize();
  }

  /// Carga el perfil y, si aplica, la dieta y el estado.
  Future<void> _initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _userService.fetchProfile();
      if (_currentUser == null) {
        throw Exception("No se pudo cargar el perfil de usuario.");
      }

      if (!esPremium || !incluyePlanDieta) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      _estadoPlan = await _dietaService.obtenerEstadoPlanDelMes();

      if (_estadoPlan == 'aprobado') {
        await Future.wait([
          _fetchDietaParaDiaInterno(DateTime.now()), // Carga la dieta de hoy
          _fetchListaCompra()
        ]);
      }
      
    } catch (e) {
      _error = "Error al inicializar: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- ¡NUEVO! Función pública para refrescar ---
  /// Vuelve a cargar todos los datos (perfil, estado y dieta).
  Future<void> refreshData() async {
    await _initialize();
  }
  // --------------------------------------------

  /// Carga la lista de la compra
  Future<void> _fetchListaCompra() async {
    try {
      _listaCompra = await _dietaService.obtenerListaCompra();
    } catch (e) {
      print("Error al cargar la lista de la compra: $e");
      _listaCompra = {};
    }
  }

  /// Carga la dieta para una fecha (privado, usado por initialize)
  Future<void> _fetchDietaParaDiaInterno(DateTime fecha) async {
    try {
      _dietaDelDia = await _dietaService.obtenerDietaDelDia(fecha);
    } catch (e) {
      if (!e.toString().toLowerCase().contains('descans')) {
        _error = 'Error al cargar la dieta: ${e.toString()}';
      }
      _dietaDelDia = null;
    }
  }

  /// Carga la dieta para una fecha (público, usado por el calendario)
  Future<void> fetchDietaParaDia(DateTime fecha) async {
    if (!incluyePlanDieta) return;

    _error = null; 
    _fechaSeleccionada = fecha;
    
    // Muestra un spinner PEQUEÑO solo sobre la dieta, no en toda la pantalla
    _dietaDelDia = null; // Limpia la dieta anterior
    notifyListeners(); // Actualiza el día seleccionado
    
    // Ponemos un try-catch local para la carga de la dieta
    try {
      final nuevaDieta = await _dietaService.obtenerDietaDelDia(fecha);
      _dietaDelDia = nuevaDieta;
    } catch (e) {
      if (e.toString().toLowerCase().contains('descans')) {
        _error = null;
        _dietaDelDia = null;
      } else {
        _error = 'Error al cargar la dieta: ${e.toString()}';
        _dietaDelDia = null;
      }
    } finally {
      notifyListeners(); // Notifica con la nueva dieta (o nula)
    }
  }

  /// Cambia el día y recarga la dieta. (onDaySelected)
  void cambiarDia(DateTime nuevaFecha) {
    if (!isSameDay(_fechaSeleccionada, nuevaFecha)) {
      _fechaSeleccionada = nuevaFecha;
      _focusedDay = nuevaFecha;
      fetchDietaParaDia(nuevaFecha); // Llama a fetch público
    }
  }

  /// Actualiza el 'focusedDay' (onPageChanged).
  void setFocusedDay(DateTime newFocusedDay) {
    _focusedDay = newFocusedDay;
    notifyListeners();
  }
}