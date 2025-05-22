import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pedometer/pedometer.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../config.dart';

class SaludService {
  final _storage = const FlutterSecureStorage();
  final Health _health = Health();

  Future<void> solicitarPermisos() async {
    await Permission.activityRecognition.request();
    await _health.requestAuthorization(
      [HealthDataType.ACTIVE_ENERGY_BURNED],
      permissions: [HealthDataAccess.READ],
    );
  }

  Future<Map<String, dynamic>> obtenerHistorialConRacha() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return {"historial": [], "racha": 0};

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/salud/historial'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> historial = data['historial'];
      final int racha = data['racha'] ?? 0;
      return {
        'historial': historial.map((e) => {
          'fecha': e['fecha'],
          'pasos': e['pasos'],
          'kcalQuemadas': (e['kcalQuemadas'] ?? 0.0).toDouble(),
          'kcalConsumidas': (e['kcalConsumidas'] ?? 0.0).toDouble(),
        }).toList(),
        'racha': racha,
      };
    }
    return {"historial": [], "racha": 0};
  }

  Future<List<String>> obtenerLogros() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/salud/logros'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(data['logros'] ?? []);
    }
    return [];
  }

  Future<int> obtenerPasosHoy() async {
    final stepsKey = 'initial_steps';
    final today = DateTime.now().toIso8601String().split('T')[0];
    final storedDate = await _storage.read(key: 'steps_date');
    int initial = 0;

    if (storedDate != today) {
      await _storage.write(key: 'steps_date', value: today);
      await _storage.delete(key: stepsKey);
    } else {
      final saved = await _storage.read(key: stepsKey);
      if (saved != null) initial = int.tryParse(saved) ?? 0;
    }

    final stepStream = Pedometer.stepCountStream;
    final completer = Completer<int>();

    stepStream.listen((event) async {
      if (initial == 0) {
        initial = event.steps;
        await _storage.write(key: stepsKey, value: initial.toString());
      }
      final pasosHoy = event.steps - initial;
      completer.complete(pasosHoy);
    }, onError: (e) => completer.complete(0));

    return completer.future;
  }

  Future<double> obtenerKcalDeporte() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: start,
        endTime: now,
      );
      return data.fold<double>(0.0, (sum, e) => sum + (e.value as num).toDouble());
    } catch (_) {
      return 0.0;
    }
  }

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

  Future<void> actualizarBackend(int pasos, double kcalQuemadas, double kcalConsumidas) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return;

    await http.put(
      Uri.parse('${AppConstants.baseUrl}/api/salud/pasos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'pasos': pasos,
        'kcalQuemadas': kcalQuemadas,
        'kcalConsumidas': kcalConsumidas,
        'fecha': DateTime.now().toIso8601String().split('T')[0],
      }),
    );
  }

  static tz.TZDateTime hoyA23Horas() {
    tzdata.initializeTimeZones();
    final location = tz.getLocation('Europe/Madrid');
    final now = tz.TZDateTime.now(location);
    return tz.TZDateTime(location, now.year, now.month, now.day, 23, 0);
  }

  Widget botonKcalClase(BuildContext context) {
    final kcalController = TextEditingController();

    return ElevatedButton.icon(
      icon: const Icon(Icons.fitness_center),
      label: const Text("Añadir kcal de clase"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Registrar kcal quemadas en clase'),
            content: TextField(
              controller: kcalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Kcal'),
            ),
            actions: [
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text('Guardar'),
                onPressed: () async {
                  final kcal = double.tryParse(kcalController.text) ?? 0.0;
                  final token = await _storage.read(key: 'jwt_token');
                  if (token == null) return;

                  // Obtener kcal quemadas actuales
                  double existingKcal = 0.0;
                  final today = DateTime.now().toIso8601String().split('T')[0];
                  final response = await http.get(
                    Uri.parse('${AppConstants.baseUrl}/api/salud/historial'),
                    headers: {'Authorization': 'Bearer $token'},
                  );

                  if (response.statusCode == 200) {
                    final data = json.decode(response.body);
                    final todayEntry = (data['historial'] as List).firstWhere(
                      (e) => e['fecha'].startsWith(today),
                      orElse: () => null,
                    );
                    if (todayEntry != null && todayEntry['kcalQuemadas'] != null) {
                      existingKcal = (todayEntry['kcalQuemadas'] as num).toDouble();
                    }
                  }

                  await http.put(
                    Uri.parse('${AppConstants.baseUrl}/api/salud/pasos'),
                    headers: {
                      'Content-Type': 'application/json',
                      'Authorization': 'Bearer $token',
                    },
                    body: json.encode({
                      'kcalQuemadas': existingKcal + kcal,
                      'fecha': today,
                    }),
                  );

                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
