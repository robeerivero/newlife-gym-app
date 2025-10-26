// viewmodels/metabolic_viewmodel.dart
// ¡ACTUALIZADO!
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/usuario.dart'; // Importa Usuario para verificar si es premium

class MetabolicViewModel extends ChangeNotifier {
  final _userService = UserService();

  bool _loading = false;
  String? _error;
  int _kcalResult = 0;
  bool _isPremium = false; // Para saber si mostrar el mensaje extra

  bool get loading => _loading;
  String? get error => _error;
  int get kcalResult => _kcalResult;

  // Necesitamos saber si el usuario es premium al inicializar
  void setIsPremium(bool isPremium) {
    _isPremium = isPremium;
  }

  Future<bool> guardarDatos(Map<String, dynamic> datos) async {
    _loading = true;
    _error = null;
    _kcalResult = 0;
    notifyListeners();

    // Asegurarse de que los números se envían como números
    datos['peso'] = double.tryParse(datos['peso'] ?? '0') ?? 0.0;
    datos['altura'] = double.tryParse(datos['altura'] ?? '0') ?? 0.0;
    datos['edad'] = int.tryParse(datos['edad'] ?? '0') ?? 0;

    try {
      final response = await _userService.actualizarDatosMetabolicos(datos);

      if (response != null && response.containsKey('kcalObjetivo')) {
        _kcalResult = (response['kcalObjetivo'] as num?)?.toInt() ?? 0;
        _loading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Error al guardar los datos desde el servidor.';
         _loading = false;
         notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión al guardar datos metabólicos.';
       _loading = false;
       notifyListeners();
      return false;
    }
  }

  // Mensaje de éxito a mostrar en el SnackBar
  String getSuccessMessage() {
    String message = '¡Objetivo de $_kcalResult Kcal guardado!';
    if (_isPremium) {
       message += '\nTu plan premium podría actualizarse pronto.';
    }
    return message;
  }
}