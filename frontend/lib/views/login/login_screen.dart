import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui'; // Para ImageFilter
import 'package:google_fonts/google_fonts.dart';
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
    // 1. Capturamos el tema actual
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;

    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: Consumer<LoginViewModel>(
        builder: (context, vm, child) {
          // Navegación automática si login correcto (Lógica intacta)
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
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      // CAMBIO: Gradiente basado en el color Primario (Teal)
                      colors: [
                        primaryColor.withOpacity(0.6), // Teal más claro arriba
                        primaryColor,                  // Teal original abajo
                      ],
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
                            'assets/images/NewLifeLogo2026.png',
                            height: 200.h,
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
                              ],
                            ),
                          ),
                          SizedBox(height: 30.h),

                          // 3. El Formulario
                          _buildGlassForm(context, vm, primaryColor, secondaryColor),
                          
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
  Widget _buildGlassForm(BuildContext context, LoginViewModel vm, Color primary, Color secondary) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85), // Un poco más opaco para legibilidad
            borderRadius: BorderRadius.circular(18),
            // CAMBIO: Borde color Primario (Teal)
            border: Border.all(color: primary.withOpacity(0.5), width: 2),
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
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    labelStyle: GoogleFonts.poppins(),
                    // CAMBIO: Icono color Secundario (Naranja)
                    prefixIcon: Icon(Icons.email_outlined, color: secondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: primary, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
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
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: GoogleFonts.poppins(),
                    // CAMBIO: Icono color Secundario
                    prefixIcon: Icon(Icons.lock_outline, color: secondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: primary, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
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
                  CircularProgressIndicator(color: secondary)
                else
                  ElevatedButton(
                    onPressed: () => _handleLogin(vm),
                    style: ElevatedButton.styleFrom(
                      // CAMBIO: Botón color Secundario (Naranja) para llamar a la acción
                      backgroundColor: secondary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      'Iniciar Sesión',
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (vm.errorMessage != null) ...[
                  SizedBox(height: 10.h),
                  Text(
                    vm.errorMessage!,
                    style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w500),
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