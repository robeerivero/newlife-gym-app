import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'reserve_class_screen.dart';
import '../../config.dart';

class ClassScreen extends StatefulWidget {
  const ClassScreen({super.key});

  @override
  ClassScreenState createState() => ClassScreenState();
}

class ClassScreenState extends State<ClassScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<dynamic> nextClasses = [];
  bool isLoading = false;
  String? _errorMessage;
  int cancelaciones = 0;

  @override
  void initState() {
    super.initState();
    fetchNextClasses();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        setState(() {
          _errorMessage = 'No se encontró el token. Por favor, inicia sesión nuevamente.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/usuarios/perfil'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          cancelaciones = data['cancelaciones'] ?? 0;
        });
      } else {
        setState(() {
          _errorMessage = 'Error al obtener el perfil.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión.';
      });
    }
  }

  Future<void> fetchNextClasses() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        setState(() {
          _errorMessage = 'No se encontró el token. Por favor, inicia sesión nuevamente.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/clases/proximas-clases'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          nextClasses = data;
        });
      } else {
        setState(() {
          _errorMessage = 'Error al obtener las próximas clases.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión.';
      });
    }
  }

  Future<void> cancelClass(String classId) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        setState(() {
          _errorMessage = 'No se encontró el token. Por favor, inicia sesión nuevamente.';
        });
        return;
      }

      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/api/reservas/cancelar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'idClase': classId}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clase cancelada con éxito.')),
        );
        fetchNextClasses();
        _fetchProfile();
      } else {
        setState(() {
          _errorMessage = 'Error al cancelar la clase.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión.';
      });
    }
  }

  String formatDate(String date) {
    final parsedDate = DateTime.parse(date);
    return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: Column(
        children: [
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),          
          Expanded(
            child: nextClasses.isEmpty
                ? const Center(
                    child: Text(
                      'No tienes clases próximas.',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: nextClasses.length,
                    itemBuilder: (context, index) {
                      final classItem = nextClasses[index];
                      return Card(
                        elevation: 30,
                        margin: const EdgeInsets.all(16), // Espaciado adicional
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // Más circular
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16), // Espaciado interno para agrandar la tarjeta
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Título en mayúsculas
                              Text(
                                '${(classItem['dia']).toUpperCase()} - ${(classItem['horaInicio']).toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 20, 
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF42A5F5),
                                ),
                              ),
                              const SizedBox(height: 8), // Espaciado entre el título y el resto
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Fecha: ${formatDate(classItem['fecha'])}',
                                    style: const TextStyle(fontSize: 14),),
                                  Text('Tipo: ${(classItem['nombre'] ?? 'Sin nombre').toUpperCase()}',
                                    style: const TextStyle(fontSize: 14),),
                                ],
                              ),
                              const SizedBox(height: 16), // Espaciado entre detalles y los indicadores
                              Row(
                                children: [
                                  // Indicador para cupos disponibles
                                  Row(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: const BoxDecoration(
                                          color: Colors.green, // Verde para cupos disponibles
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Cupos: ${classItem['cuposDisponibles']}'),
                                    ],
                                  ),
                                  const SizedBox(width: 16), // Espaciado entre indicadores
                                  // Indicador para asistentes
                                  Row(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: const BoxDecoration(
                                          color: Colors.red, // Rojo para asistentes
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Asistentes: ${classItem['maximoParticipantes'] - classItem['cuposDisponibles']}',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16), // Espaciado antes del botón
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: () => cancelClass(classItem['_id']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text('Cancelar'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );

                    },
                  ),
          ),
          if (cancelaciones > 0)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReserveClassScreen(),
                    ),
                  ).then((_) => {fetchNextClasses(),_fetchProfile()});
                },
                icon: const Icon(Icons.add),
                label: const Text('Reservar una clase'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
