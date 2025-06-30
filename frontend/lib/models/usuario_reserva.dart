class UsuarioReserva {
  final String id;
  final String nombre;
  final String correo;
  final bool asistio;

  UsuarioReserva({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.asistio,
  });

  factory UsuarioReserva.fromJson(Map<String, dynamic> json) {
    return UsuarioReserva(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      correo: json['correo'] ?? '',
      asistio: json['asistio'] ?? false,
    );
  }
}
