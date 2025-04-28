import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config.dart';
class ReservationsListScreen extends StatefulWidget {
  final String classId;

  const ReservationsListScreen({Key? key, required this.classId})
      : super(key: key);

  @override
  _ReservationsListScreenState createState() => _ReservationsListScreenState();
}

class _ReservationsListScreenState extends State<ReservationsListScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<dynamic> users = [];
  List<dynamic> allUsers = [];
  bool isLoading = false;
  String errorMessage = '';
  String? selectedUserId;

  // Método para obtener usuarios de una clase
  Future<void> fetchUsersInClass() async {
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
        Uri.parse('${AppConstants.baseUrl}/api/admin/reservas/clase/${widget.classId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          users = data;
        });
      } else {
        setState(() {
          errorMessage = json.decode(response.body)['mensaje'] ??
              'Error al obtener usuarios de la clase.';
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

  // Método para obtener todos los usuarios
  Future<void> fetchAllUsers() async {
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
        Uri.parse('${AppConstants.baseUrl}/api/admin/usuarios'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          allUsers = data;
        });
      } else {
        setState(() {
          errorMessage = json.decode(response.body)['mensaje'] ??
              'Error al obtener usuarios.';
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

  // Método para asignar un usuario a la clase
  Future<void> assignUserToClass() async {
    if (selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un usuario.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/admin/reservas/asignar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'idClase': widget.classId,
          'idUsuario': selectedUserId,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario asignado a la clase con éxito.')),
        );
        fetchUsersInClass(); // Recargar usuarios tras asignar
      } else {
        setState(() {
          errorMessage = json.decode(response.body)['mensaje'] ??
              'Error al asignar el usuario a la clase.';
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

  // Método para eliminar un usuario de la clase
  Future<void> removeUserFromClass(String userId) async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/api/admin/reservas/clase/${widget.classId}/usuario/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario eliminado de la clase.')),
        );
        fetchUsersInClass(); // Recargar usuarios tras eliminar
      } else {
        setState(() {
          errorMessage = 'Error al eliminar al usuario de la clase.';
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

  @override
  void initState() {
    super.initState();
    fetchUsersInClass(); // Cargar usuarios al iniciar
    fetchAllUsers(); // Cargar todos los usuarios al iniciar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios en la Clase'),
        backgroundColor: Colors.deepOrangeAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Asignar Usuario a la Clase'),
                content: DropdownButtonFormField<String>(
                  value: selectedUserId,
                  items: allUsers.map<DropdownMenuItem<String>>((user) {
                    return DropdownMenuItem<String>(
                      value: user['_id'],
                      child: Text(user['nombre']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedUserId = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Seleccionar Usuario',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      assignUserToClass();
                    },
                    child: const Text('Asignar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? const Center(
                  child: Text('No hay usuarios en esta clase.'),
                )
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final nombre = user['nombre'] ?? 'Usuario sin nombre';
                    final correo = user['correo'] ?? 'Correo no disponible';
                    return Card(
                      elevation: 5,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text(nombre),
                        subtitle: Text(correo),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => removeUserFromClass(user['_id']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
