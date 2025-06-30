class LogroPrenda {
  final String key;
  final String value;
  final String nombre;
  final String categoria;
  final String descripcion;
  final String? logro;
  final bool conseguido;
  final String emoji;

  LogroPrenda({
    required this.key,
    required this.value,
    required this.nombre,
    required this.categoria,
    required this.descripcion,
    required this.logro,
    required this.conseguido,
    required this.emoji,
  });

  factory LogroPrenda.fromJson(Map<String, dynamic> json) {
    return LogroPrenda(
      key: json['key'],
      value: json['value'],
      nombre: json['nombre'],
      categoria: json['categoria'],
      descripcion: json['descripcion'],
      logro: json['logro'],
      conseguido: json['conseguido'] ?? false,
      emoji: json['emoji'] ?? "🎉",
    );
  }
}
