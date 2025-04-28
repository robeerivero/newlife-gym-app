import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';
import 'reservas/reservations_list_screen.dart'; // Pantalla para listar usuarios de una clase
import 'reservas/add_user_to_classes_screen.dart'; // Pantalla para añadir usuarios a clases

class ReservationManagementScreen extends StatefulWidget {
  const ReservationManagementScreen({Key? key}) : super(key: key);

  @override
  _ReservationManagementScreenState createState() =>
      _ReservationManagementScreenState();
}

class _ReservationManagementScreenState
    extends State<ReservationManagementScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<dynamic> classes = [];
  bool isLoading = false;
  String errorMessage = '';
  DateTime? _selectedDate;

  // Método para obtener clases por fecha
  Future<void> fetchClasses(DateTime? date) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        setState(() {
          errorMessage = 'Token no encontrado. Por favor, inicia sesión nuevamente.';
        });
        return;
      }

      final dateQuery = date != null
          ? '?fecha=${date.toIso8601String().split('T')[0]}'
          : '';

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/admin/clases$dateQuery'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          classes = data;
        });
      } else {
        setState(() {
          errorMessage = json.decode(response.body)['mensaje'] ??
              'Error al obtener las clases.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error de conexión. Por favor, intenta nuevamente.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Método para seleccionar una fecha
  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
      fetchClasses(pickedDate);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchClasses(null); // Obtener todas las clases al iniciar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Reservas'),
        backgroundColor: const Color(0xFF42A5F5),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ElevatedButton.icon(
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_today),
              label: const Text('Seleccionar Fecha'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddUserToClassesScreen(),
                ),
              ),
              icon: const Icon(Icons.person_add),
              label: const Text('Añadir Usuario a Clases'),
            ),
            const SizedBox(height: 10),
            isLoading
                ? const CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: classes.length,
                      itemBuilder: (context, index) {
                        final classItem = classes[index];
                        return Card(
                          elevation: 5,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          child: ListTile(
                            title: Text(
                              classItem['nombre'] ?? 'Clase sin nombre',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Fecha: ${classItem['dia'] ?? ''} | Hora: ${classItem['horaInicio'] ?? ''}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.people, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReservationsListScreen(
                                      classId: classItem['_id'],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
