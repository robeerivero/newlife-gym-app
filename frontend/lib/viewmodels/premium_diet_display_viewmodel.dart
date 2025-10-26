// viewmodels/premium_diet_display_viewmodel.dart
// ¡¡ACTUALIZADO PARA SOPORTAR TABLECALENDAR!!

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart'; // Importa para isSameDay
import '../models/plan_dieta.dart';
import '../services/ia_dieta_service.dart';

// Helper para comparar días (lo ponemos aquí para usarlo en cambiarDia)
bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class PremiumDietDisplayViewModel extends ChangeNotifier {
  final IADietaService _dietaService = IADietaService();

  DiaDieta? dietaDelDia;
  bool _isLoading = false;
  String? error;
  DateTime _fechaSeleccionada = DateTime.now();
  
  // --- CAMPOS NUEVOS PARA TABLECALENDAR ---
  DateTime _focusedDay = DateTime.now(); // Para controlar el foco del calendario
  // --- FIN CAMPOS NUEVOS ---

  // --- Getters ---
  bool get isLoading => _isLoading;
  DateTime get fechaSeleccionada => _fechaSeleccionada;
  DateTime get focusedDay => _focusedDay; // Getter para el foco

  PremiumDietDisplayViewModel() {
    // Carga la dieta para el día de hoy al iniciar
    fetchDietaParaDia(DateTime.now());
  }

  /// Carga la dieta aprobada para una fecha específica.
  Future<void> fetchDietaParaDia(DateTime fecha) async {
    _isLoading = true;
    error = null;
    _fechaSeleccionada = fecha;
    // No notificamos aquí para evitar parpadeo si ya hay datos
    // notifyListeners();

    try {
      dietaDelDia = await _dietaService.obtenerDietaDelDia(fecha);
    } catch (e) {
      error = 'Error al cargar la dieta: ${e.toString()}';
      dietaDelDia = null; // Limpia datos en caso de error
    } finally {
      _isLoading = false;
      notifyListeners(); // Actualiza la UI con los datos (o error)
    }
  }

  /// Cambia el día y recarga la dieta.
  void cambiarDia(DateTime nuevaFecha) {
    if (!isSameDay(_fechaSeleccionada, nuevaFecha)) {
       // --- LÓGICA DE CALENDARIO ACTUALIZADA ---
      _fechaSeleccionada = nuevaFecha;
      _focusedDay = nuevaFecha; // Mueve el foco al día seleccionado
      // --- FIN LÓGICA ---
      
      // Recargamos la dieta para el nuevo día
      fetchDietaParaDia(nuevaFecha);
    }
  }

  // --- FUNCIÓN NUEVA PARA TABLECALENDAR ---
  /// Solo cambia el foco del calendario (ej. al cambiar de mes)
  void setFocusedDay(DateTime date) {
    _focusedDay = date;
    notifyListeners();
  }
}