// viewmodels/class_management_viewmodel.dart
import 'package:flutter/material.dart';
import '../models/clase.dart';
import '../services/class_service.dart';

class ClassManagementViewModel extends ChangeNotifier {
  final ClassService _classService = ClassService();

  List<Clase> clases = [];
  bool loading = false;
  String? error;

  DateTime? selectedDate;

  Future<void> fetchClasses({DateTime? date}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final fetched = await _classService.fetchClasses(fecha: date);
      clases = fetched;
    } catch (e) {
      error = 'Error cargando clases: $e';
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> deleteClass(String id) async {
    loading = true;
    notifyListeners();
    final result = await _classService.deleteClass(id);
    if (result) await fetchClasses(date: selectedDate);
    loading = false;
    notifyListeners();
    return result;
  }

  Future<bool> deleteAllClasses() async {
    loading = true;
    notifyListeners();
    final result = await _classService.deleteAllClasses();
    if (result) await fetchClasses(date: selectedDate);
    loading = false;
    notifyListeners();
    return result;
  }

  Future<bool> addClass(Clase clase) async {
    loading = true;
    notifyListeners();
    final result = await _classService.addClass(clase);
    if (result) await fetchClasses(date: selectedDate);
    loading = false;
    notifyListeners();
    return result;
  }

  Future<bool> editClass(String id, Clase clase) async {
    loading = true;
    notifyListeners();
    final result = await _classService.editClass(id, clase);
    if (result) await fetchClasses(date: selectedDate);
    loading = false;
    notifyListeners();
    return result;
  }
}
