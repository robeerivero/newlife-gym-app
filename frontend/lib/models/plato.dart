class Plato {
  final String id;
  final String nombre;
  final int kcal;
  final String comidaDelDia;
  final List<String> ingredientes;
  final String instrucciones;
  final int tiempoPreparacion;
  final String? observaciones;

  Plato({
    required this.id,
    required this.nombre,
    required this.kcal,
    required this.comidaDelDia,
    required this.ingredientes,
    required this.instrucciones,
    required this.tiempoPreparacion,
    this.observaciones,
  });

  factory Plato.fromJson(Map<String, dynamic> json) {
    return Plato(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      kcal: json['kcal'] ?? 0,
      comidaDelDia: json['comidaDelDia'] ?? '',
      ingredientes: (json['ingredientes'] as List?)?.map((e) => e.toString()).toList() ?? [],
      instrucciones: json['instrucciones'] ?? '',
      tiempoPreparacion: json['tiempoPreparacion'] ?? 0,
      observaciones: json['observaciones'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'kcal': kcal,
      'comidaDelDia': comidaDelDia,
      'ingredientes': ingredientes,
      'instrucciones': instrucciones,
      'tiempoPreparacion': tiempoPreparacion,
      'observaciones': observaciones,
    };
  }
}
