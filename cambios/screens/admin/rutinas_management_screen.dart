import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'rutinas/add_rutina_screen.dart'; // Pantalla para agregar una rutina
import 'rutinas/edit_rutina_screen.dart'; // Pantalla para editar una rutina
import 'ejercicio_screen.dart'; // Pantalla de gestión de ejercicios
import '../../config.dart';
class RutinasManagementScreen extends StatefulWidget {
  const RutinasManagementScreen({Key? key}) : super(key: key);

  @override
  State<RutinasManagementScreen> createState() => _RutinasManagementScreenState();
}

class _RutinasManagementScreenState extends State<RutinasManagementScreen> {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  List<dynamic> rutinas = [];
  bool isLoading = false;
  String errorMessage = '';

  // Obtener todas las rutinas
  Future<void> fetchRutinas() async {
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

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/rutinas'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          rutinas = data;
        });
      } else {
        setState(() {
          errorMessage = json.decode(response.body)['mensaje'] ?? 'Error al obtener las rutinas.';
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

  // Eliminar una rutina por ID
  Future<void> deleteRutina(String rutinaId) async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        setState(() {
          errorMessage = 'Token no encontrado. Por favor, inicia sesión nuevamente.';
        });
        return;
      }

      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/api/rutinas/$rutinaId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        fetchRutinas();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rutina eliminada correctamente.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar la rutina.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión. Por favor, intenta nuevamente.')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRutinas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Rutinas'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.fitness_center),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EjerciciosManagementScreen()),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: rutinas.length,
                    itemBuilder: (context, index) {
                      final rutina = rutinas[index];
                      final usuarioNombre = rutina['usuario']?['nombre'] ?? 'Usuario no especificado';
                      final ejercicios = rutina['ejercicios'] ?? [];

                      return Card(
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text(
                            rutina['diaSemana'] ?? 'Día no especificado',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Usuario: $usuarioNombre'),
                              const SizedBox(height: 5),
                              const Text('Ejercicios:'),
                              ...List<Widget>.generate(
                                ejercicios.length,
                                (i) => Text(ejercicios[i]['ejercicio']['nombre'] ?? 'No disponible'),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.green),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditRutinaScreen(rutinaId: rutina['_id']),
                                    ),
                                  ).then((_) => fetchRutinas());
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => deleteRutina(rutina['_id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddRutinaScreen()),
                      ).then((_) => fetchRutinas());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Agregar Rutina',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
