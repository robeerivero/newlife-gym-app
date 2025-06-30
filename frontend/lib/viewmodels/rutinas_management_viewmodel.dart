import 'package:flutter/material.dart';
import '../services/rutinas_service.dart';
import '../models/rutina.dart';

class RutinasManagementViewModel extends ChangeNotifier {
  final RutinasService _service = RutinasService();

  List<Rutina> rutinas = [];
  bool loading = false;
  String? error;

  Future<void> fetchRutinas() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      rutinas = await _service.fetchRutinas();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      rutinas = [];
    }
    loading = false;
    notifyListeners();
  }

  Future<void> deleteRutina(String rutinaId) async {
    loading = true;
    notifyListeners();
    try {
      await _service.deleteRutina(rutinaId);
      await fetchRutinas();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    }
    loading = false;
    notifyListeners();
  }
}
