import 'package:flutter/material.dart';
import 'package:fluttermoji/fluttermoji.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _name;
  String? _email;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await _storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/usuarios/perfil'),
        headers: { 'Authorization': 'Bearer $token' },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final avatarJson = data['avatar'];
        _name = data['nombre'] ?? "Usuario";
        _email = data['correo'] ?? "";
        if (avatarJson != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('fluttermojiSelectedOptions', avatarJson);
        }
      } else {
        _error = 'Error al obtener el perfil';
      }
    } catch (e) {
      _error = "Error de conexión";
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _guardarAvatar() async {
    final token = await _storage.read(key: 'jwt_token');
    final avatarJson = await FluttermojiFunctions().encodeMySVGtoString();
    await http.put(
      Uri.parse('${AppConstants.baseUrl}/api/usuarios/avatar'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'avatar': avatarJson}),
    );
  }

  void _editarAvatar() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FluttermojiCustomizer()),
    );
    await _guardarAvatar();
    setState(() {});
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
              onTap: () {
                Navigator.pop(ctx);
                _editarAvatar();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar sesión'),
              onTap: () async {
                Navigator.pop(ctx);
                await _storage.delete(key: 'jwt_token');
                if (mounted) Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        );
      },
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
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  FluttermojiCircleAvatar(
                    backgroundColor: Colors.blue[50],
                    radius: 70,
                  ),
                  const SizedBox(height: 20),
                  Text(_name ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                  Text(_email ?? "", style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text("Editar avatar"),
                    onPressed: _editarAvatar,
                  ),
                ],
              ),
            ),
    );
  }
}
