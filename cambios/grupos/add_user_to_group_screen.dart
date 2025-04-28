import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddUserToGroupScreen extends StatefulWidget {
  final String groupId;

  const AddUserToGroupScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  _AddUserToGroupScreenState createState() => _AddUserToGroupScreenState();
}

class _AddUserToGroupScreenState extends State<AddUserToGroupScreen> {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  List<dynamic> users = [];
  String? selectedUserId;
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchUsers(); // Cargar lista de usuarios al inicio
  }

  Future<void> fetchUsers() async {
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
        Uri.parse('http://192.168.0.101:5000/api/admin/usuarios'), // Endpoint para obtener usuarios
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List<dynamic>) {
          setState(() {
            users = data;
          });
        } else {
          setState(() {
            errorMessage = 'Formato inesperado de la respuesta del servidor.';
          });
        }
      } else {
        setState(() {
          errorMessage = json.decode(response.body)['mensaje'] ?? 'Error al obtener usuarios.';
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

  Future<void> addUserToGroup() async {
    if (selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un usuario.')),
      );
      return;
    }

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

      final response = await http.post(
        Uri.parse('http://192.168.0.101:5000/api/admin/grupos/anadirUsuario'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'idGrupo': widget.groupId,
          'idUsuario': selectedUserId,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario añadido al grupo exitosamente.')),
        );
      } else {
        setState(() {
          errorMessage = json.decode(response.body)['mensaje'] ?? 'Error al añadir usuario al grupo.';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Usuario al Grupo'),
        backgroundColor: Colors.deepOrangeAccent,
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
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return RadioListTile<String>(
                        title: Text(user['nombre']),
                        subtitle: Text(user['correo']),
                        value: user['_id'],
                        groupValue: selectedUserId,
                        onChanged: (value) {
                          setState(() {
                            selectedUserId = value;
                          });
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ElevatedButton(
                    onPressed: addUserToGroup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrangeAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Añadir Usuario',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
