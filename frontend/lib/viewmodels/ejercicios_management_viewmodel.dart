import 'package:flutter/material.dart';
import '../models/ejercicio.dart';
import '../services/ejercicio_service.dart';

class EjerciciosManagementViewModel extends ChangeNotifier {
  final EjercicioService _service = EjercicioService();

  List<Ejercicio> ejercicios = [];
  bool loading = false;
  String? error;

  Future<void> fetchEjercicios() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _service.fetchEjercicios();
      if (data != null) {
        ejercicios = data;
      } else {
        error = 'Error al cargar ejercicios';
      }
    } catch (_) {
      error = 'Error de conexión';
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> addEjercicio(Ejercicio ejercicio) async {
    loading = true;
    notifyListeners();
    final success = await _service.addEjercicio(ejercicio);
    if (success) {
      await fetchEjercicios();
    } else {
      error = 'Error al agregar ejercicio';
    }
    loading = false;
    notifyListeners();
    return success;
  }

  Future<bool> editEjercicio(Ejercicio ejercicio) async {
    loading = true;
    notifyListeners();
    final success = await _service.editEjercicio(ejercicio);
    if (success) {
      await fetchEjercicios();
    } else {
      error = 'Error al editar ejercicio';
    }
    loading = false;
    notifyListeners();
    return success;
  }

  Future<bool> deleteEjercicio(String id) async {
    loading = true;
    notifyListeners();
    final success = await _service.deleteEjercicio(id);
    if (success) {
      await fetchEjercicios();
    } else {
      error = 'Error al eliminar ejercicio';
    }
    loading = false;
    notifyListeners();
    return success;
  }
}
