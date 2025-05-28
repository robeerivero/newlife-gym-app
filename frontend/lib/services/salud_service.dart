import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config.dart';

class SaludService {
  final _storage = const FlutterSecureStorage();

  // 1. Solicitar permisos (activity recognition)
  Future<void> solicitarPermisos() async {
    await Permission.activityRecognition.request();
  }

  // 2. Inicializa el valor base del día
  Future<void> inicializarPasosDiarios() async {
    final stepsKey = 'initial_steps';
    final todayKey = 'steps_date';
    final today = DateTime.now().toIso8601String().split('T')[0];
    final storedDate = await _storage.read(key: todayKey);
    final savedInitial = await _storage.read(key: stepsKey);

    if (storedDate != today || savedInitial == null) {
      final firstEvent = await Pedometer.stepCountStream.first;
      await _storage.write(key: todayKey, value: today);
      await _storage.write(key: stepsKey, value: firstEvent.steps.toString());
    }
  }

  // 3. Devuelve el valor inicial del día
  Future<int> obtenerInicialPasosHoy() async {
    final stepsKey = 'initial_steps';
    final todayKey = 'steps_date';
    final today = DateTime.now().toIso8601String().split('T')[0];
    final storedDate = await _storage.read(key: todayKey);
    final savedInitial = await _storage.read(key: stepsKey);
    if (storedDate == today && savedInitial != null) {
      return int.tryParse(savedInitial) ?? 0;
    }
    return 0;
  }

  // 4. Devuelve la lista simple del historial (últimos 7 días)
  Future<List<Map<String, dynamic>>> obtenerHistorialUltimos7Dias() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/salud/historial'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> historial = data['historial'] ?? [];
      return historial
          .map<Map<String, dynamic>>((e) => {
                'fecha': e['fecha'],
                'pasos': e['pasos'] ?? 0,
                'kcalQuemadas': (e['kcalQuemadas'] ?? 0.0).toDouble(),
                'kcalConsumidas': (e['kcalConsumidas'] ?? 0.0).toDouble(),
              })
          .toList();
    }
    return [];
  }

  // 5. Obtener kcal consumidas hoy (opcional, desde backend)
  Future<double> obtenerKcalConsumidas() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return 0.0;

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/salud/kcal-consumidas'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['kcalConsumidas'] ?? 0.0).toDouble();
    }
    return 0.0;
  }

  /// 6. Actualiza backend con los pasos actuales, o suma kcal manuales.
  /// Si mandas [kcalQuemadas], el backend la suma (si sumarKcal=true).
  Future<void> actualizarBackend(int pasos, [double? kcalQuemadas, double? kcalConsumidas]) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return;

    final payload = <String, dynamic>{
      'pasos': pasos,
      'fecha': DateTime.now().toIso8601String().split('T')[0],
    };

    if (kcalQuemadas != null) {
      payload['kcalQuemadas'] = kcalQuemadas;
      payload['sumarKcal'] = true; // para el backend: suma, no reemplaza
    }
    if (kcalConsumidas != null) {
      payload['kcalConsumidas'] = kcalConsumidas;
    }

    await http.put(
      Uri.parse('${AppConstants.baseUrl}/api/salud/pasos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(payload),
    );
  }
}
