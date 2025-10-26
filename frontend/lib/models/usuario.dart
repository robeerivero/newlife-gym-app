// models/usuario.dart
// ¡CORREGIDO! Parseo de 'avatar' más robusto.

import 'dart:convert';

class Usuario {
  final String id;
  final String nombre;
  final String correo;
  final String rol;
  final int cancelaciones;
  final List<String> tiposDeClases;
  // --- ¡MODIFICADO! Aseguramos que 'avatar' sea siempre un Map ---
  final Map<String, dynamic> avatar; 
  final List<dynamic> desbloqueados;
  
  // Datos Metabólicos
  final String genero;
  final int edad;
  final double altura;
  final double peso;
  final String nivelActividad;
  final String objetivo;
  final int kcalObjetivo;

  // Campos Premium
  final bool esPremium;
  final bool incluyePlanDieta;
  final bool incluyePlanEntrenamiento;
  
  // Inputs Dieta
  final String dietaAlergias;
  final String dietaPreferencias;
  final int dietaComidas;
  
  // Inputs Entrenamiento
  final String premiumMeta;
  final String premiumFoco;
  final String premiumEquipamiento;
  final int premiumTiempo;

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
    required this.avatar, // Sigue siendo Map aquí
    required this.desbloqueados,
    required this.genero,
    required this.edad,
    required this.altura,
    required this.peso,
    required this.nivelActividad,
    required this.objetivo,
    required this.kcalObjetivo,
    required this.esPremium,
    required this.incluyePlanDieta,
    required this.incluyePlanEntrenamiento,
    required this.dietaAlergias,
    required this.dietaPreferencias,
    required this.dietaComidas,
    required this.premiumMeta,
    required this.premiumFoco,
    required this.premiumEquipamiento,
    required this.premiumTiempo,
    required this.haPagado,
    this.nombreGrupo,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    // --- ¡LÓGICA DE PARSEO DE AVATAR CORREGIDA! ---
    Map<String, dynamic> parsedAvatar = {}; // Por defecto, un mapa vacío
    if (json['avatar'] is Map<String, dynamic>) {
      // Si SÍ es un Map, lo usamos directamente
      parsedAvatar = json['avatar'];
    } else if (json['avatar'] is String) {
      // Si es un String, intentamos decodificarlo (si es un JSON string)
      // Si no, se quedará como mapa vacío.
      try {
        var decoded = jsonDecode(json['avatar']);
        if (decoded is Map<String, dynamic>) {
          parsedAvatar = decoded;
        }
      } catch (e) {
        // Ignorar error si no es un JSON string válido, se queda vacío
        print('Warning: Could not parse avatar string: ${json['avatar']}');
      }
    }
    // --- FIN CORRECCIÓN AVATAR ---

    return Usuario(
      id: json['_id'] ?? '', // Mejor añadir un fallback por si acaso
      nombre: json['nombre'] ?? '',
      correo: json['correo'] ?? '',
      rol: json['rol'] ?? 'cliente',
      cancelaciones: json['cancelaciones'] ?? 0,
      tiposDeClases: List<String>.from(json['tiposDeClases'] ?? []),
      
      avatar: parsedAvatar, // <-- Usamos el avatar parseado de forma segura

      desbloqueados: json['desbloqueados'] ?? [],
      genero: json['genero'] ?? 'masculino',
      edad: (json['edad'] ?? 25).toInt(),
      altura: (json['altura'] ?? 170.0).toDouble(),
      peso: (json['peso'] ?? 70.0).toDouble(),
      nivelActividad: json['nivelActividad'] ?? 'sedentario',
      objetivo: json['objetivo'] ?? 'mantener',
      kcalObjetivo: (json['kcalObjetivo'] ?? 2000).toInt(),
      esPremium: json['esPremium'] ?? false,
      incluyePlanDieta: json['incluyePlanDieta'] ?? false,
      incluyePlanEntrenamiento: json['incluyePlanEntrenamiento'] ?? false,
      dietaAlergias: json['dietaAlergias'] ?? 'Ninguna',
      dietaPreferencias: json['dietaPreferencias'] ?? 'Omnívoro',
      dietaComidas: (json['dietaComidas'] ?? 4).toInt(),
      premiumMeta: json['premiumMeta'] ?? 'perder_peso',
      premiumFoco: json['premiumFoco'] ?? 'general',
      premiumEquipamiento: json['premiumEquipamiento'] ?? 'solo_cuerpo',
      premiumTiempo: (json['premiumTiempo'] ?? 45).toInt(),
      haPagado: json['haPagado'] ?? false,
      nombreGrupo: json['nombreGrupo'], 
    );
  }
}