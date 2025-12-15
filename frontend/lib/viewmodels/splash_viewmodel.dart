import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart'; // <--- IMPORTAR

class SplashViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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
    // Leemos el token guardado
    final token = await _storage.read(key: 'jwt_token');
    
    // Simulación de carga mínima (opcional, por estética)
    await Future.delayed(const Duration(seconds: 2));

    if (token != null) {
      // Verificamos si el token sigue siendo válido en el backend
      final result = await _authService.verifyToken(token);
      
      if (result.success && result.accessToken != null && result.role != null) {
        // 1. Actualizamos el token (por si el backend nos dio uno nuevo refrescado)
        await _storage.write(key: 'jwt_token', value: result.accessToken);

        // 2. ¡NUEVO! Reactivar notificaciones en el arranque
        // Esto asegura que el backend tenga el token FCM actualizado
        try {
          await NotificationService().initNotifications();
          print("🔔 Notificaciones reactivadas en Splash");
        } catch (e) {
          print("⚠️ Error reactivando notificaciones (Splash): $e");
        }

        // 3. Decidir ruta
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
        nextRoute = '/online';
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