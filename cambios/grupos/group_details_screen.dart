import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GroupDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> groupData;

  const GroupDetailsScreen({Key? key, required this.groupData}) : super(key: key);

  @override
  _GroupDetailsScreenState createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  bool isLoading = false;
  String errorMessage = '';

  Future<void> removeUserFromGroup(String userId) async {
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
        Uri.parse('http://192.168.0.101:5000/api/admin/grupos/eliminarUsuario'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'idGrupo': widget.groupData['_id'],
          'idUsuario': userId,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          widget.groupData['usuarios'] = widget.groupData['usuarios']
              .where((user) => user['_id'] != userId)
              .toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario eliminado del grupo.')),
        );
      } else {
        setState(() {
          errorMessage = json.decode(response.body)['mensaje'] ?? 'Error al eliminar usuario.';
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
    final usuarios = widget.groupData['usuarios'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Grupo: ${widget.groupData['nombre']}'),
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
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: usuarios.length,
                    itemBuilder: (context, index) {
                      final user = usuarios[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text(user['nombre']),
                          subtitle: Text(user['correo']),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => removeUserFromGroup(user['_id']),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
