// Archivo: lib/services/salud_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config.dart';
import 'package:pedometer/pedometer.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:flutter/material.dart';

class SaludService {
  final _storage = const FlutterSecureStorage();
  final Health _health = Health();

  Future<void> solicitarPermisos() async {
    await Permission.activityRecognition.request();
    await _health.requestAuthorization([
      HealthDataType.ACTIVE_ENERGY_BURNED
    ], permissions: [HealthDataAccess.READ]);
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
        'racha': racha
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

  Future<void> registrarActividadManual(BuildContext context) async {
    final pasosController = TextEditingController();
    final kcalController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Añadir actividad manual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            
            TextField(
              controller: kcalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Kcal quemadas'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final pasos = int.tryParse(pasosController.text) ?? 0;
              final kcal = double.tryParse(kcalController.text) ?? 0.0;
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
                  'kcalQuemadas': kcal,
                  'fecha': DateTime.now().toIso8601String().split('T')[0],
                }),
              );
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          )
        ],
      ),
    );
  }

  static tz.TZDateTime hoyA23Horas() {
    tzdata.initializeTimeZones();
    final location = tz.getLocation('Europe/Madrid');
    final now = tz.TZDateTime.now(location);
    return tz.TZDateTime(location, now.year, now.month, now.day, 23, 0);
  }

  Widget botonActividadManual(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => registrarActividadManual(context),
      icon: const Icon(Icons.add),
      label: const Text("Añadir actividad manual"),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
    );
  }
}
