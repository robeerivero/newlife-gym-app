import 'package:flutter/material.dart';
import '../models/clase.dart';
import '../services/class_service.dart';

class ClassManagementViewModel extends ChangeNotifier {
  final ClassService _classService = ClassService();

  // ==========================================
  // 1. ESTADO DE LA LISTA Y GESTIÓN GENERAL
  // ==========================================
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
      selectedDate = date; // Actualizamos la fecha seleccionada
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

  // ==========================================
  // 2. ESTADO DEL FORMULARIO DE CREACIÓN MASIVA
  // ==========================================
  
  // Variables de Estado para el formulario
  String? newClassType;
  final List<String> newSelectedDays = [];
  final List<String> newSelectedHours = [];
  final TextEditingController maxParticipantsController = TextEditingController(text: '14');

  // Datos fijos (Listas para los Chips)
  final List<String> availableTypes = ['funcional', 'pilates', 'zumba'];
  final List<String> availableDays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
  final List<String> availableHours = [
    '08:00', '08:30', '09:00', '09:30', '10:00', '10:30',
    '11:00', '11:30', '12:00', '17:00', '17:30', '18:00', 
    '18:30', '19:00', '19:30', '20:00', '20:30', '21:00'
  ];

  // --- Lógica de selección ---

  void setClassType(String? type) {
    newClassType = type;
    notifyListeners();
  }

  void toggleDay(String day) {
    if (newSelectedDays.contains(day)) {
      newSelectedDays.remove(day);
    } else {
      newSelectedDays.add(day);
    }
    notifyListeners();
  }

  void toggleHour(String hour) {
    if (newSelectedHours.contains(hour)) {
      newSelectedHours.remove(hour);
    } else {
      newSelectedHours.add(hour);
    }
    notifyListeners();
  }

  // Helpers para la UI
  bool isDaySelected(String day) => newSelectedDays.contains(day);
  bool isHourSelected(String hour) => newSelectedHours.contains(hour);

  // Limpiar formulario
  void clearMassCreationForm() {
    newSelectedDays.clear();
    newSelectedHours.clear();
    newClassType = null;
    maxParticipantsController.text = '14';
    notifyListeners();
  }

  // --- ACCIÓN PRINCIPAL: CREAR CLASES MASIVAS ---
  
  Future<String?> createMassiveClasses() async {
    // 1. Validar
    if (newClassType == null || newSelectedDays.isEmpty || newSelectedHours.isEmpty) {
      return 'Por favor selecciona tipo, días y horas.';
    }

    loading = true;
    notifyListeners();

    try {
      final maxParticipants = int.tryParse(maxParticipantsController.text) ?? 14;

      // 2. Llamar al servicio
      final result = await _classService.crearClasesRecurrentes(
        nombre: newClassType!,
        dias: newSelectedDays,
        horas: newSelectedHours,
        maximoParticipantes: maxParticipants,
      );

      loading = false;
      notifyListeners();

      if (result['success'] == true) {
        // 3. ¡Éxito! Recargamos la lista general para ver los cambios
        await fetchClasses(date: selectedDate);
        return null; 
      } else {
        return result['mensaje'];
      }
    } catch (e) {
      loading = false;
      notifyListeners();
      return e.toString();
    }
  }
}