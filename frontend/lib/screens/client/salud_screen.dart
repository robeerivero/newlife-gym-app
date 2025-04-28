import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config.dart';

class SaludScreen extends StatefulWidget {
  const SaludScreen({Key? key}) : super(key: key);

  @override
  _SaludScreenState createState() => _SaludScreenState();
}

class _SaludScreenState extends State<SaludScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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
    _requestPermission().then((_) => _initializePedometer());
    _obtenerKcalConsumidas();
    _verificarCambioDeDia();
  }

  Future<void> _requestPermission() async {
    var status = await Permission.activityRecognition.status;
    if (!status.isGranted) {
      status = await Permission.activityRecognition.request();
      if (!status.isGranted) {
        setState(() {
          _errorMessage = 'Permiso de actividad física denegado.';
        });
        throw Exception('Permiso de actividad física denegado.');
      }
    }
  }

  Future<void> _initializePedometer() async {
    try {
      final storedDate = await _storage.read(key: 'steps_date');
      final storedSteps = await _storage.read(key: 'initial_steps');
      final today = DateTime.now().toIso8601String().split('T')[0];
      int _initialSteps = 0;

      if (storedDate != today) {
        await _storage.write(key: 'steps_date', value: today);
        _initialSteps = 0;
      } else if (storedSteps != null) {
        _initialSteps = int.tryParse(storedSteps) ?? 0;
      }

      _stepCountStream = Pedometer.stepCountStream;
      _stepCountStream.listen(
        (StepCount event) async {
          if (_initialSteps == 0) {
            _initialSteps = event.steps;
            await _storage.write(key: 'initial_steps', value: _initialSteps.toString());
          }

          final pasosHoy = event.steps - _initialSteps;
          final kcalQuemadas = _calculateCalories(pasosHoy);

          setState(() {
            _pasos = pasosHoy;
            _kcalQuemadas = kcalQuemadas;
          });

          await _actualizarPasosBackend(pasosHoy, kcalQuemadas);
        },
        onError: (error) {
          setState(() {
            _errorMessage = 'Error al obtener los pasos: $error';
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  double _calculateCalories(int steps) {
    const double caloriesPerStep = 0.04;
    return steps * caloriesPerStep;
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
    if (token == null) {
      setState(() {
        _errorMessage = 'No se encontró el token. Por favor, inicia sesión nuevamente.';
      });
      return;
    }

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
      } else {
        print('Error al obtener kcal consumidas');
      }
    } catch (e) {
      print('Error de conexión: $e');
    }
  }

  Future<void> _guardarDatosSalud() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return;

    final hoy = DateTime.now().toIso8601String().split('T')[0];

    try {
      await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/salud/guardar-datos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'fecha': hoy,
          'pasos': _pasos,
          'kcalQuemadas': _kcalQuemadas,
          'kcalConsumidas': _kcalConsumidas,
        }),
      );
    } catch (e) {
      print('Error al guardar datos: $e');
    }
  }

  Future<void> _verificarCambioDeDia() async {
    final hoy = DateTime.now().toIso8601String().split('T')[0];
    final storedDate = await _storage.read(key: 'steps_date');

    if (storedDate != hoy) {
      await _guardarDatosSalud();
      await _storage.write(key: 'steps_date', value: hoy);
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
          final ultimoRegistro = data.last;
          setState(() {
            _pasos = ultimoRegistro['pasos'] ?? 0;
            _kcalQuemadas = (ultimoRegistro['kcalQuemadas'] ?? 0).toDouble();
            _kcalConsumidas = (ultimoRegistro['kcalConsumidas'] ?? 0).toDouble();
            _historial = data.map((e) => {
              'fecha': e['fecha'],
              'pasos': e['pasos'],
              'kcalQuemadas': e['kcalQuemadas'],
              'kcalConsumidas': e['kcalConsumidas'],
            }).toList();
          });
        }
      } else {
        print('Error al obtener historial de salud');
      }
    } catch (e) {
      print('Error de conexión: $e');
    }
  }

  Widget _crearGraficoHistorial() {
    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < _historial.length) {
                    return Text(_historial[index]['fecha'].split('-').last);
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _historial.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data['kcalQuemadas'].toDouble(),
                  color: Colors.green,
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: data['kcalConsumidas'].toDouble(),
                  color: Colors.red,
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),

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

            _historial.isNotEmpty
                ? _crearGraficoHistorial()
                : const Text('No hay datos aún.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
