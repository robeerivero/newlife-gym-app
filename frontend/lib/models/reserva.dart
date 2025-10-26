import 'clase.dart'; // <-- Importamos el modelo Clase

class Reserva {
  final String id;
  final String usuario;
  final Clase clase; // <-- ¡CAMBIO! De String a Clase
  final DateTime fechaReserva;
  final bool asistio;

  Reserva({
    required this.id,
    required this.usuario,
    required this.clase, // <-- ¡CAMBIO!
    required this.fechaReserva,
    required this.asistio,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) {
    return Reserva(
      id: json['_id'] ?? '',
      usuario: json['usuario'] ?? '',
      // ¡CAMBIO! Ahora parseamos el objeto 'clase' anidado
      clase: Clase.fromJson(json['clase'] as Map<String, dynamic>), 
      fechaReserva: DateTime.parse(json['fechaReserva']),
      asistio: json['asistio'] ?? false,
    );
  }
}