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

  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.cancelaciones,
    required this.tiposDeClases,
    required this.avatar,
    required this.desbloqueados,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      correo: json['correo'] ?? '',
      rol: json['rol'] ?? '',
      cancelaciones: json['cancelaciones'] ?? 0,
      tiposDeClases: (json['tiposDeClases'] as List?)?.map((e) => e.toString()).toList() ?? [],
      avatar: json['avatar'] is String && json['avatar'].isNotEmpty
          ? jsonDecode(json['avatar'])
          : (json['avatar'] as Map<String, dynamic>? ?? {}),
      desbloqueados: json['desbloqueados'] ?? [],
    );
  }
}
