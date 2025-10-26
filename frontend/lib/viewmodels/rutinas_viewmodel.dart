import 'package:flutter/material.dart';
/*import '../services/rutinas_service.dart';
import '../models/rutina.dart';

class RutinasViewModel extends ChangeNotifier {
  final RutinasService _service = RutinasService();

  bool isLoading = true;
  String errorMessage = '';
  List<Rutina> rutinas = [];

  Future<void> fetchRutinas() async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      rutinas = await _service.fetchRutinasUsuario();
    } catch (e) {
      errorMessage = 'Error de conexión.';
      rutinas = [];
    }
    isLoading = false;
    notifyListeners();
  }
  
}
*/