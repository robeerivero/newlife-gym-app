import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/salud_service.dart';

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
    final kcalComida = await SaludService().obtenerKcalConsumidas();

    final kcalTotal = pasosHoy * 0.04 + kcalDeporte;

    setState(() {
      pasos = pasosHoy;
      kcalQuemadas = kcalTotal;
      kcalConsumidas = kcalComida;
    });

    await SaludService().actualizarBackend(pasosHoy, kcalTotal, kcalComida);

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
      const NotificationDetails(
        android: AndroidNotificationDetails('canal1', 'Envios diarios'),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Widget _buildResumenSalud() {
    return Column(
      children: [
        _buildResumenItem(Icons.directions_walk, "Pasos", pasos.toString(), Colors.blue),
        _buildResumenItem(Icons.local_fire_department, "Kcal quemadas", kcalQuemadas.toStringAsFixed(0), Colors.redAccent),
        _buildResumenItem(Icons.restaurant, "Kcal consumidas", kcalConsumidas.toStringAsFixed(0), Colors.green),
      ],
    );
  }

  Widget _buildResumenItem(IconData icono, String titulo, String valor, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icono, size: 40, color: color),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(valor, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildResumenSalud(),
            const SizedBox(height: 10),
            SaludService().botonKcalClase(context),
            const SizedBox(height: 20),
            Card(
              color: Colors.orange[50],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.local_fire_department, color: Colors.orange),
                title: Text('🔥 Racha activa: $racha días'),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Logros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (logros.isEmpty)
              const Text('Aún no has obtenido logros. ¡Sigue avanzando!', style: TextStyle(color: Colors.grey)),
            ...logros.map((logro) => Card(
                  elevation: 3,
                  child: ListTile(
                    leading: const Icon(Icons.emoji_events, color: Colors.amber),
                    title: Text(logro),
                  ),
                )),
            const SizedBox(height: 20),
            const Text('Historial', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (historial.isEmpty)
              Column(
                children: const [
                  Icon(Icons.history, size: 48, color: Colors.grey),
                  Text('Sin historial por ahora.', style: TextStyle(color: Colors.grey)),
                ],
              )
            else
              Column(
                children: historial.map((dia) {
                  final fecha = DateFormat.yMMMd('es_ES').format(DateTime.parse(dia['fecha']));
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(fecha),
                      subtitle: Text('👣 ${dia['pasos']} pasos\n🔥 ${dia['kcalQuemadas']} kcal'),
                      isThreeLine: true,
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
