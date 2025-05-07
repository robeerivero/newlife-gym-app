import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:health/health.dart';
import '../../config.dart';

class SaludScreen extends StatefulWidget {
  const SaludScreen({Key? key}) : super(key: key);

  @override
  _SaludScreenState createState() => _SaludScreenState();
}

class _SaludScreenState extends State<SaludScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Health _health = Health();

  int _pasos = 0;
  double _kcalQuemadas = 0.0;
  double _kcalConsumidas = 0.0;
  List<Map<String, dynamic>> _historial = [];
  String? _errorMessage;
  late Stream<StepCount> _stepCountStream;

  @override
  void initState() {
    super.initState();
    _cargarDatosSalud();
    _requestPermission()
        .then((_) => _initializePedometer())
        .then((_) => _requestHealthPermissions());
    _obtenerKcalConsumidas();
    _verificarCambioDeDia();
  }

  Future<void> _requestPermission() async {
    var status = await Permission.activityRecognition.status;
    if (!status.isGranted) {
      status = await Permission.activityRecognition.request();
      if (!status.isGranted) {
        setState(() => _errorMessage = 'Permiso de actividad física denegado.');
        throw Exception('Permiso de actividad física denegado.');
      }
    }
  }

  Future<void> _requestHealthPermissions() async {
    final types = [HealthDataType.ACTIVE_ENERGY_BURNED];
    final permissions = [HealthDataAccess.READ];
    bool requested = await _health.requestAuthorization(types, permissions: permissions);
    if (!requested) {
      print('Permiso para datos de salud denegado.');
    }
  }

  Future<void> _initializePedometer() async {
    try {
      final storedDate = await _storage.read(key: 'steps_date');
      final storedSteps = await _storage.read(key: 'initial_steps');
      final today = DateTime.now().toIso8601String().split('T')[0];
      int initialSteps = 0;

      if (storedDate != today) {
        await _storage.write(key: 'steps_date', value: today);
        initialSteps = 0;
      } else if (storedSteps != null) {
        initialSteps = int.tryParse(storedSteps) ?? 0;
      }

      _stepCountStream = Pedometer.stepCountStream;
      _stepCountStream.listen(
        (StepCount event) async {
          if (initialSteps == 0) {
            initialSteps = event.steps;
            await _storage.write(key: 'initial_steps', value: initialSteps.toString());
          }

          final pasosHoy = event.steps - initialSteps;
          final kcalPasos = _calculateCalories(pasosHoy);
          final kcalDeporte = await _obtenerKcalDeporte();
          final kcalTotal = kcalPasos + kcalDeporte;

          setState(() {
            _pasos = pasosHoy;
            _kcalQuemadas = kcalTotal;
          });

          await _actualizarPasosBackend(pasosHoy, kcalTotal);
        },
        onError: (error) {
          setState(() => _errorMessage = 'Error al obtener los pasos: $error');
        },
      );
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }

  double _calculateCalories(int steps) {
    const double caloriesPerStep = 0.04;
    return steps * caloriesPerStep;
  }

  Future<double> _obtenerKcalDeporte() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    try {
      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: start,
        endTime: now,
      );
      double total = data.fold(0.0, (sum, e) => sum + (e.value as num).toDouble());
      return total;
    } catch (e) {
      print('Error al leer kcal deporte: $e');
      return 0.0;
    }
  }

  Future<void> _actualizarPasosBackend(int pasos, double kcalQuemadas) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return;

    try {
      await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/salud/pasos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'pasos': pasos,
          'kcalQuemadas': kcalQuemadas,
          'kcalConsumidas': _kcalConsumidas,
          'fecha': DateTime.now().toIso8601String().split('T')[0],
        }),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar pasos: $e')),
      );
    }
  }

  Future<void> _obtenerKcalConsumidas() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/salud/kcal-consumidas'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _kcalConsumidas = (data['kcalConsumidas'] ?? 0).toDouble();
        });
      }
    } catch (e) {
      print('Error de conexión: $e');
    }
  }

  Future<void> _cargarDatosSalud() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/salud/historial'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final ultimo = data.last;
          setState(() {
            _pasos = ultimo['pasos'] ?? 0;
            _kcalQuemadas = (ultimo['kcalQuemadas'] ?? 0.0).toDouble();
            _kcalConsumidas = (ultimo['kcalConsumidas'] ?? 0.0).toDouble();
            _historial = data.map((e) => {
              'fecha': e['fecha'],
              'pasos': e['pasos'],
              'kcalQuemadas': (e['kcalQuemadas'] ?? 0.0).toDouble(),
              'kcalConsumidas': (e['kcalConsumidas'] ?? 0.0).toDouble(),
            }).toList();
          });
        }
      }
    } catch (e) {
      print('Error de conexión: $e');
    }
  }

  Future<void> _verificarCambioDeDia() async {
    final hoy = DateTime.now().toIso8601String().split('T')[0];
    final storedDate = await _storage.read(key: 'steps_date');

    if (storedDate != hoy) {
      await _storage.write(key: 'steps_date', value: hoy);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCard("Pasos", _pasos.toString(), Icons.directions_walk),
                _buildMetricCard("Quemadas", "${_kcalQuemadas.toStringAsFixed(0)} kcal", Icons.local_fire_department),
                _buildMetricCard("Consumidas", "${_kcalConsumidas.toStringAsFixed(0)} kcal", Icons.restaurant),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Historial de los Últimos 7 Días', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _historial.isNotEmpty ? _crearListaHistorial() : const Text('No hay datos aún.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _crearListaHistorial() {
    return Column(
      children: _historial.map((dia) {
        final fechaStr = dia['fecha'];
        final fecha = DateTime.tryParse(fechaStr) ?? DateTime.now();
        final fechaFormateada = DateFormat.yMMMMEEEEd('es_ES').format(fecha).toUpperCase();

        final pasos = dia['pasos'] ?? 0;
        final kcalQuemadas = dia['kcalQuemadas'] ?? 0.0;
        final kcalConsumidas = dia['kcalConsumidas'] ?? 0.0;
        final diferencia = kcalQuemadas - kcalConsumidas;

        return SizedBox(
          width: double.infinity,
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.white,
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fechaFormateada,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow('👣 Pasos', pasos.toString()),
                  _buildInfoRow('🔥 Quemadas', '${kcalQuemadas.toStringAsFixed(0)} kcal'),
                  _buildInfoRow('🍽 Consumidas', '${kcalConsumidas.toStringAsFixed(0)} kcal'),
                  _buildInfoRow(
                    '➖ Diferencia',
                    '${diferencia.toStringAsFixed(0)} kcal',
                    color: diferencia >= 0 ? Colors.green : Colors.red,
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.blueAccent),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
