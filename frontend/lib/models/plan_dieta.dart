// models/plan_dieta.dart
// ¡MODIFICADO! Añadido campo 'listaCompra'

// Representa un plato generado por IA (texto libre)
class PlatoGenerado {
  final String nombrePlato;
  final int kcalAprox;
  final String ingredientes;
  final String receta;

  PlatoGenerado({
    required this.nombrePlato,
    required this.kcalAprox,
    required this.ingredientes,
    required this.receta,
  });

  factory PlatoGenerado.fromJson(Map<String, dynamic> json) {
    return PlatoGenerado(
      nombrePlato: json['nombrePlato'] ?? 'Plato sin nombre',
      kcalAprox: (json['kcalAprox'] as num?)?.toInt() ?? 0,
      ingredientes: json['ingredientes'] ?? '',
      receta: json['receta'] ?? '',
    );
  }
  
  // Para la edición por el admin
  Map<String, dynamic> toJson() => {
    'nombrePlato': nombrePlato,
    'kcalAprox': kcalAprox,
    'ingredientes': ingredientes,
    'receta': receta,
  };
}

// Representa una comida del día (ej. "Desayuno") con sus opciones
class ComidaDia {
  final String nombreComida;
  final List<PlatoGenerado> opciones;

  ComidaDia({required this.nombreComida, required this.opciones});

  factory ComidaDia.fromJson(Map<String, dynamic> json) {
    return ComidaDia(
      nombreComida: json['nombreComida'] ?? 'Comida sin nombre',
      opciones: (json['opciones'] as List<dynamic>?) // Ajuste leve
          ?.map((e) => PlatoGenerado.fromJson(e as Map<String, dynamic>))
          .toList() ?? [], // Maneja lista nula
    );
  }
  
  // Para la edición por el admin
  Map<String, dynamic> toJson() => {
    'nombreComida': nombreComida,
    'opciones': opciones.map((o) => o.toJson()).toList(),
  };
}

// Representa la dieta de un tipo de día (ej. "Lunes a Viernes")
class DiaDieta {
  final String nombreDia;
  final int kcalDiaAprox;
  final List<ComidaDia> comidas;

  DiaDieta({
    required this.nombreDia,
    required this.kcalDiaAprox,
    required this.comidas,
  });

  factory DiaDieta.fromJson(Map<String, dynamic> json) {
    return DiaDieta(
      nombreDia: json['nombreDia'] ?? 'Día sin nombre',
      kcalDiaAprox: (json['kcalDiaAprox'] as num?)?.toInt() ?? 0,
      comidas: (json['comidas'] as List<dynamic>?) // Ajuste leve
          ?.map((e) => ComidaDia.fromJson(e as Map<String, dynamic>))
          .toList() ?? [], // Maneja lista nula
    );
  }
  
  // Para la edición por el admin
  Map<String, dynamic> toJson() => {
    'nombreDia': nombreDia,
    'kcalDiaAprox': kcalDiaAprox,
    'comidas': comidas.map((c) => c.toJson()).toList(),
  };
}

// Representa el plan de dieta completo del mes para un usuario
class PlanDieta {
  final String id; // ID del documento PlanDieta en MongoDB
  final String usuarioId;
  final String usuarioNombre; // <-- NUEVO
  final String? usuarioGrupo;
  final String mes;
  final Map<String, dynamic> inputsUsuario;
  final List<DiaDieta> planGenerado;
  final String estado; // 'pendiente_solicitud', 'pendiente_revision', 'aprobado'

  // --- ¡NUEVO CAMPO! ---
  final Map<String, dynamic> listaCompra;

  PlanDieta({
    required this.id,
    required this.usuarioId,
    required this.usuarioNombre,
    this.usuarioGrupo,
    required this.mes,
    required this.inputsUsuario,
    required this.planGenerado,
    required this.estado,
    required this.listaCompra, // <-- Añadido al constructor
  });

  factory PlanDieta.fromJson(Map<String, dynamic> json) {
    // --- LÓGICA MEJORADA PARA 'usuario' ---
    String usuarioId;
    String usuarioNombre;
    String? usuarioGrupo;

    if (json['usuario'] is Map) {
      // Opción 1: El backend envió el usuario populado (¡Ideal!)
      usuarioId = json['usuario']['_id'] ?? '';
      usuarioNombre = json['usuario']['nombre'] ?? 'Sin Nombre';
      usuarioGrupo = json['usuario']['nombreGrupo']; // Es nulable, está bien
    } else {
      // Opción 2: El backend solo envió el ID (Fallback)
      usuarioId = json['usuario']?.toString() ?? '';
      // Intentamos obtener el nombre de 'inputsUsuario' como fallback
      usuarioNombre = (json['inputsUsuario'] as Map?)?['usuarioNombre']?.toString() ?? 'ID: $usuarioId';
      usuarioGrupo = null;
    }
    // ------------------------------------

    return PlanDieta(
      id: json['_id'] ?? '',
      usuarioId: usuarioId, // <-- Asignado
      usuarioNombre: usuarioNombre, // <-- Asignado
      usuarioGrupo: usuarioGrupo, // <-- Asignado
      mes: json['mes'] ?? '',
      inputsUsuario: (json['inputsUsuario'] as Map?)?.cast<String, dynamic>() ?? {},
      planGenerado: (json['planGenerado'] as List<dynamic>?) // Ajuste leve
          ?.map((e) => DiaDieta.fromJson(e as Map<String, dynamic>))
          .toList() ?? [], // Maneja lista nula
      estado: json['estado'] ?? 'pendiente_solicitud',
      
      // --- ¡NUEVO CAMPO PARSEADO! ---
      // El backend lo envía como 'listaCompraGenerada'
      listaCompra: (json['listaCompraGenerada'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }
}