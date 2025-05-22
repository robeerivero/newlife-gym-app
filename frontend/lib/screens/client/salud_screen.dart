// Archivo: lib/screens/salud_screen.dart (parcial, mejorado)

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/salud_service.dart';
import '../../widgets/anillo_progreso.dart';

class SaludScreen extends StatefulWidget {
  const SaludScreen({super.key});

  @override
  State<SaludScreen> createState() => _SaludScreenState();
}

class _SaludScreenState extends State<SaludScreen> {
  int pasos = 0;
  double kcalQuemadas = 0;
  double kcalConsumidas = 0;
  List<Map<String, dynamic>> historial = [];
  List<String> logros = [];
  int racha = 0;

  final Health health = Health();

  @override
  void initState() {
    super.initState();
    inicializarDatosSalud();
    programarEnvioAutomatico();
  }

  Future<void> inicializarDatosSalud() async {
    await SaludService().solicitarPermisos();
    final pasosHoy = await SaludService().obtenerPasosHoy();
    final kcalDeporte = await SaludService().obtenerKcalDeporte();
    final kcalTotal = pasosHoy * 0.04 + kcalDeporte;

    setState(() {
      pasos = pasosHoy;
      kcalQuemadas = kcalTotal;
    });

    await SaludService().actualizarBackend(pasosHoy, kcalTotal, kcalConsumidas);

    final datosHistorial = await SaludService().obtenerHistorialConRacha();
    final logrosRemotos = await SaludService().obtenerLogros();

    setState(() {
      historial = datosHistorial['historial'];
      racha = datosHistorial['racha'] ?? 0;
      logros = logrosRemotos;
    });
  }

  Future<void> programarEnvioAutomatico() async {
    final plugin = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidInit);
    await plugin.initialize(settings);

    await Permission.notification.request();

    await plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await plugin.zonedSchedule(
      0,
      'Envío de datos de salud',
      'Tus datos del día han sido sincronizados.',
      SaludService.hoyA23Horas(),
      const NotificationDetails(android: AndroidNotificationDetails('canal1', 'Envios diarios')),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 16),
          AnilloProgreso(valor: pasos.toDouble(), meta: 10000, etiqueta: 'Pasos'),
          AnilloProgreso(valor: kcalQuemadas, meta: 500, etiqueta: 'kcal quemadas'),
          AnilloProgreso(valor: kcalConsumidas, meta: 2000, etiqueta: 'kcal consumidas'),
          const SizedBox(height: 10),
          SaludService().botonActividadManual(context),
          const SizedBox(height: 20),
          Text('🔥 Racha activa: $racha días', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('Logros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...logros.map((logro) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(logro, style: const TextStyle(fontSize: 16)),
              )),
          const SizedBox(height: 20),
          const Text('Historial', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: historial.length,
              itemBuilder: (context, index) {
                final dia = historial[index];
                final fecha = DateFormat.yMMMd('es_ES').format(DateTime.parse(dia['fecha']));
                return ListTile(
                  title: Text(fecha),
                  subtitle: Text('Pasos: ${dia['pasos']}, Quemadas: ${dia['kcalQuemadas']} kcal'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
