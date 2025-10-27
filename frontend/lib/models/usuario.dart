// models/usuario.dart
// ¡MODIFICADO! Añadidos campos de dieta y entrenamiento.

import 'dart:convert';

class Usuario {
  final String id;
  final String nombre;
  final String correo;
  final String rol;
  final int cancelaciones;
  final List<String> tiposDeClases;
  final Map<String, dynamic> avatar; 
  final List<dynamic> desbloqueados;
  
  // --- Datos Metabólicos (MODIFICADOS) ---
  final String genero;
  final int edad;
  final double altura;
  final double peso;
  // final String nivelActividad; // <-- ELIMINADO
  final String ocupacion;      // <-- AÑADIDO (de la dieta)
  final String ejercicio;      // <-- AÑADIDO (de la dieta)
  final String objetivo;
  final int kcalObjetivo;

  // Campos Premium
  final bool esPremium;
  final bool incluyePlanDieta;
  final bool incluyePlanEntrenamiento;
  
  // --- Inputs Dieta (MODIFICADOS) ---
  final String dietaAlergias;
  final String dietaPreferencias;
  final int dietaComidas;
  final String historialMedico;   // <-- AÑADIDO
  final String horarios;          // <-- AÑADIDO
  final String platosFavoritos;   // <-- AÑADIDO
  
  // --- Inputs Entrenamiento (MODIFICADOS) ---
  final String premiumMeta;
  final String premiumFoco;
  final String premiumEquipamiento;
  final int premiumTiempo;
  final String premiumNivel;        // <-- AÑADIDO
  final int premiumDiasSemana;    // <-- AÑADIDO
  final String premiumLesiones;     // <-- AÑADIDO

  // Nuevos Campos
  final bool haPagado;
  final String? nombreGrupo; 

  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.cancelaciones,
    required this.tiposDeClases,
    required this.avatar,
    required this.desbloqueados,
    required this.genero,
    required this.edad,
    required this.altura,
    required this.peso,
    // required this.nivelActividad, // <-- ELIMINADO
    required this.ocupacion,      // <-- AÑADIDO
    required this.ejercicio,      // <-- AÑADIDO
    required this.objetivo,
    required this.kcalObjetivo,
    required this.esPremium,
    required this.incluyePlanDieta,
    required this.incluyePlanEntrenamiento,
    required this.dietaAlergias,
    required this.dietaPreferencias,
    required this.dietaComidas,
    required this.historialMedico,   // <-- AÑADIDO
    required this.horarios,          // <-- AÑADIDO
    required this.platosFavoritos,   // <-- AÑADIDO
    required this.premiumMeta,
    required this.premiumFoco,
    required this.premiumEquipamiento,
    required this.premiumTiempo,
    required this.premiumNivel,        // <-- AÑADIDO
    required this.premiumDiasSemana,    // <-- AÑADIDO
    required this.premiumLesiones,     // <-- AÑADIDO
    required this.haPagado,
    this.nombreGrupo,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    // --- LÓGICA DE PARSEO DE AVATAR (sin cambios) ---
    Map<String, dynamic> parsedAvatar = {}; 
    if (json['avatar'] is Map<String, dynamic>) {
      parsedAvatar = json['avatar'];
    } else if (json['avatar'] is String) {
      try {
        var decoded = jsonDecode(json['avatar']);
        if (decoded is Map<String, dynamic>) {
          parsedAvatar = decoded;
        }
      } catch (e) {
        print('Warning: Could not parse avatar string: ${json['avatar']}');
      }
    }
    // --- FIN CORRECCIÓN AVATAR ---

    return Usuario(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      correo: json['correo'] ?? '',
      rol: json['rol'] ?? 'cliente',
      cancelaciones: json['cancelaciones'] ?? 0,
      tiposDeClases: List<String>.from(json['tiposDeClases'] ?? []),
      avatar: parsedAvatar, 
      desbloqueados: json['desbloqueados'] ?? [],
      
      // Metabólicos / Dieta
      genero: json['genero'] ?? 'masculino',
      edad: (json['edad'] ?? 25).toInt(),
      altura: (json['altura'] ?? 170.0).toDouble(),
      peso: (json['peso'] ?? 70.0).toDouble(),
      ocupacion: json['ocupacion'] ?? 'sedentaria', 
      ejercicio: json['ejercicio'] ?? '0',           
      objetivo: json['objetivo'] ?? 'mantener',
      kcalObjetivo: (json['kcalObjetivo'] ?? 2000).toInt(),
      
      // Premium
      esPremium: json['esPremium'] ?? false,
      incluyePlanDieta: json['incluyePlanDieta'] ?? false,
      incluyePlanEntrenamiento: json['incluyePlanEntrenamiento'] ?? false,
      
      // Inputs Dieta
      dietaAlergias: json['dietaAlergias'] ?? 'Ninguna',
      dietaPreferencias: json['dietaPreferencias'] ?? 'Omnívoro',
      dietaComidas: (json['dietaComidas'] ?? 4).toInt(),
      historialMedico: json['historialMedico'] ?? '',
      horarios: json['horarios'] ?? '',
      platosFavoritos: json['platosFavoritos'] ?? '',

      // Inputs Entrenamiento
      premiumMeta: json['premiumMeta'] ?? 'perder_peso',
      premiumFoco: json['premiumFoco'] ?? 'general',
      premiumEquipamiento: json['premiumEquipamiento'] ?? 'solo_cuerpo',
      premiumTiempo: (json['premiumTiempo'] ?? 45).toInt(),
      premiumNivel: json['premiumNivel'] ?? 'principiante',        // <-- AÑADIDO
      premiumDiasSemana: (json['premiumDiasSemana'] ?? 4).toInt(), // <-- AÑADIDO
      premiumLesiones: json['premiumLesiones'] ?? 'Ninguna',       // <-- AÑADIDO
      
      // Otros
      haPagado: json['haPagado'] ?? false,
      nombreGrupo: json['nombreGrupo'], 
    );
  }
}