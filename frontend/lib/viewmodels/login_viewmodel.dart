import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart'; // <--- IMPORTAR

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool isLoading = false;
  String? errorMessage;
  bool loginSuccess = false;
  String? role;
  bool rememberMe = false;

  Future<void> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _authService.login(email, password);

    if (result.success && result.accessToken != null && result.role != null) {
      // 1. Guardar el Token JWT
      await _storage.write(
        key: 'jwt_token',
        value: result.accessToken,
        aOptions: rememberMe
            ? const AndroidOptions(encryptedSharedPreferences: true)
            : const AndroidOptions(),
      );

      // 2. ¡NUEVO! Inicializar Notificaciones y enviar token al Backend
      // Hacemos esto aquí porque ya tenemos el JWT guardado, que el servicio necesita.
      try {
        await NotificationService().initNotifications();
        print("🔔 Notificaciones inicializadas tras login");
      } catch (e) {
        print("⚠️ Error inicializando notificaciones (Login): $e");
        // No bloqueamos el login si esto falla, pero lo logueamos
      }

      // 3. Finalizar proceso
      loginSuccess = true;
      role = result.role;
    } else {
      errorMessage = result.error;
    }
    
    isLoading = false;
    notifyListeners();
  }
}