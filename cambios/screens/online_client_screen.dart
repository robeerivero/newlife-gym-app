import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'client/rutinas_screen.dart';
import 'client/diet_screen.dart';
import 'client/video_screen.dart';
import 'client/profile_screen.dart';
import 'client/salud_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_screen.dart';
import '../config.dart';

class OnlineClientScreen extends StatefulWidget {
  const OnlineClientScreen({super.key});

  @override
  State<OnlineClientScreen> createState() => _OnlineClientScreenState();
}

class _OnlineClientScreenState extends State<OnlineClientScreen> {
  int _selectedIndex = 0;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _userName;
  bool _isLoading = false;
  String? _errorMessage;

  // Cerrar sesión
  Future<void> _logout(BuildContext context) async {
    await _storage.delete(key: 'jwt_token');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
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
    _fetchProfile();
  }

  final List<Widget> _screens = [
    const RutinasScreen(),    // 0 - Rutinas
    const DietScreen(),       // 1 - Dietas
    const VideoScreen(),      // 2 - Videos
    const ProfileScreen(),    // 3 - Perfil
    const SaludScreen(),      // 4 - Salud
  ];
  final List<String> _titles = [
    'Mis Rutinas',
    'Mis Dietas',
    'Videos',
    'Mi Perfil',
    'Mi Salud',
  ];

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
            label: 'Rutinas',
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
