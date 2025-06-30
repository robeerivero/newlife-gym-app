import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/salud_service.dart';
import '../../models/salud.dart';

class SaludViewModel extends ChangeNotifier {
  final SaludService _saludService = SaludService();

  List<Salud> historial = [];
  bool loading = true;
  int objetivoSemanal = 50000;
  StreamSubscription<StepCount>? _stepsSubscription;
  bool permisoDenegado = false;
  int inicialPasos = 0;
  bool _initialized = false;

  SaludViewModel();

  Future<void> inicializarTodo({bool forzar = false}) async {
    if (_initialized && !forzar) return;
    _initialized = true;

    loading = true;
    permisoDenegado = false;
    notifyListeners();

    final permiso = await _saludService.solicitarPermisos();
    if (!permiso) {
      permisoDenegado = true;
      loading = false;
      notifyListeners();
      return;
    }

    await _cargarObjetivo();

    await _saludService.inicializarPasosDiarios();
    inicialPasos = await _saludService.obtenerInicialPasosHoy();

    _stepsSubscription?.cancel();
    _stepsSubscription = Pedometer.stepCountStream.listen((event) async {
      int pasosActual = event.steps - inicialPasos;
      if (pasosActual < 0) pasosActual = 0;
      await _saludService.actualizarBackend(
        pasosActual,
        null,
        null,
      );
      await _actualizarDatos();
    }, onError: (e) {
      _actualizarDatos();
    });

    await _actualizarDatos();
  }

  Future<void> _actualizarDatos() async {
    final hist = await _saludService.obtenerHistorialUltimos7Dias();
    historial = hist;
    loading = false;
    notifyListeners();
  }

  Future<void> _cargarObjetivo() async {
    final prefs = await SharedPreferences.getInstance();
    final semana = _claveSemanaActual();
    final objetivo = prefs.getInt('objetivo_semana_$semana');
    objetivoSemanal = objetivo ?? 50000;
    notifyListeners();
  }

  /// Calcular clave de la semana en local
  String _claveSemanaActual() {
    final ahora = DateTime.now();
    final week = ((int.parse(
      ahora.difference(DateTime(ahora.year, 1, 1)).inDays.toString()) -
      ahora.weekday + 10) ~/ 7);
    return "${ahora.year}-$week";
  }

  Future<void> cambiarObjetivo(int nuevo) async {
    final prefs = await SharedPreferences.getInstance();
    final semana = _claveSemanaActual();
    await prefs.setInt('objetivo_semana_$semana', nuevo);
    objetivoSemanal = nuevo;
    notifyListeners();
  }

  /// Añadir kcal manuales usando los pasos actuales de hoy
  Future<void> anadirKcalManual(double kcal, int pasosHoy) async {
    loading = true;
    notifyListeners();

    await _saludService.actualizarBackend(
      pasosHoy,
      kcal,
      null,
    );
    await Future.delayed(const Duration(milliseconds: 200));
    await _actualizarDatos();
    loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _stepsSubscription?.cancel();
    super.dispose();
  }
}
