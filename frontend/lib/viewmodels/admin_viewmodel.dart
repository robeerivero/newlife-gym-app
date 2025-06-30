import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AdminViewModel extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();

  Future<void> logout(BuildContext context) async {
    await _storage.delete(key: 'jwt_token');
    Navigator.pushReplacementNamed(context, '/login');
  }

}
