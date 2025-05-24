import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'reserve_class_screen.dart';
import 'qr_scan_screen.dart';
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        title: const Text('Mis Clases', style: TextStyle(color: Colors.white)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () async {
              await _storage.delete(key: 'jwt_token');
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ],
      ),
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
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.event_available, color: Color(0xFF42A5F5)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${(classItem['dia']).toUpperCase()} - ${(classItem['horaInicio']).toUpperCase()}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E88E5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text('📅 Fecha: ${formatDate(classItem['fecha'])}', style: TextStyle(fontSize: 14, color: Colors.grey[800])),
                              Text('🏷️ Tipo: ${(classItem['nombre'] ?? 'Sin nombre').toUpperCase()}', style: TextStyle(fontSize: 14, color: Colors.grey[800])),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.group, size: 16, color: Colors.green),
                                      const SizedBox(width: 6),
                                      Text('Cupos: ${classItem['cuposDisponibles']}'),
                                    ],
                                  ),
                                  const SizedBox(width: 20),
                                  Row(
                                    children: [
                                      const Icon(Icons.people_alt, size: 16, color: Colors.red),
                                      const SizedBox(width: 6),
                                      Text('Asistentes: ${classItem['maximoParticipantes'] - classItem['cuposDisponibles']}'),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => cancelClass(classItem['_id']),
                                    icon: const Icon(Icons.cancel),
                                    label: const Text('Cancelar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
                                  ),
                                 ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => QRScanScreen(codigoClase: classItem['_id']),
                                        ),
                                      ).then((_) => fetchNextClasses());
                                    },
                                    icon: const Icon(Icons.qr_code_scanner, size: 20),
                                    label: const Text(
                                      'Canjear QR',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigoAccent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      elevation: 3,
                                    ),
                                  ),
                                ],
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
                  ).then((_) => {fetchNextClasses(), _fetchProfile()});
                },
                icon: const Icon(Icons.add),
                label: const Text('Reservar una clase'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
