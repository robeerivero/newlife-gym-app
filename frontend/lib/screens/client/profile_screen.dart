import 'package:flutter/material.dart';
import '../../fluttermoji/fluttermoji.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config.dart';
import 'edit_profile_screen.dart';
import '../../fluttermoji/fluttermoji_assets/fluttermojimodel.dart';
import '../../fluttermoji/fluttermojiCustomizer.dart'; // Corrige el import según tu carpeta real

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

  Future<List<dynamic>> _fetchCatalogoPrendas() async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/usuarios/catalogo-prendas'),
      headers: { 'Authorization': 'Bearer $token' },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    }
    throw Exception('Error al cargar catálogo');
  }

  Future<Map<String, Set<int>>> _fetchPrendasDesbloqueadas() async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/usuarios/desbloqueadas'),
      headers: { 'Authorization': 'Bearer $token' },
    );
    if (response.statusCode == 200) {
      final prendas = jsonDecode(response.body) as List;
      Map<String, Set<int>> map = {};
      for (final prenda in prendas) {
        final key = prenda['key'];
        final idx = prenda['idx'];
        if (idx != null && idx is int) {
          map.putIfAbsent(key, () => <int>{}).add(idx);
        }
      }
      return map;
    }
    throw Exception('Error al cargar prendas desbloqueadas');
  }


  void _editarAvatar() async {
    // Mostramos loader mientras obtenemos prendas desbloqueadas
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    Map<String, Set<int>> prendasDesbloqueadas = {};
    try {
      prendasDesbloqueadas = await _fetchPrendasDesbloqueadas();
    } catch (e) {
      Navigator.of(context).pop(); // Cierra el loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar tus prendas desbloqueadas')),
      );
      return;
    }

    Navigator.of(context).pop(); // Cierra el loader

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FluttermojiCustomizer(
          prendasDesbloqueadasPorAtributo: prendasDesbloqueadas,
        ),
      ),
    );
    await _guardarAvatar();
    setState(() {});
  }

  void _editarPerfil() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          initialName: _name ?? "",
          initialEmail: _email ?? "",
        ),
      ),
    );
    if (result == true) {
      _fetchProfile(); // Recarga los datos si se editó el perfil
    }
  }

  void _showSettingsDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF1E88E5)),
                title: const Text('Editar perfil'),
                onTap: () {
                  Navigator.pop(ctx);
                  _editarPerfil();
                },
              ),
              ListTile(
                leading: const Icon(Icons.face, color: Color(0xFF42A5F5)),
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        title: const Text('Mi Perfil', style: TextStyle(color: Colors.white)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Center(
                child: Card(
                  elevation: 12,
                  margin: const EdgeInsets.only(top: 20, bottom: 28),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(_error!,
                                style: const TextStyle(color: Colors.red, fontSize: 16)),
                          ),
                        FluttermojiCircleAvatar(
                          backgroundColor: Colors.blue[50],
                          radius: 70,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _name ?? "",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Color(0xFF1E88E5),
                          ),
                        ),
                        Text(
                          _email ?? "",
                          style: const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.person, size: 22),
                          label: const Text("Editar perfil"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          onPressed: _editarPerfil,
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.face, size: 22),
                          label: const Text("Editar avatar"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF42A5F5),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          onPressed: _editarAvatar,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
