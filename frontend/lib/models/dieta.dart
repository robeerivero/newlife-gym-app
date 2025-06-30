import 'plato.dart';

class Dieta {
  final String id;
  final String usuario;
  final DateTime fecha;
  final List<Plato> platos;

  Dieta({
    required this.id,
    required this.usuario,
    required this.fecha,
    required this.platos,
  });

  factory Dieta.fromJson(Map<String, dynamic> json) {
    return Dieta(
      id: json['_id'] ?? '',
      usuario: json['usuario'] is Map
          ? json['usuario']['_id'] ?? ''
          : json['usuario'] ?? '',
      fecha: DateTime.tryParse(json['fecha'] ?? '') ?? DateTime.now(),
      platos: (json['platos'] as List? ?? [])
          .map((e) => Plato.fromJson(e))
          .toList(),
    );
  }
}
