import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'grupos/add_group_screen.dart'; // Pantalla para agregar grupos
import 'grupos/edit_group_screen.dart'; // Pantalla para editar grupos
import 'grupos/add_user_to_group_screen.dart';
import 'grupos/group_details_screen.dart';

class GroupManagementScreen extends StatefulWidget {
  @override
  _GroupManagementScreenState createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  List<dynamic> groups = [];
  bool isLoading = false;
  String errorMessage = '';

  // Método para obtener todos los grupos
  Future<void> fetchGroups() async {
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
        Uri.parse('http://192.168.0.104:5000/api/admin/grupos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List<dynamic>) {
          setState(() {
            groups = data;
          });
        } else {
          setState(() {
            errorMessage = 'Formato inesperado de la respuesta del servidor.';
          });
        }
      } else {
        setState(() {
          errorMessage = json.decode(response.body)['mensaje'] ?? 'Error al obtener los grupos.';
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

  // Método para eliminar un grupo
  Future<void> deleteGroup(String groupId) async {
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
        Uri.parse('http://192.168.0.104:5000/api/admin/grupos/$groupId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        fetchGroups();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grupo eliminado correctamente.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar el grupo.')),
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

  Future<void> fetchGroupDetails(String groupId) async {
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
      Uri.parse('http://192.168.0.104:5000/api/admin/grupos/$groupId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final group = json.decode(response.body);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupDetailsScreen(groupData: group),
        ),
      );
    } else {
      setState(() {
        errorMessage = json.decode(response.body)['mensaje'] ?? 'Error al obtener el grupo.';
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
    fetchGroups(); // Obtener grupos al iniciar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Grupos'),
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
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      return Card(
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text(
                            group['nombre'] ?? 'Grupo sin nombre',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(group['descripcion'] ?? 'Sin descripción'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.group_add, color: Colors.blue),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddUserToGroupScreen(groupId: group['_id']),
                                    ),
                                  ).then((_) => fetchGroups());
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.green),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditGroupScreen(groupData: group),
                                    ),
                                  ).then((_) => fetchGroups());
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => deleteGroup(group['_id']),
                              ),
                            ],
                          ),
                          onTap: () => fetchGroupDetails(group['_id']), 
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
                        MaterialPageRoute(builder: (context) => const AddGroupScreen()),
                      ).then((_) => fetchGroups());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrangeAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Agregar Grupo',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
