// models/plan_entrenamiento.dart
// ¡NUEVO ARCHIVO!

// Representa un ejercicio generado por IA (texto libre)
class EjercicioGenerado {
  final String nombre;
  final String series;
  final String repeticiones;
  final String descansoSeries;
  final String descansoEjercicios;
  final String descripcion;

  EjercicioGenerado({
    required this.nombre,
    required this.series,
    required this.repeticiones,
    required this.descansoSeries,
    required this.descansoEjercicios,
    required this.descripcion,
  });

  factory EjercicioGenerado.fromJson(Map<String, dynamic> json) {
    return EjercicioGenerado(
      nombre: json['nombre'] ?? 'Ejercicio sin nombre',
      series: json['series']?.toString() ?? '3', // Convertir a String por si acaso
      repeticiones: json['repeticiones']?.toString() ?? '10',
      descansoSeries: json['descansoSeries'] ?? '60 seg',
      descansoEjercicios: json['descansoEjercicios'] ?? '2 min',
      descripcion: json['descripcion'] ?? '',
    );
  }
  
  // Para la edición por el admin
  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'series': series,
    'repeticiones': repeticiones,
    'descansoSeries': descansoSeries,
    'descansoEjercicios': descansoEjercicios,
    'descripcion': descripcion,
  };
}

// Representa la rutina de un día específico (ej. "Día 1: Pecho y Tríceps")
class DiaEntrenamiento {
  final String nombreDia;
  final List<EjercicioGenerado> ejercicios;

  DiaEntrenamiento({required this.nombreDia, required this.ejercicios});

  factory DiaEntrenamiento.fromJson(Map<String, dynamic> json) {
    return DiaEntrenamiento(
      nombreDia: json['nombreDia'] ?? 'Día sin nombre',
      ejercicios: (json['ejercicios'] as List? ?? [])
          .map((e) => EjercicioGenerado.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
  
  // Para la edición por el admin
  Map<String, dynamic> toJson() => {
    'nombreDia': nombreDia,
    'ejercicios': ejercicios.map((e) => e.toJson()).toList(),
  };
}

// Representa el plan completo del mes para un usuario
class PlanEntrenamiento {
  final String id; // ID del documento PlanEntrenamiento en MongoDB
  final String usuarioId; // Referencia al usuario
  final String usuarioNombre; // <-- NUEVO
  final String? usuarioGrupo;
  final String mes; // Ej: "2025-10"
  final Map<String, dynamic> inputsUsuario; // Las metas que rellenó
  final List<DiaEntrenamiento> planGenerado; // El plan de la IA (editado)
  final String estado; // 'pendiente_solicitud', 'pendiente_ia', 'pendiente_revision', 'aprobado'
  final List<String> diasAsignados; // Ej: ['Martes', 'Jueves']

  PlanEntrenamiento({
    required this.id,
    required this.usuarioId,
    required this.usuarioNombre,
    this.usuarioGrupo,
    required this.mes,
    required this.inputsUsuario,
    required this.planGenerado,
    required this.estado,
    required this.diasAsignados,
  });

  factory PlanEntrenamiento.fromJson(Map<String, dynamic> json) {
    // --- LÓGICA MEJORADA PARA 'usuario' (IDÉNTICA A PlanDieta) ---
    String usuarioId;
    String usuarioNombre;
    String? usuarioGrupo;

    if (json['usuario'] is Map) {
      usuarioId = json['usuario']['_id'] ?? '';
      usuarioNombre = json['usuario']['nombre'] ?? 'Sin Nombre';
      usuarioGrupo = json['usuario']['nombreGrupo'];
    } else {
      usuarioId = json['usuario']?.toString() ?? '';
      usuarioNombre = (json['inputsUsuario'] as Map?)?['usuarioNombre']?.toString() ?? 'ID: $usuarioId';
      usuarioGrupo = null;
    }
    // ------------------------------------

    return PlanEntrenamiento(
      id: json['_id'] ?? '',
      usuarioId: usuarioId,
      usuarioNombre: usuarioNombre, // <-- Asignado
      usuarioGrupo: usuarioGrupo, // <-- Asignado
      mes: json['mes'] ?? '',
      inputsUsuario: (json['inputsUsuario'] as Map?)?.cast<String, dynamic>() ?? {},
      planGenerado: (json['planGenerado'] as List? ?? [])
          .map((e) => DiaEntrenamiento.fromJson(e as Map<String, dynamic>))
          .toList(),
      estado: json['estado'] ?? 'pendiente_solicitud',
      diasAsignados: List<String>.from(json['diasAsignados'] ?? []),
    );
  }
}