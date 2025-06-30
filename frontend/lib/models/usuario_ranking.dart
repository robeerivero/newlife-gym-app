import 'dart:convert';
class UsuarioRanking {
  final String id;
  final String nombre;
  final Map<String, dynamic> avatar;
  final int asistenciasEsteMes;
  final int pasosEsteMes;

  UsuarioRanking({
    required this.id,
    required this.nombre,
    required this.avatar,
    required this.asistenciasEsteMes,
    required this.pasosEsteMes,
  });

  factory UsuarioRanking.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> avatarDecoded = {};
    if (json['avatar'] != null) {
      if (json['avatar'] is String && json['avatar'].isNotEmpty) {
        avatarDecoded = jsonDecode(json['avatar']);
      } else if (json['avatar'] is Map<String, dynamic>) {
        avatarDecoded = json['avatar'];
      }
    }
    return UsuarioRanking(
      id: json['_id'],
      nombre: json['nombre'],
      avatar: avatarDecoded,
      asistenciasEsteMes: json['asistenciasEsteMes'] ?? 0,
      pasosEsteMes: json['pasosEsteMes'] ?? 0,
    );
  }
}
