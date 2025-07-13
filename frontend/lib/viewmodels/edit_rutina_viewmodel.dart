import 'package:flutter/material.dart';
import '../models/rutina.dart';
import '../models/usuario.dart';
import '../models/ejercicio.dart';
import '../models/ejercicio_ref.dart';
import '../services/rutinas_service.dart';
import '../services/ejercicio_service.dart';
import '../services/user_service.dart';

class EditRutinaViewModel extends ChangeNotifier {
  final RutinasService rutinasService = RutinasService();
  final EjercicioService ejercicioService = EjercicioService();
  final UserService userService = UserService();

  Rutina? rutina;
  List<Usuario> usuarios = [];
  List<Ejercicio> ejerciciosDisponibles = [];

  bool loading = false;
  String? error;

  String? selectedDiaSemana;
  Usuario? selectedUsuario;
  List<EjercicioRutina> selectedEjercicios = [];

  Future<void> cargarTodo(String rutinaId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      rutina = await rutinasService.fetchRutinaById(rutinaId);

      if (rutina == null) {
        error = 'No se pudo cargar la rutina.';
        loading = false;
        notifyListeners();
        return;
      }

      usuarios = await userService.fetchAllUsuarios() ?? [];
      ejerciciosDisponibles = await ejercicioService.fetchEjercicios() ?? [];

      selectedDiaSemana = rutina!.diaSemana;

      selectedUsuario = usuarios.firstWhere(
        (u) => u.id == rutina!.usuario.id,
        orElse: () {
          usuarios.insert(0, rutina!.usuario);
          return rutina!.usuario;
        },
      );

      selectedEjercicios = rutina!.ejercicios;

    } catch (e) {
      error = 'Error al cargar datos';
    }

    loading = false;
    notifyListeners();
  }

  void updateDiaSemana(String? v) {
    selectedDiaSemana = v;
    notifyListeners();
  }

  void updateUsuario(Usuario? u) {
    selectedUsuario = u;
    notifyListeners();
  }

  void updateEjercicio(int idx, {int? series, int? repeticiones}) {
    final old = selectedEjercicios[idx];
    selectedEjercicios[idx] = old.copyWith(
      series: series ?? old.series,
      repeticiones: repeticiones ?? old.repeticiones,
    );
    notifyListeners();
  }

  void toggleEjercicio(Ejercicio ejercicio) {
    final idx = selectedEjercicios.indexWhere((e) => e.ejercicio.id == ejercicio.id);
    if (idx >= 0) {
      selectedEjercicios.removeAt(idx);
    } else {
      selectedEjercicios.add(
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
    }
    notifyListeners();
  }

  bool isEjercicioSelected(Ejercicio ejercicio) {
    return selectedEjercicios.any((e) => e.ejercicio.id == ejercicio.id);
  }

  int getSeries(Ejercicio ejercicio) {
    final er = selectedEjercicios.firstWhere(
      (e) => e.ejercicio.id == ejercicio.id,
      orElse: () => EjercicioRutina(
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
    return er.series;
  }

  int getReps(Ejercicio ejercicio) {
    final er = selectedEjercicios.firstWhere(
      (e) => e.ejercicio.id == ejercicio.id,
      orElse: () => EjercicioRutina(
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
    return er.repeticiones;
  }

  Future<bool> guardarCambios() async {
    print('🔁 guardarCambios() llamado');

    if (selectedUsuario == null || selectedDiaSemana == null || selectedEjercicios.isEmpty) {
      print('❌ Validación fallida:');
      print('  selectedUsuario: $selectedUsuario');
      print('  selectedDiaSemana: $selectedDiaSemana');
      print('  selectedEjercicios: ${selectedEjercicios.length}');
      error = 'Todos los campos son obligatorios';
      notifyListeners();
      return false;
    }

    if (rutina == null) {
      print('❌ rutina está null al guardar');
      error = 'No se pudo cargar la rutina para editar.';
      notifyListeners();
      return false;
    }

    loading = true;
    error = null;
    notifyListeners();

    try {
      final actualizada = Rutina(
        id: rutina!.id,
        usuario: selectedUsuario!,
        diaSemana: selectedDiaSemana!,
        ejercicios: selectedEjercicios,
      );

      print('📤 Enviando rutina actualizada:');
      print('  ID: ${actualizada.id}');
      print('  Usuario: ${actualizada.usuario.id}');
      print('  Día: ${actualizada.diaSemana}');
      print('  Ejercicios: ${actualizada.ejercicios.map((e) => e.toJson()).toList()}');

      await rutinasService.updateRutina(actualizada);

      print('✅ Rutina actualizada con éxito');
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('🔥 Error en guardarCambios(): $e');
      error = 'Error al guardar cambios';
      loading = false;
      notifyListeners();
      return false;
    }
  }
}
