import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../config.dart';

class SaludService {
  final _storage = const FlutterSecureStorage();

  // 1. Solicitar permisos
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

  // 6. Actualiza backend con los pasos actuales
  Future<void> actualizarBackend(int pasos, [double? kcalQuemadas, double? kcalConsumidas]) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return;

    final Map<String, dynamic> payload = {
      'pasos': pasos,
      'kcalQuemadas': kcalQuemadas,
      'kcalConsumidas': kcalConsumidas,
      'fecha': DateTime.now().toIso8601String().split('T')[0],
    };

    await http.put(
      Uri.parse('${AppConstants.baseUrl}/api/salud/pasos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(payload),
    );
  }

  // 7. Botón para sumar kcal manualmente
  Widget botonKcalClase(BuildContext context, VoidCallback onActualizado) {
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
                  if (kcal <= 0) return;

                  final token = await _storage.read(key: 'jwt_token');
                  if (token == null) return;

                  final today = DateTime.now().toIso8601String().split('T')[0];

                  await http.put(
                    Uri.parse('${AppConstants.baseUrl}/api/salud/pasos'),
                    headers: {
                      'Content-Type': 'application/json',
                      'Authorization': 'Bearer $token',
                    },
                    body: json.encode({
                      'kcalQuemadas': kcal,
                      'fecha': today,
                      'sumarKcal': true, // Sumar a lo existente
                    }),
                  );

                  Navigator.pop(context);
                  onActualizado();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 8. Para notificaciones a las 23h (por si usas en otro lado)
  static tz.TZDateTime hoyA23Horas() {
    tzdata.initializeTimeZones();
    final location = tz.getLocation('Europe/Madrid');
    final now = tz.TZDateTime.now(location);
    return tz.TZDateTime(location, now.year, now.month, now.day, 23, 0);
  }
}
