class Reserva {
  final String id;
  final String usuario;
  final String clase;
  final DateTime fechaReserva;
  final bool asistio;

  Reserva({
    required this.id,
    required this.usuario,
    required this.clase,
    required this.fechaReserva,
    required this.asistio,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) {
    return Reserva(
      id: json['_id'] ?? '',
      usuario: json['usuario'] ?? '',
      clase: json['clase'] ?? '',
      fechaReserva: DateTime.parse(json['fechaReserva']),
      asistio: json['asistio'] ?? false,
    );
  }
}
