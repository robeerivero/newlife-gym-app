class Clase {
  final String id;
  final String nombre;
  final String dia;
  final String horaInicio;
  final String horaFin;
  final DateTime fecha;
  final int cuposDisponibles;
  final int maximoParticipantes;
  final List<String> listaEspera;

  Clase({
    required this.id,
    required this.nombre,
    required this.dia,
    required this.horaInicio,
    required this.horaFin,
    required this.fecha,
    required this.cuposDisponibles,
    required this.maximoParticipantes,
    required this.listaEspera,
  });

  factory Clase.fromJson(Map<String, dynamic> json) {
    return Clase(
      id: json['_id'] ?? '',  // <- Usa _id porque mongo devuelve así
      nombre: json['nombre'] ?? '',
      dia: json['dia'] ?? '',
      horaInicio: json['horaInicio'] ?? '',
      horaFin: json['horaFin'] ?? '',
      fecha: DateTime.tryParse(json['fecha'] ?? '') ?? DateTime.now(),
      cuposDisponibles: json['cuposDisponibles'] ?? 0,
      maximoParticipantes: json['maximoParticipantes'] ?? 0,
      listaEspera: (json['listaEspera'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
