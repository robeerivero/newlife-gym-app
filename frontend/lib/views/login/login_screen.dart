import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui'; // Para ImageFilter
import 'package:google_fonts/google_fonts.dart'; // <-- IMPORTANTE
import '../../viewmodels/login_viewmodel.dart';
import '../chatbot/chatbot_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  // bool _showForm = false; // <-- Eliminado, el formulario siempre se muestra
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin(LoginViewModel vm) {
    if (_formKey.currentState!.validate()) {
      vm.login(_emailController.text, _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: Consumer<LoginViewModel>(
        builder: (context, vm, child) {
          // Navegación automática si login correcto
          if (vm.loginSuccess && vm.role != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              switch (vm.role) {
                case 'admin':
                  Navigator.pushReplacementNamed(context, '/admin');
                  break;
                case 'online':
                  Navigator.pushReplacementNamed(context, '/online');
                  break;
                default:
                  Navigator.pushReplacementNamed(context, '/client');
              }
            });
          }

          return Scaffold(
            body: ScreenUtilInit(
              designSize: const Size(360, 690),
              builder: (context, child) {
                // El contenedor con gradiente ahora es el fondo principal
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF90CAF9), Color(0xFF42A5F5)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 50.h),
                          // 1. El Logo
                          Image.asset(
                            'assets/images/NewLifeLogo.png',
                            height: 200.h, // Ajusta el tamaño si es necesario
                            width: 200.w,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(height: 10.h),

                          // 2. Título Principal
                          Text(
                            'Inicia Sesión',
                            style: GoogleFonts.poppins(
                              fontSize: 26.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(2, 2),
                                )
                              ]
                            ),
                          ),
                          SizedBox(height: 30.h),

                          // 3. El Formulario (efecto "glass")
                          _buildGlassForm(context, vm),
                          
                          SizedBox(height: 20.h),

                          // 4. Enlaces al ChatBot
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildInfoButton(context, 'Info Pilates', 'Pilates'),
                              _buildInfoButton(context, 'Info Funcional', 'Funcional'),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Widget para el formulario con efecto "glass"
  Widget _buildGlassForm(BuildContext context, LoginViewModel vm) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.77),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF42A5F5), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _emailController,
                  style: GoogleFonts.poppins(), // Fuente aplicada
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    labelStyle: GoogleFonts.poppins(), // Fuente aplicada
                    prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF42A5F5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa tu correo';
                    } else if (!RegExp(r"^[\w.-]+@[\w-]+\.[a-zA-Z]{2,}")
                        .hasMatch(value)) {
                      return 'Formato de correo no válido';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20.h),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: GoogleFonts.poppins(), // Fuente aplicada
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: GoogleFonts.poppins(), // Fuente aplicada
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF42A5F5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() {
                        _obscurePassword = !_obscurePassword;
                      }),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa tu contraseña';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20.h),
                if (vm.isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: () => _handleLogin(vm),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF42A5F5),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      'Iniciar Sesión',
                      style: GoogleFonts.poppins( // Fuente aplicada
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (vm.errorMessage != null) ...[
                  SizedBox(height: 10.h),
                  Text(
                    vm.errorMessage!,
                    style: GoogleFonts.poppins(color: Colors.red[700], fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper para los botones de info (ChatBot)
  Widget _buildInfoButton(BuildContext context, String text, String section) {
    return TextButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChatBotScreen(section: section)),
      ),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white,
        ),
      ),
    );
  }
}