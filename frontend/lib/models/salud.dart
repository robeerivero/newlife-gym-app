import 'dart:convert';
class Salud {
  final String id;
  final String usuario;
  final DateTime fecha;
  final int pasos;
  final double kcalQuemadas;
  final double kcalConsumidas;
  final double kcalQuemadasManual;

  Salud({
    required this.id,
    required this.usuario,
    required this.fecha,
    required this.pasos,
    required this.kcalQuemadas,
    required this.kcalConsumidas,
    required this.kcalQuemadasManual,
  });

  factory Salud.fromJson(Map<String, dynamic> json) {
    return Salud(
      id: json['_id'] ?? '',
      usuario: json['usuario'] ?? '',
      fecha: DateTime.parse(json['fecha']),
      pasos: json['pasos'] is int ? json['pasos'] : (json['pasos'] ?? 0).toInt(),
      kcalQuemadas: (json['kcalQuemadas'] ?? 0.0).toDouble(),
      kcalConsumidas: (json['kcalConsumidas'] ?? 0.0).toDouble(),
      kcalQuemadasManual: (json['kcalQuemadasManual'] ?? 0.0).toDouble(),
    );
  }
}