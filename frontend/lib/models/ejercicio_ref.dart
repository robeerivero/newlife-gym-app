class EjercicioRef {
  final String id;
  final String nombre;

  EjercicioRef({required this.id, required this.nombre});

  factory EjercicioRef.fromJson(dynamic json) {
    if (json is String) {
      return EjercicioRef(id: json, nombre: '');
    } else if (json is Map<String, dynamic>) {
      return EjercicioRef(
        id: json['_id'] ?? '',
        nombre: json['nombre'] ?? '',
      );
    } else {
      return EjercicioRef(id: '', nombre: '');
    }
  }
}
