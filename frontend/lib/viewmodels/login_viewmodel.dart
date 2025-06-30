import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';

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
      await _storage.write(
        key: 'jwt_token',
        value: result.accessToken,
        aOptions: rememberMe
            ? const AndroidOptions(encryptedSharedPreferences: true)
            : const AndroidOptions(),
      );
      loginSuccess = true;
      role = result.role;
    } else {
      errorMessage = result.error;
    }
    isLoading = false;
    notifyListeners();
  }
}
