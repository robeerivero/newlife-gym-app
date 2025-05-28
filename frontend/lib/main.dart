import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/client_screen.dart';
import 'screens/online_client_screen.dart';

// Notificaciones
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Nombres de las tareas
const String kMorningNotificationTask = "morningNotificationTask";
const String kNightNotificationTask = "nightNotificationTask";

// --- WORKMANAGER CALLBACK ---
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    const androidInit = AndroidInitializationSettings('ic_notificacion');
    const initSettings = InitializationSettings(android: androidInit);
    await flutterLocalNotificationsPlugin.initialize(initSettings);

    if (task == kMorningNotificationTask) {
      await flutterLocalNotificationsPlugin.show(
        1,
        '¡Inicia el día!',
        'Empieza a contabilizar tus pasos desde ya 🚶‍♂️',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'canal_morning',
            'Notificaciones de la mañana',
            importance: Importance.max,
            priority: Priority.high,
            icon: 'ic_notificacion',
          ),
        ),
      );
    } else if (task == kNightNotificationTask) {
      await flutterLocalNotificationsPlugin.show(
        2,
        '¡Mira tus pasos!',
        'Consulta cuántos pasos has hecho hoy y revisa tu ranking en la app.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'canal_night',
            'Notificaciones de la noche',
            importance: Importance.max,
            priority: Priority.high,
            icon: 'ic_notificacion',
          ),
        ),
      );
    }
    return Future.value(true);
  });
}

// ---- Permisos: Solo notificaciones y solo primera vez ----
Future<void> requestNotificationPermissionIfNeeded() async {
  final prefs = await SharedPreferences.getInstance();
  final permisoPedido = prefs.getBool('permisoNotificacionesPedido') ?? false;
  if (permisoPedido) return;

  // ANDROID: Pedir POST_NOTIFICATIONS si Android 13+
  if (Platform.isAndroid) {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      status = await Permission.notification.request();
    }
    if (status.isGranted) {
      await prefs.setBool('permisoNotificacionesPedido', true);
    }
  }

  // iOS: pide permisos normales
  if (Platform.isIOS) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await prefs.setBool('permisoNotificacionesPedido', true);
  }
}

// --- Programar tareas Workmanager a horas exactas ---
Future<void> scheduleDailyTasks() async {
  DateTime now = DateTime.now();

  // Morning: 08:00
  DateTime nextMorning = DateTime(now.year, now.month, now.day, 8, 00);
  if (now.isAfter(nextMorning)) nextMorning = nextMorning.add(Duration(days: 1));
  final delayMorning = nextMorning.difference(now);

  // Night: 22:30
  DateTime nextNight = DateTime(now.year, now.month, now.day, 22, 30);
  if (now.isAfter(nextNight)) nextNight = nextNight.add(Duration(days: 1));
  final delayNight = nextNight.difference(now);

  // --- Cancela tareas anteriores ---
  await Workmanager().cancelAll();

  // --- Registra tareas periódicas ---
  await Workmanager().registerPeriodicTask(
    "morning_task_id",
    kMorningNotificationTask,
    frequency: const Duration(hours: 24),
    initialDelay: delayMorning,
    existingWorkPolicy: ExistingWorkPolicy.replace,
    constraints: Constraints(networkType: NetworkType.not_required),
  );

  await Workmanager().registerPeriodicTask(
    "night_task_id",
    kNightNotificationTask,
    frequency: const Duration(hours: 24),
    initialDelay: delayNight,
    existingWorkPolicy: ExistingWorkPolicy.replace,
    constraints: Constraints(networkType: NetworkType.not_required),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pide permisos SOLO la primera vez (solo el de notificaciones)
  await requestNotificationPermissionIfNeeded();

  // Inicializa Workmanager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  // Registra tareas para notificar a las horas deseadas
  await scheduleDailyTasks();

  runApp(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (context, child) => MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Clases',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/admin': (context) => AdminScreen(),
        '/client': (context) => ClientScreen(),
        '/online': (context) => OnlineClientScreen(),
      },
      supportedLocales: const [
        Locale('es', ''),
        Locale('en', ''),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
