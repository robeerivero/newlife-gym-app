import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';
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
  bool _showForm = false;
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
                return Column(
                  children: [
                    // Header Image
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 600) {
                          return const SizedBox.shrink();
                        } else {
                          return SizedBox(
                            height: 200.h,
                            width: double.infinity,
                            child: Image.asset(
                              'assets/images/fondo_login.jpg',
                              fit: BoxFit.cover,
                            ),
                          );
                        }
                      },
                    ),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF90CAF9), Color(0xFF42A5F5)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                            child: Column(
                              children: [
                                Image.asset(
                                  'assets/images/NewLifeLogo.png',
                                  height: 300.h,
                                  width: 300.w,
                                  fit: BoxFit.contain,
                                ),
                                SizedBox(height: 10.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ChatBotScreen(section: 'Pilates'),
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
                                          builder: (context) => const ChatBotScreen(section: 'Funcional'),
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
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  child: _showForm
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(18),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                            child: Container(
                                              margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
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
                                              padding: const EdgeInsets.all(16.0),
                                              child: Form(
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
                                                        } else if (!RegExp(r"^[\w.-]+@[\w-]+\.[a-zA-Z]{2,}").hasMatch(value)) {
                                                          return 'Formato de correo no válido';
                                                        }
                                                        return null;
                                                      },
                                                    ),
                                                    SizedBox(height: 20.h),
                                                    TextFormField(
                                                      controller: _passwordController,
                                                      obscureText: _obscurePassword,
                                                      decoration: InputDecoration(
                                                        labelText: 'Contraseña',
                                                        border: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(10.0),
                                                        ),
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
                                                    SizedBox(height: 10.h),
                                                    if (vm.isLoading)
                                                      const CircularProgressIndicator()
                                                    else
                                                      ElevatedButton(
                                                        onPressed: () => _handleLogin(vm),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: const Color(0xFF42A5F5),
                                                          foregroundColor: Colors.white,
                                                          padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 10.h),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(10.0),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          'Iniciar Sesión',
                                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                        ),
                                                      ),
                                                    if (vm.errorMessage != null) ...[
                                                      SizedBox(height: 10.h),
                                                      Text(
                                                        vm.errorMessage!,
                                                        style: const TextStyle(color: Colors.red),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
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
        },
      ),
    );
  }
}
