class EjercicioRef {
  final String id;
  final String nombre;
  final String video;
  final String descripcion;
  final String dificultad;

  EjercicioRef({
    required this.id,
    required this.nombre,
    required this.video,
    required this.descripcion,
    required this.dificultad,
  });

  factory EjercicioRef.fromJson(dynamic json) {
    if (json is String) {
      return EjercicioRef(
        id: json,
        nombre: '',
        video: '',
        descripcion: '',
        dificultad: '',
      );
    } else if (json is Map<String, dynamic>) {
      return EjercicioRef(
        id: json['_id'] ?? '',
        nombre: json['nombre'] ?? '',
        video: json['video'] ?? '',
        descripcion: json['descripcion'] ?? '',
        dificultad: json['dificultad'] ?? '',
      );
    } else {
      return EjercicioRef(
        id: '',
        nombre: '',
        video: '',
        descripcion: '',
        dificultad: '',
      );
    }
  }
}
