import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'client/class_screen.dart';
import 'client/diet_screen.dart';
import 'client/video_screen.dart';
import 'client/profile_screen.dart';
import 'client/salud_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_screen.dart';
import '../config.dart';

class ClientScreen extends StatefulWidget {
  const ClientScreen({super.key}); // Usa super.key para evitar advertencias
  
  @override
  ClientScreenState createState() => ClientScreenState();
}

class ClientScreenState extends State<ClientScreen> {
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
    const ClassScreen(),
    const DietScreen(),
    const VideoScreen(),
    const ProfileScreen(),
    const SaludScreen(),
  ];
  final List<String> titulos = [
    'Mis Clases',
    'Mis Dietas',
    'Videos',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Clases',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Dietas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Videos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Salud',
          ),
        ],
      ),
    );
  }

}
