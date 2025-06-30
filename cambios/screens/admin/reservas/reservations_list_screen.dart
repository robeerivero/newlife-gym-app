import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config.dart';

class ReservationsListScreen extends StatefulWidget {
  final String classId;

  const ReservationsListScreen({Key? key, required this.classId}) : super(key: key);

  @override
  _ReservationsListScreenState createState() => _ReservationsListScreenState();
}

class _ReservationsListScreenState extends State<ReservationsListScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<dynamic> users = [];
  bool isLoading = false;
  String errorMessage = '';

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
        Uri.parse('${AppConstants.baseUrl}/api/clases/usuarios/${widget.classId}'),
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
          errorMessage = json.decode(response.body)['mensaje'] ?? 'Error al obtener usuarios de la clase.';
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
    fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Participantes de la Clase'),
        backgroundColor: const Color(0xFF42A5F5),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : users.isEmpty
                ? const Center(child: Text('No hay usuarios registrados en esta clase.'))
                : ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: Icon(
                            user['asistio'] == true ? Icons.check_circle : Icons.cancel,
                            color: user['asistio'] == true ? Colors.green : Colors.red,
                          ),
                          title: Text(user['nombre'] ?? 'Sin nombre'),
                          subtitle: Text(user['correo'] ?? ''),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
