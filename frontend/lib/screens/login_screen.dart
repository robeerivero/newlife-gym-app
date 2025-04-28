import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
import 'chatbot_screen.dart';
import '../config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _storage = FlutterSecureStorage();

  bool _isLoading = false;
  String? _errorMessage;
  bool _showForm = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'correo': _emailController.text,
          'contrasena': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['accessToken'];

        if (token != null && token.isNotEmpty) {
          await _storage.write(key: 'jwt_token', value: token);
          final role = data['usuario']['rol'];
          if (role == 'admin') {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/admin');
            }
          } else if (role == 'online') {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/online');
            }
          }else {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/client');
            }
          }
        } else {
          setState(() {
            _errorMessage = 'Token vacío recibido';
          });
        }
      } else {
        final data = json.decode(response.body);
        setState(() {
          _errorMessage = data['mensaje'] ?? 'Error desconocido';
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Error al conectar con el servidor';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenUtilInit(
        designSize: const Size(360, 690), // Tamaño base para escalar
        builder: (context, child) {
          return Column(
            children: [
              // Imagen de cabecera
              SizedBox(
                height: 200.h, // Altura fija
                width: double.infinity,
                child: Image.asset(
                  'assets/images/fondo_login.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              // Fondo celeste y contenido principal
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF90CAF9), // Celeste más claro
                        Color(0xFF42A5F5), // Celeste más oscuro
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                      child: Column(
                        children: [
                          // Logo centrado
                          Image.asset(
                            'assets/images/NewLifeLogo.png',
                            height: 300.h,
                            width: 300.w,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(height: 10.h),
                          // Iconos interactivos
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatBotScreen(section: 'Pilates'),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Image.asset(
                                      'assets/icons/icon_pilates.png',
                                      height: 60.h,
                                      width: 60.w,
                                    ),
                                    SizedBox(height: 5.h),
                                    const Text('Pilates', style: TextStyle(fontSize: 16)),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showForm = true;
                                  });
                                },
                                child: Column(
                                  children: [
                                    Image.asset(
                                      'assets/icons/icon_login.png',
                                      height: 60.h,
                                      width: 60.w,
                                    ),
                                    SizedBox(height: 5.h),
                                    const Text('Iniciar Sesión', style: TextStyle(fontSize: 16)),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatBotScreen(section: 'Funcional'),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Image.asset(
                                      'assets/icons/icon_funcional.png',
                                      height: 60.h,
                                      width: 60.w,
                                    ),
                                    SizedBox(height: 5.h),
                                    const Text('Funcional', style: TextStyle(fontSize: 16)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_showForm) ...[
                            SizedBox(height: 20.h),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      labelText: 'Correo electrónico',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10.0),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, ingresa tu correo electrónico';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 20.h),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      labelText: 'Contraseña',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10.0),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, ingresa tu contraseña';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 30.h),
                                  if (_isLoading)
                                    const CircularProgressIndicator()
                                  else
                                    ElevatedButton(
                                      onPressed: _login,
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(horizontal: 100.w, vertical: 15.h),
                                      ),
                                      child: const Text('Iniciar Sesión'),
                                    ),
                                  if (_errorMessage != null) ...[
                                    SizedBox(height: 10.h),
                                    Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}