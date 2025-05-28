import 'dart:async';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/salud_service.dart';

class SaludScreen extends StatefulWidget {
  const SaludScreen({super.key});
  @override
  State<SaludScreen> createState() => _SaludScreenState();
}

class _SaludScreenState extends State<SaludScreen> {
  int pasosHoy = 0;
  int inicialPasos = 0;
  double kcalQuemadasHoy = 0.0;
  double kcalConsumidasHoy = 0.0;
  List<Map<String, dynamic>> historial = [];
  bool loading = true;
  int objetivoSemanal = 50000;
  StreamSubscription<StepCount>? _stepsSubscription;
  bool permisoDenegado = false;

  @override
  void initState() {
    super.initState();
    _inicializarTodo();
  }

  @override
  void dispose() {
    _stepsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _inicializarTodo() async {
    setState(() {
      loading = true;
      permisoDenegado = false;
    });

    // === PEDIR PERMISO ACTIVITY_RECOGNITION ===
    final status = await Permission.activityRecognition.request();
    if (status != PermissionStatus.granted) {
      setState(() {
        permisoDenegado = true;
        loading = false;
      });
      _showPermisoDialog();
      return;
    }

    await _cargarObjetivo();

    await SaludService().inicializarPasosDiarios();
    final base = await SaludService().obtenerInicialPasosHoy();
    setState(() => inicialPasos = base);

    _stepsSubscription?.cancel();
    _stepsSubscription = Pedometer.stepCountStream.listen((event) async {
      int pasosActual = event.steps - inicialPasos;
      if (pasosActual < 0) pasosActual = 0;
      setState(() {
        pasosHoy = pasosActual;
      });
      await SaludService().actualizarBackend(
        pasosHoy,
        null,
        kcalConsumidasHoy,
      );
    }, onError: (e) {
      setState(() => pasosHoy = 0);
    });

    final hist = await SaludService().obtenerHistorialUltimos7Dias();

    double kcalConsHoy = 0.0, kcalQuemadasBackend = 0.0;
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    for (final dia in hist) {
      if ((dia['fecha'] ?? '').toString().split('T')[0] == todayStr) {
        kcalConsHoy = (dia['kcalConsumidas'] ?? 0.0).toDouble();
        kcalQuemadasBackend = (dia['kcalQuemadas'] ?? 0.0).toDouble();
        break;
      }
    }

    setState(() {
      kcalQuemadasHoy = kcalQuemadasBackend;
      kcalConsumidasHoy = kcalConsHoy;
      historial = hist;
      loading = false;
    });
  }

  void _showPermisoDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Permiso necesario"),
        content: const Text(
            "Para registrar tus pasos es necesario el permiso de Reconocimiento de Actividad. Por favor, concédelo desde ajustes."),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  Future<void> _cargarObjetivo() async {
    final prefs = await SharedPreferences.getInstance();
    final semana = _claveSemanaActual();
    final objetivo = prefs.getInt('objetivo_semana_$semana');
    setState(() {
      objetivoSemanal = objetivo ?? 50000;
    });
  }

  String _claveSemanaActual() {
    final ahora = DateTime.now();
    final week = ((int.parse(DateFormat('D').format(ahora)) - ahora.weekday + 10) / 7).floor();
    return "${ahora.year}-$week";
  }

  Future<void> _cambiarObjetivo() async {
    final TextEditingController ctrl = TextEditingController(text: objetivoSemanal.toString());
    final semana = _claveSemanaActual();
    final nuevo = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cuál es tu objetivo de pasos para esta semana?'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Pasos objetivo"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
              onPressed: () {
                int? val = int.tryParse(ctrl.text.trim());
                if (val != null && val > 0) {
                  Navigator.pop(ctx, val);
                }
              },
              child: const Text("Guardar")),
        ],
      ),
    );
    if (nuevo != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('objetivo_semana_$semana', nuevo);
      setState(() {
        objetivoSemanal = nuevo;
      });
    }
  }

  // Cambia esto para que SIEMPRE refresque la pantalla tras añadir kcal
  Future<void> _anadirKcalManual() async {
    await showDialog(
      context: context,
      builder: (ctx) {
        final kcalController = TextEditingController();
        return AlertDialog(
          title: const Text('Registrar kcal quemadas en clase'),
          content: TextField(
            controller: kcalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Kcal'),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(ctx),
            ),
            TextButton(
              child: const Text('Guardar'),
              onPressed: () async {
                final kcal = double.tryParse(kcalController.text) ?? 0.0;
                if (kcal <= 0) return;

                setState(() => loading = true);

                await SaludService().actualizarBackend(
                  pasosHoy,
                  kcal,
                  null,
                );

                Navigator.pop(ctx);
                await _inicializarTodo(); // <-- refresca todo para mostrar la suma
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calcular el lunes de esta semana
    final DateFormat fmt = DateFormat('yyyy-MM-dd');
    final now = DateTime.now();
    final int daysToMonday = now.weekday - DateTime.monday;
    final DateTime monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToMonday));
    final String mondayStr = fmt.format(monday);
    final String nowStr = fmt.format(now);

    final semana = historial.where((dia) {
      final f = DateTime.parse(dia['fecha']);
      final fStr = fmt.format(f);
      return fStr.compareTo(mondayStr) >= 0 && fStr.compareTo(nowStr) <= 0;
    }).toList()
      ..sort((a, b) => DateTime.parse(a['fecha']).compareTo(DateTime.parse(b['fecha'])));

    final int pasosSemana = semana.fold<int>(
      0,
      (sum, dia) => sum + ((dia['pasos'] ?? 0) as num).toInt(),
    );
    final double progreso = (pasosSemana / (objetivoSemanal > 0 ? objetivoSemanal : 1)).clamp(0.0, 1.0);

    Color colorProgreso;
    if (progreso >= 1.0) {
      colorProgreso = Colors.green;
    } else if (progreso > 0.7) {
      colorProgreso = Colors.lightGreen;
    } else if (progreso > 0.4) {
      colorProgreso = Colors.orangeAccent;
    } else {
      colorProgreso = Colors.redAccent;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        title: const Text('Salud', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag, color: Colors.white),
            onPressed: permisoDenegado ? null : _cambiarObjetivo,
            tooltip: "Cambiar objetivo semanal",
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: permisoDenegado ? null : _inicializarTodo,
            tooltip: "Sincronizar",
          ),
        ],
      ),
      body: permisoDenegado
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.error, size: 70, color: Colors.redAccent),
                  SizedBox(height: 16),
                  Text(
                    'El permiso de actividad es necesario\ny ha sido denegado.',
                    style: TextStyle(fontSize: 17, color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 6),
                      CircularPercentIndicator(
                        radius: 98,
                        lineWidth: 16,
                        percent: progreso,
                        animation: true,
                        animateFromLastPercent: true,
                        circularStrokeCap: CircularStrokeCap.round,
                        center: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "$pasosSemana",
                              style: TextStyle(
                                  fontSize: 36, fontWeight: FontWeight.bold, color: colorProgreso),
                            ),
                            Text("de $objetivoSemanal\npasos semanales",
                                textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 6),
                            Text(
                              progreso >= 1.0
                                  ? "¡Objetivo semanal completado! 🎉"
                                  : progreso > 0.7
                                      ? "¡Ya casi lo tienes!"
                                      : progreso > 0.4
                                          ? "¡Sigue sumando!"
                                          : "¡Ánimo, tú puedes!",
                              style: TextStyle(
                                  color: colorProgreso,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16),
                            ),
                          ],
                        ),
                        progressColor: colorProgreso,
                        backgroundColor: Colors.grey[300]!,
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _infoCard("👣", "Hoy", pasosHoy.toString(), Colors.blue[700]!),
                          _infoCard("🔥", "Kcal quem.", kcalQuemadasHoy.toStringAsFixed(0), Colors.redAccent),
                          _infoCard("🍽️", "Kcal cons.", kcalConsumidasHoy.toStringAsFixed(0), Colors.green),
                        ],
                      ),
                      const SizedBox(height: 26),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.fitness_center),
                        label: const Text("Añadir kcal de clase"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: loading || permisoDenegado ? null : _anadirKcalManual,
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'Historial (semana actual)',
                        style: TextStyle(
                            fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF1E88E5)),
                      ),
                      const SizedBox(height: 13),
                      _buildHistorial(semana),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _infoCard(String emoji, String label, String value, Color color) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 22),
        child: Column(
          children: [
            Text(
              emoji,
              style: TextStyle(fontSize: 38, shadows: [
                Shadow(
                  blurRadius: 2,
                  color: color.withOpacity(0.4),
                  offset: const Offset(0, 2),
                )
              ]),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorial(List<Map<String, dynamic>> semana) {
    if (semana.isEmpty) {
      return Column(
        children: const [
          Icon(Icons.history, size: 48, color: Colors.grey),
          Text('Sin historial por ahora.', style: TextStyle(color: Colors.grey)),
        ],
      );
    }

    return Column(
      children: semana.map((dia) {
        final fechaDT = DateTime.parse(dia['fecha']);
        final fecha = DateFormat.EEEE('es_ES').format(fechaDT).toUpperCase();
        final pasosDia = ((dia['pasos'] ?? 0) as num).toInt();
        final kcalDia = (dia['kcalQuemadas'] as num? ?? 0).toStringAsFixed(0);
        final kcalCons = (dia['kcalConsumidas'] as num? ?? 0).toStringAsFixed(0);
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          elevation: 3,
          child: ListTile(
            leading: Text(
              "👣",
              style: TextStyle(
                  fontSize: 36, color: Colors.blue[700], fontWeight: FontWeight.bold),
            ),
            title: Text(fecha,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('👣 $pasosDia pasos\n🔥 $kcalDia kcal\n🍽️ $kcalCons kcal consumidas',
                  style: const TextStyle(fontSize: 15)),
            ),
            isThreeLine: true,
          ),
        );
      }).toList(),
    );
  }
}
