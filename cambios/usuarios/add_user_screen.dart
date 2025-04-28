import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../../../config.dart';
class AddUserScreen extends StatefulWidget {
  const AddUserScreen({Key? key}) : super(key: key); // Constructor con parámetro `Key`

  @override
  _AddUserScreenState createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? selectedRole;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final List<String> _classTypes = ['funcional', 'pilates', 'zumba'];
  final List<String> _roles = ['admin', 'cliente', 'online'];

  List<String> selectedClassTypes = []; // Almacena los tipos de clases seleccionados
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _addUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Token no encontrado. Por favor, inicia sesión nuevamente.';
        });
        return;
      }
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/admin/usuarios'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'nombre': _nameController.text,
          'correo': _emailController.text,
          'contrasena': _passwordController.text,
          'rol': selectedRole,
          'tiposDeClases': selectedClassTypes, // Enviar lista de tipos de clases seleccionados
        }),
      );

      if (response.statusCode == 201) {
        Navigator.pop(context); // Regresar a la pantalla anterior
      } else {
        final data = json.decode(response.body);
        setState(() {
          _errorMessage = data['mensaje'] ?? 'Error desconocido';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Usuario')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            // Selección múltiple de tipos de clase
            Wrap(
              spacing: 10,
              children: _classTypes.map((type) {
                final isSelected = selectedClassTypes.contains(type);
                return FilterChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        selectedClassTypes.add(type);
                      } else {
                        selectedClassTypes.remove(type);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Selección de rol
            DropdownButtonFormField<String>(
              value: selectedRole,
              items: _roles.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedRole = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Seleccionar Rol'),
            ),

            const SizedBox(height: 20),

            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _addUser,
                    child: const Text('Agregar Usuario'),
                  ),
          ],
        ),
      ),
    );
  }
}
