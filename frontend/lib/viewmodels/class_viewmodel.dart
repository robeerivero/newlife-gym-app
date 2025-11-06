// viewmodels/class_viewmodel.dart
// ¡ACTUALIZADO PARA CANCELACIÓN Y RESTRICCIÓN DE DÍAS!

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/reserva.dart';
import '../models/plan_entrenamiento.dart';
import '../models/usuario.dart';
import '../services/class_service.dart';
import '../services/user_service.dart';
import '../services/ia_entrenamiento_service.dart';
import '../services/qr_service.dart';

// Helper para comparar fechas ignorando la hora
bool isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class ClassViewModel extends ChangeNotifier {
  // --- Servicios ---
  final ClassService _classService = ClassService();
  final UserService _userService = UserService();
  final IAEntrenamientoService _iaEntrenamientoService = IAEntrenamientoService();
  final QRService _qrService = QRService();

  // --- Estado del Usuario ---
  Usuario? _currentUser;
  Usuario? get currentUser => _currentUser;
  bool get esPremium => _currentUser?.esPremium ?? false;
  bool get incluyePlanEntrenamiento => _currentUser?.incluyePlanEntrenamiento ?? false;
  int get cancelaciones => _currentUser?.cancelaciones ?? 0;

  // --- Estado del Calendario ---
  DateTime _focusedDay = DateTime.now();
  // Asegura que el día seleccionado nunca sea anterior a hoy
  DateTime _selectedDay = DateTime.now().isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))
                          ? DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
                          : DateTime.now();
  DateTime get focusedDay => _focusedDay;
  DateTime get selectedDay => _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  CalendarFormat get calendarFormat => _calendarFormat;
  // --- NUEVO: Fecha de inicio para el calendario ---
  DateTime get firstCalendarDay => DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);


  // --- Datos ---
  final Map<DateTime, List<Reserva>> _reservasCache = {};
  DiaEntrenamiento? _rutinaDelDia;
  DiaEntrenamiento? get rutinaDelDia => _rutinaDelDia;
  bool _isRutinaLoading = false;
  bool get isRutinaLoading => _isRutinaLoading;
  // --- NUEVO: Estado después de cancelar ---
  bool cancelSuccessCreditGranted = false; // Indica si la cancelación dio crédito


  // --- Estado de Carga y Errores ---
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;

  ClassViewModel() {
    // Asegura que selectedDay no sea pasado al inicio
    if (_selectedDay.isBefore(firstCalendarDay)) {
      _selectedDay = firstCalendarDay;
    }
    _focusedDay = _selectedDay; // Enfoca el día inicial
    _init();
  }

  void _init() async {
    _isLoading = true;
    notifyListeners();
    await fetchProfile();
    await fetchReservasParaMes(_focusedDay);

    final hoyUtc = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (incluyePlanEntrenamiento && getReservasParaDia(hoyUtc).isEmpty) {
      await _fetchRutinaParaDia(_selectedDay);
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Carga/Recarga el perfil completo del usuario desde el backend.
  Future<void> fetchProfile() async {
    _error = null;
    try {
       _currentUser = await _userService.fetchProfile();
       if (_currentUser == null) _error = 'Error al obtener el perfil.';
    } catch (e) {
       _error = 'Error de conexión al obtener perfil.';
       _currentUser = null;
    }
    // No notificamos aquí para evitar repintados innecesarios
  }

  /// Carga las reservas de clases presenciales para un mes dado.
  Future<void> fetchReservasParaMes(DateTime mes) async {
    _error = null;
    final primerDia = DateTime(mes.year, mes.month, 1);
    final ultimoDia = DateTime(mes.year, mes.month + 1, 0);
    try {
      final reservas = await _classService.fetchReservasPorRango(primerDia, ultimoDia);
      _reservasCache.clear();
      for (var reserva in reservas) {
        final dia = DateTime.utc(reserva.clase.fecha.year, reserva.clase.fecha.month, reserva.clase.fecha.day);
        _reservasCache[dia] ??= [];
        _reservasCache[dia]!.add(reserva);
      }
    } catch (e) {
      _error = "Error al cargar reservas: $e";
    }
    notifyListeners();
  }

  /// Intenta cargar la rutina de entrenamiento IA para un día específico.
  Future<void> _fetchRutinaParaDia(DateTime dia) async {
    if (!incluyePlanEntrenamiento) return;
    _rutinaDelDia = null;
    _error = null;
    _isRutinaLoading = true;
    notifyListeners();
    try {
      _rutinaDelDia = await _iaEntrenamientoService.obtenerRutinaDelDia(dia);
    } catch (e) {
      if (e.toString().toLowerCase().contains('descanso')) {
        _error = null; // No es un error, es un día libre. No mostramos nada.
      } else {
        _error = e.toString(); // Es un error real (ej. sin conexión).
      }
    } finally {
       _isRutinaLoading = false;
       notifyListeners();
    }
  }

  /// Cancela una reserva de clase presencial.
  /// Cancela clase presencial. Actualiza `cancelSuccessCreditGranted`.
  Future<bool> cancelarClase(String classId) async {
    _error = null;
    cancelSuccessCreditGranted = false; // --- Resetea el flag ---
    notifyListeners();
    int cancelacionesAntes = cancelaciones;
    bool success = false;
    try {
      success = await _classService.cancelClass(classId);
      if (success) {
        await fetchProfile(); // Recarga perfil ACTUALIZANDO cancelaciones
        await fetchReservasParaMes(_focusedDay);

        // --- LÓGICA DE CRÉDITO ---
        if (cancelaciones > cancelacionesAntes) { // Compara los nuevos créditos con los viejos
           cancelSuccessCreditGranted = true;
        }
        // -------------------------

        if (incluyePlanEntrenamiento && getReservasParaDia(_selectedDay).isEmpty) {
           await _fetchRutinaParaDia(_selectedDay);
        }
      } else {
        _error = 'El servidor rechazó la cancelación.';
      }
    } catch (e) {
      _error = 'Error de red al cancelar: $e';
    }
    notifyListeners();
    return success;
  }

  /// Registra asistencia con QR.
  Future<String> registrarAsistencia(String qrCode) async {
     _error = null;
     notifyListeners();
     try {
       return await _qrService.registrarAsistencia(qrCode);
     } catch (e) {
       _error = "Error al procesar el QR: $e";
       notifyListeners();
       return _error!;
     }
  }

  /// Cierra la sesión del usuario.
  Future<void> logout(BuildContext context) async {
     await _userService.logout();
     if (context.mounted) {
       Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
     }
  }

  // --- Métodos del Calendario ---

  /// Devuelve reservas para un día.
  List<Reserva> getReservasParaDia(DateTime dia) {
    final diaUtc = DateTime.utc(dia.year, dia.month, dia.day);
    return _reservasCache[diaUtc] ?? [];
  }

  /// Se llama al seleccionar un día. ¡MODIFICADO CON RESTRICCIÓN!
  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
     // 1. Comprobación de día pasado (YA EXISTE)
     final dayUtc = DateTime.utc(selectedDay.year, selectedDay.month, selectedDay.day);
     if (dayUtc.isBefore(firstCalendarDay)) {
       return; // No hace nada si es un día pasado
     }
     
     // --- ¡¡FIX 1: AÑADIDO!! ---
     // 2. Comprobación de mes diferente
     if (selectedDay.month != focusedDay.month) {
       // Si el día seleccionado no es del mes que se está viendo, no hace nada
       return;
     }
     // --- FIN DEL FIX ---

     // 3. Lógica existente
    if (!isSameDay(_selectedDay, selectedDay)) {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _rutinaDelDia = null;
      _error = null;

      // Carga rutina si procede
      if (incluyePlanEntrenamiento && getReservasParaDia(selectedDay).isEmpty) {
        _fetchRutinaParaDia(selectedDay);
      } else {
        _rutinaDelDia = null;
        _isRutinaLoading = false;
      }
      notifyListeners();
    }
  }

  /// Se llama al cambiar de página.
  void onPageChanged(DateTime focusedDay) {
    // Asegura que el foco no vaya al pasado si cambia rápido de mes
     _focusedDay = focusedDay.isBefore(firstCalendarDay) ? firstCalendarDay : focusedDay;
     fetchReservasParaMes(_focusedDay);
  }

  /// Cambia formato mes/semana.
  void onFormatChanged(CalendarFormat format) {
    if (_calendarFormat != format) { _calendarFormat = format; notifyListeners(); }
  }

  /// Formatea fecha.
  String formatDate(DateTime date) {
     return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
