import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _name; // Nombre del usuario

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  // Obtener datos del perfil
  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        setState(() {
          _errorMessage = 'No se encontró el token. Por favor, inicia sesión nuevamente.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/usuarios/perfil'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _name = data['nombre'] ?? 'Usuario';
          _emailController.text = data['correo'] ?? '';
        });
      } else {
        setState(() {
          _errorMessage = 'Error al obtener el perfil.';
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

  // Cambiar contraseña
  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty || _newPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, completa todos los campos.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
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
        Uri.parse('${AppConstants.baseUrl}/api/usuarios/perfil/contrasena'),
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
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (_errorMessage != null)
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  Form(
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: _name,
                          decoration: const InputDecoration(labelText: 'Nombre'),
                          readOnly: true, // Campo no editable
                        ),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Correo electrónico'),
                          readOnly: true,
                        ),                              
                        TextFormField(
                          controller: _currentPasswordController,
                          decoration: const InputDecoration(labelText: 'Contraseña Actual'),
                          obscureText: true,
                        ),
                        TextFormField(
                          controller: _newPasswordController,
                          decoration: const InputDecoration(labelText: 'Nueva Contraseña'),
                          obscureText: true,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _changePassword,
                          child: const Text('Cambiar Contraseña'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}