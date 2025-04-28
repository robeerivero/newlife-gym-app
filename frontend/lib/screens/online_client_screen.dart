import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'client/rutinas_screen.dart';
import 'client/diet_screen.dart';
import 'client/profile_screen.dart';
import 'client/salud_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_screen.dart';
import '../config.dart';

class OnlineClientScreen extends StatefulWidget {
  const OnlineClientScreen({super.key}); // Usa super.key para evitar advertencias
  
  @override
  OnlineClientScreenState createState() => OnlineClientScreenState();
}

class OnlineClientScreenState extends State<OnlineClientScreen> {
  int _selectedIndex = 0;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _userName;
  bool _isLoading = false;
  String? _errorMessage;

  // Método para cerrar sesión
  Future<void> _logout(BuildContext context) async {
    await _storage.delete(key: 'jwt_token'); // Eliminar el token de sesión
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()), // Redirigir al login
    );
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
          _userName = data['nombre'] ?? 'Usuario';
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

  @override
  void initState() {
    super.initState();
    _fetchProfile(); // Carga el perfil al iniciar
  }

  final List<Widget> _screens = [
    const RutinasScreen(),
    const DietScreen(),
    const ProfileScreen(),
    const SaludScreen(),
  ];
  final List<String> titulos = [
    'Mis Rutinas',
    'Mis Dietas',
    'Mi Perfil',
    'Mi Salud',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Cierra el Drawer al seleccionar una opción
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        title: Text(
          titulos[_selectedIndex], 
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            color: Color.fromARGB(255, 250, 250, 250),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: const Color(0xFF1E88E5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.person, size: 60, color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    'Bienvenido, ${_userName ?? 'Usuario'}',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text('Rutinas'),
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              leading: const Icon(Icons.restaurant),
              title: const Text('Dietas'),
              onTap: () => _onItemTapped(1),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: () => _onItemTapped(2),
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Salud'),
              onTap: () => _onItemTapped(3),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _screens[_selectedIndex],
    );
  }
}
