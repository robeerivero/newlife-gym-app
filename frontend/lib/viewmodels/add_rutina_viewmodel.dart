// ==========================
// lib/viewmodels/add_rutina_viewmodel.dart
// ==========================

import 'package:flutter/material.dart';
import '../services/rutinas_service.dart';
import '../models/rutina.dart';
import '../services/ejercicio_service.dart';
import '../services/user_service.dart';
import '../models/usuario.dart';
import '../models/ejercicio.dart';
import '../models/ejercicio_ref.dart';

class AddRutinaViewModel extends ChangeNotifier {
  final RutinasService _rutinasService = RutinasService();
  final EjercicioService _ejercicioService = EjercicioService();
  final UserService _userService = UserService();

  List<Usuario> usuarios = [];
  List<Ejercicio> ejerciciosDisponibles = [];
  List<EjercicioRutina> ejerciciosSeleccionados = [];
  Usuario? selectedUsuario;
  String diaSemana = '';
  String? error;
  bool loading = false;

  Future<void> fetchUsuarios() async {
    usuarios = await _userService.fetchAllUsuarios() ?? [];
    if (usuarios.isNotEmpty) {
      selectedUsuario = usuarios.first;
    }
    notifyListeners();
  }

  Future<void> fetchEjercicios() async {
    ejerciciosDisponibles = await _ejercicioService.fetchEjercicios() ?? [];
    notifyListeners();
  }

  void addEjercicioSeleccionado(Ejercicio ejercicio) {
    ejerciciosSeleccionados.add(
      EjercicioRutina(
        ejercicio: EjercicioRef(
  id: ejercicio.id,
  nombre: ejercicio.nombre,
  video: ejercicio.video,
  descripcion: ejercicio.descripcion,
  dificultad: ejercicio.dificultad,
),
        series: 3,
        repeticiones: 10,
      ),
    );
    notifyListeners();
  }

  void removeEjercicioSeleccionado(int index) {
    ejerciciosSeleccionados.removeAt(index);
    notifyListeners();
  }

  Future<void> crearRutina(BuildContext context) async {
    if (selectedUsuario == null || diaSemana.isEmpty || ejerciciosSeleccionados.isEmpty) {
      error = 'Todos los campos son obligatorios.';
      notifyListeners();
      return;
    }
    loading = true;
    error = null;
    notifyListeners();

    try {
      await _rutinasService.addRutina(selectedUsuario!.id, diaSemana, ejerciciosSeleccionados);
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rutina agregada exitosamente.')),
      );
    } catch (e) {
      error = 'Error al agregar la rutina.';
      notifyListeners();
    }
    loading = false;
    notifyListeners();
  }
}

