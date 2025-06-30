import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config.dart';
import '../models/salud.dart';

class SaludService {
  final _storage = const FlutterSecureStorage();

  Future<bool> solicitarPermisos() async {
    final status = await Permission.activityRecognition.request();
    return status == PermissionStatus.granted;
  }

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

  Future<List<Salud>> obtenerHistorialUltimos7Dias() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/salud/historial'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> historial = data['historial'] ?? [];
      return historial.map((e) => Salud.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> actualizarBackend(int pasos, [double? kcalQuemadas, double? kcalConsumidas]) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return;

    final now = DateTime.now();
    final fechaUtc = DateTime.utc(now.year, now.month, now.day);

    final payload = <String, dynamic>{
      'pasos': pasos,
      'fecha': DateTime.now().toIso8601String().split('T')[0], // Aquí el cambio importante
    };

    if (kcalQuemadas != null) {
      payload['kcalQuemadas'] = kcalQuemadas;
      payload['sumarKcal'] = true;
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

  
  // Devuelve un objeto Salud para el día dado
  Future<Salud?> fetchSaludDia(String fecha) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return null;

    // La fecha siempre en UTC ISO para evitar líos de zona horaria
    final now = DateTime.now();
    final fechaUtc = DateTime.utc(now.year, now.month, now.day);
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/salud/dia/${fechaUtc.toIso8601String()}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return Salud.fromJson(json.decode(response.body));
    }
    return null;
  }
}
