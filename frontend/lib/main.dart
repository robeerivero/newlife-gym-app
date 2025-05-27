import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/client_screen.dart';
import 'screens/online_client_screen.dart';

// Nombre de la tarea
const String kDailyNotificationTask = "dailyNotificationTask";

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == kDailyNotificationTask) {
      print("[WorkManager] Ejecutando notificación diaria");

      // Inicializa notificaciones locales
      final plugin = FlutterLocalNotificationsPlugin();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: androidInit);

      await plugin.initialize(settings);

      await plugin.show(
        0,
        'Sincroniza tus pasos',
        '¡No olvides abrir la app y sincronizar tus pasos de hoy!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'canal1',
            'Notificaciones diarias',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa WorkManager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false, // Ponlo en true solo en desarrollo
  );

  // Registra tarea periódica solo para notificación (no pasos)
  await Workmanager().registerPeriodicTask(
    "1", // id único
    kDailyNotificationTask,
    frequency: const Duration(hours: 24), // Cada 24h
    initialDelay: const Duration(hours: 23), // Para que salga cerca de las 23h la primera vez
    constraints: Constraints(
      networkType: NetworkType.not_required,
    ),
  );

  runApp(
    ScreenUtilInit(
      designSize: Size(360, 690),
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
