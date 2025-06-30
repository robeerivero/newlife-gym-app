import 'usuario.dart';
import 'ejercicio_ref.dart';

class Rutina {
  final String id;
  final Usuario usuario;
  final String diaSemana;
  final List<EjercicioRutina> ejercicios;

  Rutina({
    required this.id,
    required this.usuario,
    required this.diaSemana,
    required this.ejercicios,
  });

  factory Rutina.fromJson(Map<String, dynamic> json) {
    final usuarioJson = json['usuario'];
    return Rutina(
      id: json['_id'] ?? '',
      usuario: usuarioJson is Map<String, dynamic>
          ? Usuario.fromJson(usuarioJson)
          : Usuario(
              id: usuarioJson ?? '',
              nombre: '',
              correo: '',
              rol: '',
              cancelaciones: 0,
              tiposDeClases: [],
              avatar: {},
              desbloqueados: [],
            ),
      diaSemana: json['diaSemana'] ?? '',
      ejercicios: (json['ejercicios'] as List? ?? [])
          .map((e) => EjercicioRutina.fromJson(e))
          .toList(),
    );
  }
}

class EjercicioRutina {
  final EjercicioRef ejercicio;
  final int series;
  final int repeticiones;

  EjercicioRutina({
    required this.ejercicio,
    required this.series,
    required this.repeticiones,
  });

  factory EjercicioRutina.fromJson(Map<String, dynamic> json) {
    return EjercicioRutina(
      ejercicio: EjercicioRef.fromJson(json['ejercicio']),
      series: json['series'] ?? 3,
      repeticiones: json['repeticiones'] ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ejercicio': ejercicio.id,
      'series': series,
      'repeticiones': repeticiones,
    };
  }

  EjercicioRutina copyWith({
    EjercicioRef? ejercicio,
    int? series,
    int? repeticiones,
  }) {
    return EjercicioRutina(
      ejercicio: ejercicio ?? this.ejercicio,
      series: series ?? this.series,
      repeticiones: repeticiones ?? this.repeticiones,
    );
  }
}
