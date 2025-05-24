import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';
import 'avatar_selection_screen.dart'; // Importa tu selector


class AvatarWidget extends StatelessWidget {
  final String gender;
  final String skinColor;
  final String hair;
  final String clothing;
  final double size;

  const AvatarWidget({
    Key? key,
    required this.gender,
    required this.skinColor,
    required this.hair,
    required this.clothing,
    this.size = 120,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/avatar/base/${gender}_$skinColor.png',
            width: size,
            fit: BoxFit.contain,
          ),
          Image.asset(
            'assets/avatar/hair/$hair.png',
            width: size,
            fit: BoxFit.contain,
          ),
          Image.asset(
            'assets/avatar/clothing/$clothing.png',
            width: size,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}


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
  String? _name;
  int _asistencia = 0;
  List<dynamic> _logros = [];

  // AVATAR (estos son los valores actuales, inicializan por defecto)
  String gender = 'male';
  String skinColor = 'light';
  String hair = 'short_brown';
  String clothing = 'casual1';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

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
          _asistencia = data['asistencia'] ?? 0;
          _logros = data['logros'] ?? [];
          // Leer el objeto avatar del backend
          final avatar = data['avatar'] ?? {};
          gender = avatar['gender'] ?? gender;
          skinColor = avatar['skinColor'] ?? skinColor;
          hair = avatar['hair'] ?? hair;
          clothing = avatar['clothing'] ?? clothing;
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

  Future<void> _saveAvatarToBackend() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) return;
      await http.put(
        Uri.parse('${AppConstants.baseUrl}/api/avatar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'gender': gender,
          'skinColor': skinColor,
          'hair': hair,
          'clothing': clothing,
        }),
      );
    } catch (_) {}
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

  Future<void> _cerrarSesion() async {
    await _storage.delete(key: 'jwt_token');
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _showSettingsDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar avatar'),
              onTap: () async {
                Navigator.pop(ctx);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AvatarSelectionScreen(
                      initialGender: gender,
                      initialSkinColor: skinColor,
                      initialHair: hair,
                      initialClothing: clothing,
                    ),
                  ),
                );
                if (result != null && result is Map) {
                  setState(() {
                    gender = result['gender'];
                    skinColor = result['skinColor'];
                    hair = result['hair'];
                    clothing = result['clothing'];
                  });
                  await _saveAvatarToBackend();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar sesión'),
              onTap: () {
                Navigator.pop(ctx);
                _cerrarSesion();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogros() {
    if (_logros.isEmpty) {
      return const Text('¡Empieza a moverte para conseguir logros!',
          style: TextStyle(fontSize: 16, color: Colors.grey));
    }
    return Wrap(
      spacing: 12,
      children: _logros.map((logro) {
        return Chip(
          avatar: logro['icon'] != null
              ? Image.asset(logro['icon'], width: 24)
              : null,
          label: Text(logro['nombre'] ?? 'Logro'),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
            tooltip: "Configuración",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(_errorMessage!,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  AvatarWidget(
                    gender: gender,
                    skinColor: skinColor,
                    hair: hair,
                    clothing: clothing,
                    size: 140,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _name ?? 'Usuario',
                    style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _emailController.text,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 15),

                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Logros & Prendas:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18))),
                  const SizedBox(height: 8),
                  _buildLogros(),

                  const SizedBox(height: 24),
                  Form(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _currentPasswordController,
                          decoration: const InputDecoration(
                              labelText: 'Contraseña Actual'),
                          obscureText: true,
                        ),
                        TextFormField(
                          controller: _newPasswordController,
                          decoration: const InputDecoration(
                              labelText: 'Nueva Contraseña'),
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
