import 'package:flutter/material.dart';
import '../models/dieta.dart';
import '../models/plato.dart';
import '../models/usuario.dart';
import '../services/diet_service.dart';
import '../services/user_service.dart';

class DietaManagementViewModel extends ChangeNotifier {
  final DietService _dietService = DietService();
  final UserService _userService = UserService();

  List<Usuario> usuarios = [];
  List<Dieta> dietas = [];
  List<Plato> platos = [];
  Usuario? selectedUsuario;
  bool loading = false;
  String? error;

  DietaManagementViewModel() {
    fetchUsuarios();
    fetchPlatos();
  }

  Future<void> fetchUsuarios() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      usuarios = await _userService.fetchAllUsuarios() ?? [];
      if (usuarios.isNotEmpty) {
        selectedUsuario = usuarios.first;
        await fetchDietas(selectedUsuario!.id);
      }
    } catch (e) {
      error = 'Error al cargar usuarios';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> fetchDietas(String usuarioId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      dietas = await _dietService.fetchDietasDeUsuario(usuarioId) ?? [];
    } catch (e) {
      error = 'Error al cargar dietas';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> fetchPlatos() async {
    try {
      platos = await _dietService.fetchPlatos() ?? [];
      notifyListeners();
    } catch (e) {
      error = 'Error al cargar platos';
      notifyListeners();
    }
  }

  Future<void> addDieta({
    required Usuario usuario,
    required DateTime fecha,
    required List<Plato> platosSeleccionados,
  }) async {
    loading = true;
    notifyListeners();
    try {
      final success = await _dietService.addDieta(usuario.id, fecha, platosSeleccionados);
      if (success) {
        await fetchDietas(usuario.id);
      } else {
        error = "No se pudo añadir la dieta.";
      }
    } catch (_) {
      error = 'Error de conexión al añadir dieta';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> deleteDieta(String id) async {
    loading = true;
    notifyListeners();
    try {
      await _dietService.deleteDieta(id);
      if (selectedUsuario != null) {
        await fetchDietas(selectedUsuario!.id);
      }
    } catch (_) {
      error = 'Error al eliminar dieta';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> deleteAllDietas() async {
    loading = true;
    notifyListeners();
    try {
      await _dietService.deleteAllDietas();
      if (selectedUsuario != null) {
        await fetchDietas(selectedUsuario!.id);
      }
    } catch (_) {
      error = 'Error al eliminar todas las dietas';
    }
    loading = false;
    notifyListeners();
  }
}
