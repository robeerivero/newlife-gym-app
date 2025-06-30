import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class QRService {
  final _storage = const FlutterSecureStorage();

  Future<String> registrarAsistencia(String scannedData) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      return 'Token no encontrado.';
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/reservas/asistencia'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'codigoQR': scannedData,
        }),
      );

      if (response.statusCode == 200) {
        return '✅ Asistencia registrada correctamente';
      } else {
        final data = json.decode(response.body);
        return '❌ Error: ${data['mensaje'] ?? 'Desconocido'}';
      }
    } catch (e) {
      return '❌ Error de conexión';
    }
  }
}
