import 'package:flutter/material.dart';
import '../models/logro_prenda.dart';
import '../models/logro_progreso.dart';
import '../services/user_service.dart';
import '../services/salud_service.dart';
import '../services/reservation_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LogrosViewModel extends ChangeNotifier {
  final _userService = UserService();
  final _saludService = SaludService();
  final _reservaService = ReservationService();
  final _storage = const FlutterSecureStorage();

  List<LogroPrenda> logros = [];
  Map<String, LogroProgreso> progresos = {}; // key del logro -> progreso
  bool loading = true;
  String? error;

  Future<void> fetchLogrosYProgreso(String userId) async {
    loading = true;
    error = null;
    logros = [];
    progresos = {};
    notifyListeners();
    try {
      final response = await _userService.getLogros();
      if (response != null) {
        logros = response;
        notifyListeners(); // Muestra la lista rápido, aunque sea sin progresos
        // Lanza todos los fetch de progreso en paralelo
        for (var l in logros) {
          _fetchProgresoParaLogro(l, userId).then((progreso) {
            progresos[l.key] = progreso;
            notifyListeners(); // Notifica por cada progreso nuevo
          });
        }
      } else {
        error = 'No se pudieron obtener los logros.';
        notifyListeners();
      }
    } catch (e) {
      error = 'Error al cargar logros: $e';
      notifyListeners();
    }
    loading = false;
    notifyListeners();
  }



  /// Lógica para obtener el progreso de un logro
  Future<LogroProgreso> _fetchProgresoParaLogro(LogroPrenda logro, String userId) async {
    int? totalAsistencias;
    int? rachaActual;
    int? pasosHoy;
    int? kcalHoy;

    // ----- ASISTENCIAS Y RACHAS -----
    if (logro.logro != null && (logro.logro!.toLowerCase().contains("asistencia") || logro.logro!.toLowerCase().contains("racha"))) {
      try {
        final token = await _storage.read(key: 'jwt_token');
        final data = await _reservaService.fetchAsistenciasUsuario(userId, token!);
        if (data != null) {
          totalAsistencias = data['totalAsistencias'] ?? 0;
          List<DateTime> fechas = (data['fechas'] as List<dynamic>)
              .map((f) => DateTime.parse(f as String))
              .toList();
          fechas.sort();
          rachaActual = _calcularRacha(fechas);
        }
      } catch (_) {}
    }

    // ----- PASOS Y KCAL DIARIOS -----
    if (logro.logro != null && (logro.logro!.toLowerCase().contains("pasos") || logro.logro!.toLowerCase().contains("kcal"))) {
      final hoy = DateTime.now();
      final fechaHoy = "${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}";
      final salud = await _saludService.fetchSaludDia(fechaHoy);
      if (salud != null) {
        pasosHoy = salud.pasos;
        kcalHoy = (salud.kcalQuemadas + salud.kcalQuemadasManual).round();
      }
    }

    return LogroProgreso(
      totalAsistencias: totalAsistencias,
      rachaActual: rachaActual,
      pasosHoy: pasosHoy,
      kcalHoy: kcalHoy,
    );
  }

  int _calcularRacha(List<DateTime> fechas) {
    if (fechas.isEmpty) return 0;
    fechas.sort();
    int maxRacha = 1;
    int racha = 1;
    for (int i = 1; i < fechas.length; i++) {
      final diff = fechas[i].difference(fechas[i - 1]).inDays;
      if (diff == 1) {
        racha++;
        if (racha > maxRacha) maxRacha = racha;
      } else if (diff > 1) {
        racha = 1;
      }
    }
    return maxRacha;
  }
}
