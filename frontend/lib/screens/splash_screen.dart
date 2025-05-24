import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final _storage = FlutterSecureStorage();
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _checkAuth();
  }

  void _setupAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  Future<void> _checkAuth() async {
    final token = await _storage.read(key: 'jwt_token');
    await Future.delayed(const Duration(seconds: 2));

    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('${AppConstants.baseUrl}/api/auth/verificar-token'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          await _storage.write(key: 'jwt_token', value: data['accessToken']);
          _redirectByRole(data['usuario']['rol']);
        } else {
          _handleAuthError();
        }
      } catch (e) {
        _handleAuthError();
      }
    } else {
      _redirectToLogin();
    }
  }

  void _handleAuthError() {
    setState(() => _hasError = true);
    Future.delayed(const Duration(seconds: 1), _redirectToLogin);
  }

  void _redirectByRole(String role) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (role) {
        case 'admin':
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminScreen()));
          break;
        case 'online':
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const OnlineClientScreen()));
          break;
        default:
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ClientScreen()));
      }
    });
  }

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (context, child) {
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
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Image.asset(
                      'assets/images/NewLifeLogo.png',
                      height: 200.h,
                      width: 200.w,
                    ),
                  ),
                  SizedBox(height: 30.h),
                  const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 20.h),
                  AnimatedOpacity(
                    opacity: _hasError ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: const Text(
                      'Iniciando sesión...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
