import 'package:flutter/material.dart';
import '../models/plato.dart';
import '../services/plato_service.dart';

class PlatoManagementViewModel extends ChangeNotifier {
  final PlatoService _platoService = PlatoService();

  List<Plato> platos = [];
  bool loading = false;
  String? error;

  Future<void> fetchPlatos() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      platos = await _platoService.fetchPlatos();
    } catch (e) {
      error = 'Error al cargar platos';
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> deletePlato(String id) async {
    loading = true;
    notifyListeners();
    final result = await _platoService.deletePlato(id);
    await fetchPlatos();
    loading = false;
    notifyListeners();
    return result;
  }

  Future<bool> addOrUpdatePlato(Plato plato, {String? id}) async {
    loading = true;
    notifyListeners();
    final result = await _platoService.addOrUpdatePlato(plato, id: id);
    await fetchPlatos();
    loading = false;
    notifyListeners();
    return result;
  }
}
