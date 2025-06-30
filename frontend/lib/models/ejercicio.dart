class Ejercicio {
  final String id;
  final String nombre;
  final String video;
  final String descripcion;
  final String dificultad;

  Ejercicio({
    required this.id,
    required this.nombre,
    required this.video,
    required this.descripcion,
    required this.dificultad,
  });

  factory Ejercicio.fromJson(Map<String, dynamic> json) {
    return Ejercicio(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      video: json['video'] ?? '',
      descripcion: json['descripcion'] ?? '',
      dificultad: json['dificultad'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'video': video,
      'descripcion': descripcion,
      'dificultad': dificultad,
    };
  }
}
