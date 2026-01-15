import 'package:flutter/material.dart';
import '../services/class_reserve_service.dart';

class ReserveClassViewModel extends ChangeNotifier {
  final ClassReserveService _service = ClassReserveService();

  List<dynamic> classes = [];
  List<String> userClassTypes = [];
  bool isLoading = false;
  String errorMessage = '';
  DateTime selectedDate = DateTime.now();
  int cancelaciones = -1;

  Future<void> initialize() async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      final profile = await _service.fetchUserProfile();
      if (profile == null) {
        errorMessage = 'No se encontró el token. Por favor, inicia sesión nuevamente.';
        isLoading = false;
        notifyListeners();
        return;
      }

      userClassTypes = List<String>.from(profile['tiposDeClases'] ?? []);
      cancelaciones = profile['cancelaciones'] ?? 0;

      if (cancelaciones == 0) {
        errorMessage = 'No puedes reservar debido a cancelaciones pendientes';
        isLoading = false;
        notifyListeners();
        return;
      }
      await fetchClassesForDate(selectedDate);

    } catch (e) {
      errorMessage = 'Error de conexión.';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchClassesForDate(DateTime date) async {
    isLoading = true;
    classes = [];
    errorMessage = '';
    selectedDate = date;
    notifyListeners();

    try {
      final data = await _service.fetchClassesForDate(date);
      classes = data
          .where((clase) => userClassTypes.contains(clase['nombre']))
          .toList();
    } catch (e) {
      errorMessage = 'Error al obtener clases.';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> reserveClass(String classId) async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    // Llamamos al servicio (que ya devuelve un Map según vimos antes)
    final result = await _service.reserveClass(classId);

    isLoading = false;

    if (result['success'] == true) {
      // Actualizamos créditos con la verdad del servidor
      if (result['cancelaciones'] != null) {
        cancelaciones = result['cancelaciones'];
      } else {
        cancelaciones--; // Fallback por seguridad
      }
      
      await fetchClassesForDate(selectedDate);
    } else {
      // Guardamos el mensaje de error para mostrarlo si hiciera falta en la UI
      errorMessage = result['mensaje'] ?? 'Error desconocido';
    }
    
    notifyListeners();
    return result; // Devolvemos el objeto completo
  }

  String formatDate(String date) {
    final parsedDate = DateTime.parse(date);
    return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
  }
}
