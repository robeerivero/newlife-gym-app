// screens/client/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';

class EditProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;

  const EditProfileScreen({
    Key? key,
    required this.initialName,
    required this.initialEmail,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final token = await _storage.read(key: 'jwt_token');
    // Cambiar nombre/correo
    await http.put(
      Uri.parse('${AppConstants.baseUrl}/api/usuarios/perfil'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nombre': _nameController.text,
        'correo': _emailController.text,
      }),
    );
    // Cambiar contraseña si la rellena
    if (_currentPasswordController.text.isNotEmpty &&
        _newPasswordController.text.isNotEmpty) {
      await http.put(
        Uri.parse('${AppConstants.baseUrl}/api/usuarios/perfil/contrasena'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contrasenaActual': _currentPasswordController.text,
          'nuevaContrasena': _newPasswordController.text,
        }),
      );
    }

    setState(() { _loading = false; });
    if (mounted) Navigator.of(context).pop(true); // Devuelve true si todo ok
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Perfil")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correo'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 16),
              const Text("Cambiar Contraseña",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _currentPasswordController,
                decoration: const InputDecoration(labelText: 'Contraseña actual'),
                obscureText: true,
              ),
              TextFormField(
                controller: _newPasswordController,
                decoration: const InputDecoration(labelText: 'Nueva contraseña'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text("Guardar cambios"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
