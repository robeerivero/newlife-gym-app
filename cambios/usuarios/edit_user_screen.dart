import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../config.dart';
class EditUserScreen extends StatefulWidget {
  final Map<String, dynamic> user; // Recibe el usuario a editar

  const EditUserScreen({Key? key, required this.user}) : super(key: key);

  @override
  _EditUserScreenState createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? selectedRole;
  List<String> selectedClassTypes = [];

  final List<String> _roles = ['admin', 'cliente'];
  final List<String> _classTypes = ['funcional', 'pilates', 'zumba'];

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user['nombre'] ?? '';
    _emailController.text = widget.user['correo'] ?? '';
    selectedRole = widget.user['rol'];
    selectedClassTypes = List<String>.from(widget.user['tiposDeClases'] ?? []);
  }

  Future<void> _updateUser() async {
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

      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/api/admin/usuarios/${widget.user['_id']}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'nombre': _nameController.text,
          'correo': _emailController.text,
          'rol': selectedRole,
          'tiposDeClases': selectedClassTypes,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario actualizado con éxito.')),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = 'Error al actualizar el usuario.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty || _newPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, completa todos los campos.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        setState(() {
          _errorMessage = 'No se encontró el token. Por favor, inicia sesión nuevamente.';
        });
        return;
      }

      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/api/admin/usuarios/${widget.user['_id']}/cambiar-contrasena'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'contrasenaActual': _currentPasswordController.text,
          'nuevaContrasena': _newPasswordController.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña cambiada exitosamente.')),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
      } else {
        setState(() {
          _errorMessage = 'Error al cambiar la contraseña.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión.';
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
      appBar: AppBar(title: const Text('Editar Usuario')),
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
              decoration: const InputDecoration(labelText: 'Rol'),
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

            // Campo para contraseña actual y nueva contraseña
            TextField(
              controller: _currentPasswordController,
              decoration: const InputDecoration(labelText: 'Contraseña Actual'),
              obscureText: true,
            ),
            TextField(
              controller: _newPasswordController,
              decoration: const InputDecoration(labelText: 'Nueva Contraseña'),
              obscureText: true,
            ),

            const SizedBox(height: 20),

            _isLoading
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: _updateUser,
                        child: const Text('Guardar Cambios'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _changePassword,
                        child: const Text('Cambiar Contraseña'),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
