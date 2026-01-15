import 'clase.dart';

class Reserva {
  final String id;
  final String usuario;
  final Clase clase;
  final DateTime fechaReserva;
  final bool asistio;
  final bool esListaEspera; // <--- NUEVO CAMPO

  Reserva({
    required this.id,
    required this.usuario,
    required this.clase,
    required this.fechaReserva,
    required this.asistio,
    this.esListaEspera = false, // Por defecto false
  });

  factory Reserva.fromJson(Map<String, dynamic> json) {
    return Reserva(
      id: json['_id'] ?? '',
      usuario: json['usuario'] ?? '',
      clase: Clase.fromJson(json['clase'] as Map<String, dynamic>),
      fechaReserva: DateTime.tryParse(json['fechaReserva'] ?? '') ?? DateTime.now(),
      asistio: json['asistio'] ?? false,
      esListaEspera: json['esListaEspera'] ?? false, // <--- LEER EL CAMPO
    );
  }
}