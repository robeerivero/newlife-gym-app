import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../config.dart';

class PrendasService {
  final _storage = const FlutterSecureStorage();

  Future<Map<String, Set<int>>> fetchPrendasDesbloqueadas() async {
    final token = await _storage.read(key: 'jwt_token');
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/usuarios/prendas/desbloqueadas'),
      headers: { 'Authorization': 'Bearer $token' },
    );
    if (response.statusCode == 200) {
      final prendas = jsonDecode(response.body) as List;
      Map<String, Set<int>> map = {};
      for (final prenda in prendas) {
        final key = prenda['key'];
        final idx = prenda['idx'];
        if (idx != null && idx is int) {
          map.putIfAbsent(key, () => <int>{}).add(idx);
        }
      }
      return map;
    }
    throw Exception('Error al cargar prendas desbloqueadas');
  }
}
