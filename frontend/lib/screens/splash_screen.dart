// screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import 'login_screen.dart';
import 'admin_screen.dart';
import 'client_screen.dart';
import 'online_client_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await _storage.read(key: 'jwt_token');
    final refreshToken = await _storage.read(key: 'refresh_token');

    if (token != null) {
        try {
        // Verificar token
        final response = await http.get(
            Uri.parse('${AppConstants.baseUrl}/api/auth/verificar-token'),
            headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
            final data = json.decode(response.body);
            await _storage.write(key: 'jwt_token', value: data['accessToken']);
            _redirectByRole(data['usuario']['rol']);
        }
        } catch (e) {
        if (refreshToken != null) {
            // Intentar renovar con refresh token
            final newTokens = await _renovarToken(refreshToken);
            if (newTokens != null) {
            await _storage.write(key: 'jwt_token', value: newTokens['accessToken']);
            await _storage.write(key: 'refresh_token', value: newTokens['refreshToken']);
            _redirectByRole(newTokens['usuario']['rol']);
            return;
            }
        }
        _redirectToLogin();
        }
    } else {
        _redirectToLogin();
    }
    }

    Future<Map<String, dynamic>?> _renovarToken(String refreshToken) async {
    try {
        final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/auth/token/renovar'),
        body: json.encode({'refreshToken': refreshToken}),
        headers: {'Content-Type': 'application/json'},
        );
        
        if (response.statusCode == 200) {
        return json.decode(response.body);
        }
    } catch (e) {
        print('Error renovando token: $e');
    }
    return null;
}

  void _redirectByRole(String role) {
    switch (role) {
      case 'admin':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminScreen()));
        break;
      case 'online':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => OnlineClientScreen()));
        break;
      default:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ClientScreen()));
    }
  }

  void _redirectToLogin() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(
                height: 200,
                width: double.infinity,
                child: Image.asset(
                  'assets/images/fondo_login.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF90CAF9),
                        Color(0xFF42A5F5),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/NewLifeLogo.png',
                        height: 200,
                      ),
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      const Text(
                        'Iniciando sesión...',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}