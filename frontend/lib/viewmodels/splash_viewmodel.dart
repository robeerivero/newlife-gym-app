import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';

class SplashViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  late AnimationController controller;
  late Animation<double> scaleAnimation;
  bool hasError = false;
  bool isLoading = true;
  String? nextRoute;
  Object? nextRouteArgs;

  SplashViewModel(TickerProvider vsync) {
    controller = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 2),
    );
    scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
    );
    controller.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await _storage.read(key: 'jwt_token');
    await Future.delayed(const Duration(seconds: 2));

    if (token != null) {
      final result = await _authService.verifyToken(token);
      if (result.success && result.accessToken != null && result.role != null) {
        await _storage.write(key: 'jwt_token', value: result.accessToken);
        _setNextRoute(result.role!);
      } else {
        _handleAuthError();
      }
    } else {
      _handleAuthError();
    }
  }

  void _handleAuthError() {
    hasError = true;
    isLoading = false;
    nextRoute = '/login';
    notifyListeners();
  }

  void _setNextRoute(String role) {
    isLoading = false;
    switch (role) {
      case 'admin':
        nextRoute = '/admin';
        break;
      case 'online':
        nextRoute = '/online_client';
        break;
      default:
        nextRoute = '/client';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
