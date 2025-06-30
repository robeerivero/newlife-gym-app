import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';

class EjerciciosManagementScreen extends StatefulWidget {
  @override
  _EjerciciosManagementScreenState createState() => _EjerciciosManagementScreenState();
}

class _EjerciciosManagementScreenState extends State<EjerciciosManagementScreen> {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  List<dynamic> ejercicios = [];
  bool isLoading = false;
  String errorMessage = '';

  // Variables para los campos de los diálogos de agregar y editar
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _videoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  String _dificultad = 'fácil';

  // Obtener la lista de ejercicios
  Future<void> fetchEjercicios() async {
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
        Uri.parse('${AppConstants.baseUrl}/api/ejercicios'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List<dynamic>) {
          setState(() {
            ejercicios = data;
          });
        } else {
          setState(() {
            errorMessage = 'Formato inesperado de la respuesta del servidor.';
          });
        }
      } else {
        setState(() {
          errorMessage = json.decode(response.body)['mensaje'] ?? 'Error al obtener los ejercicios.';
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

  // Método para agregar un ejercicio
  Future<void> addEjercicio() async {
    final nombre = _nombreController.text;
    final video = _videoController.text;
    final descripcion = _descripcionController.text;

    if (nombre.isEmpty || video.isEmpty || _dificultad.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos los campos son obligatorios.')),
      );
      return;
    }

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

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/ejercicios'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'nombre': nombre,
          'video': video,
          'descripcion': descripcion,
          'dificultad': _dificultad,
        }),
      );

      if (response.statusCode == 201) {
        fetchEjercicios();
        Navigator.pop(context); // Cierra el diálogo de agregar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ejercicio agregado correctamente.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al agregar el ejercicio.')),
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

  // Método para editar un ejercicio
  Future<void> editEjercicio(String ejercicioId) async {
    final nombre = _nombreController.text;
    final video = _videoController.text;
    final descripcion = _descripcionController.text;

    if (nombre.isEmpty || video.isEmpty || _dificultad.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos los campos son obligatorios.')),
      );
      return;
    }

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

      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/api/ejercicios/$ejercicioId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'nombre': nombre,
          'video': video,
          'descripcion': descripcion,
          'dificultad': _dificultad,
        }),
      );

      if (response.statusCode == 200) {
        fetchEjercicios();
        Navigator.pop(context); // Cierra el diálogo de editar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ejercicio editado correctamente.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al editar el ejercicio.')),
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

  // Método para eliminar un ejercicio
  Future<void> deleteEjercicio(String ejercicioId) async {
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
        Uri.parse('${AppConstants.baseUrl}/api/ejercicios/$ejercicioId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        fetchEjercicios(); // Actualizar la lista de ejercicios
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ejercicio eliminado correctamente.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar el ejercicio.')),
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
    fetchEjercicios(); // Obtener ejercicios al iniciar la pantalla
  }

  // Diálogo para agregar un ejercicio
  void showAddEjercicioDialog() {
    _nombreController.clear();
    _videoController.clear();
    _descripcionController.clear();
    _dificultad = 'fácil';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Agregar Ejercicio'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: _videoController,
                  decoration: const InputDecoration(labelText: 'Video URL'),
                ),
                TextField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                DropdownButton<String>(
                  value: _dificultad,
                  items: ['fácil', 'medio', 'difícil']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _dificultad = newValue!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('Agregar'),
              onPressed: () {
                addEjercicio();
              },
            ),
          ],
        );
      },
    );
  }

  // Diálogo para editar un ejercicio
  void showEditEjercicioDialog(String ejercicioId) {
    final ejercicio = ejercicios.firstWhere((e) => e['_id'] == ejercicioId);
    _nombreController.text = ejercicio['nombre'];
    _videoController.text = ejercicio['video'];
    _descripcionController.text = ejercicio['descripcion'];
    _dificultad = ejercicio['dificultad'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Ejercicio'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: _videoController,
                  decoration: const InputDecoration(labelText: 'Video URL'),
                ),
                TextField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                DropdownButton<String>(
                  value: _dificultad,
                  items: ['fácil', 'medio', 'difícil']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _dificultad = newValue!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('Guardar'),
              onPressed: () {
                editEjercicio(ejercicioId);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Ejercicios'),
        backgroundColor: Colors.blueAccent,
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
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: ejercicios.length,
                    itemBuilder: (context, index) {
                      final ejercicio = ejercicios[index];
                      return Card(
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text(
                            ejercicio['nombre'] ?? 'Nombre no disponible',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dificultad: ${ejercicio['dificultad'] ?? 'No especificada'}'),
                              Text('Video: ${ejercicio['video'] ?? 'No disponible'}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.green),
                                onPressed: () {
                                  showEditEjercicioDialog(ejercicio['_id']);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => deleteEjercicio(ejercicio['_id']),
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
                    onPressed: showAddEjercicioDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Agregar Ejercicio',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
