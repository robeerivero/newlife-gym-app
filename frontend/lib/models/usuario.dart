// models/usuario.dart
// ¡MODIFICADO! Actualizados los campos de entrenamiento (equipamiento, etc.)

import 'dart:convert';

class Usuario {
  final String id;
  final String nombre;
  final String correo;
  final String rol;
  final int cancelaciones;
  final List<String> tiposDeClases;
  final Map<String, dynamic> avatar; 
  
  // --- Datos Metabólicos (Dieta) ---
  final String genero;
  final int edad;
  final double altura;
  final double peso;
  final String ocupacion;
  final String ejercicio;
  final String objetivo;
  final int kcalObjetivo;

  // Campos Premium
  final bool esPremium;
  final DateTime? solicitudPremium;
  final bool incluyePlanDieta;
  final bool incluyePlanEntrenamiento;
  
  // --- Inputs Dieta (Base + Adherencia) ---
  final String dietaAlergias;
  final String dietaPreferencias;
  final int dietaComidas;
  final String historialMedico;
  final String horarios;
  final String platosFavoritos;
  final String dietaTiempoCocina;
  final String dietaHabilidadCocina;
  final List<String> dietaEquipamiento; // (Este ya estaba como Lista)
  final String dietaContextoComida;
  final String dietaAlimentosOdiados;
  final String dietaRetoPrincipal;
  final String dietaBebidas;
  
  // --- ¡INPUTS DE ENTRENAMIENTO ACTUALIZADOS! ---
  final String premiumMeta;
  final String premiumFoco;
  final List<String> premiumEquipamiento; // ¡CAMBIADO! (Era String)
  final int premiumTiempo;
  final String premiumNivel;
  final int premiumDiasSemana;
  final String premiumLesiones;
  final String premiumEjerciciosOdiados; // ¡NUEVO!
  // -------------------------------------------

  // Otros Campos
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
    // Metabólicos
    required this.genero,
    required this.edad,
    required this.altura,
    required this.peso,
    required this.ocupacion,
    required this.ejercicio,
    required this.objetivo,
    required this.kcalObjetivo,
    // Premium
    required this.esPremium,
    required this.solicitudPremium,
    required this.incluyePlanDieta,
    required this.incluyePlanEntrenamiento,
    // Dieta
    required this.dietaAlergias,
    required this.dietaPreferencias,
    required this.dietaComidas,
    required this.historialMedico,
    required this.horarios,
    required this.platosFavoritos,
    required this.dietaTiempoCocina,
    required this.dietaHabilidadCocina,
    required this.dietaEquipamiento,
    required this.dietaContextoComida,
    required this.dietaAlimentosOdiados,
    required this.dietaRetoPrincipal,
    required this.dietaBebidas,
    
    // ¡ENTRENAMIENTO ACTUALIZADO!
    required this.premiumMeta,
    required this.premiumFoco,
    required this.premiumEquipamiento, // ¡CAMBIADO!
    required this.premiumTiempo,
    required this.premiumNivel,
    required this.premiumDiasSemana,
    required this.premiumLesiones,
    required this.premiumEjerciciosOdiados, // ¡NUEVO!

    required this.haPagado,
    this.nombreGrupo,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    // (Lógica de parseo de avatar sin cambios)
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

    return Usuario(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      correo: json['correo'] ?? '',
      rol: json['rol'] ?? 'cliente',
      cancelaciones: (json['cancelaciones'] as num?)?.toInt() ?? 0,
      tiposDeClases: (json['tiposDeClases'] as List<dynamic>?)?.cast<String>() ?? [],
      avatar: parsedAvatar, 
      
      // Metabólicos (Dieta)
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
      solicitudPremium: json['solicitudPremium'] != null 
          ? DateTime.tryParse(json['solicitudPremium'].toString()) 
          : null,
      incluyePlanDieta: json['incluyePlanDieta'] ?? false,
      incluyePlanEntrenamiento: json['incluyePlanEntrenamiento'] ?? false,
      
      // Dieta
      dietaAlergias: json['dietaAlergias'] ?? 'Ninguna',
      dietaPreferencias: json['dietaPreferencias'] ?? 'Omnívoro',
      dietaComidas: (json['dietaComidas'] ?? 4).toInt(),
      historialMedico: json['historialMedico'] ?? '',
      horarios: json['horarios'] ?? '',
      platosFavoritos: json['platosFavoritos'] ?? '',
      dietaTiempoCocina: json['dietaTiempoCocina'] ?? '15_30_min',
      dietaHabilidadCocina: json['dietaHabilidadCocina'] ?? 'intermedio',
      dietaEquipamiento: (json['dietaEquipamiento'] as List<dynamic>?)?.cast<String>() ?? ['basico'],
      dietaContextoComida: json['dietaContextoComida'] ?? 'casa',
      dietaAlimentosOdiados: json['dietaAlimentosOdiados'] ?? 'Ninguno',
      dietaRetoPrincipal: json['dietaRetoPrincipal'] ?? 'picoteo',
      dietaBebidas: json['dietaBebidas'] ?? 'Principalmente agua',

      // ¡ENTRENAMIENTO ACTUALIZADO!
      premiumMeta: json['premiumMeta'] ?? 'salud_general',
      premiumFoco: json['premiumFoco'] ?? 'Cuerpo completo',
      // ¡CAMBIADO! Lee una lista de strings
      premiumEquipamiento: (json['premiumEquipamiento'] as List<dynamic>?)?.cast<String>() ?? ['solo_cuerpo'],
      premiumTiempo: (json['premiumTiempo'] ?? 45).toInt(),
      premiumNivel: json['premiumNivel'] ?? 'principiante_nuevo',
      premiumDiasSemana: (json['premiumDiasSemana'] ?? 4).toInt(),
      premiumLesiones: json['premiumLesiones'] ?? 'Ninguna',
      premiumEjerciciosOdiados: json['premiumEjerciciosOdiados'] ?? 'Ninguno', // ¡NUEVO!
      
      // Otros
      haPagado: json['haPagado'] ?? false,
      nombreGrupo: json['nombreGrupo'], 
    );
  }
}