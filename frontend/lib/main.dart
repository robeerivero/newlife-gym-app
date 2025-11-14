import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// --- Imports para notificaciones programadas en iOS ---
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/client_viewmodel.dart';
import 'views/splash/splash_screen.dart';
import 'views/login/login_screen.dart';
import 'views/admin/admin_screen.dart';
import 'views/client/client_screen.dart';
//import 'views/online_client/online_client_screen.dart';

// Notificaciones
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Nombres de las tareas (para Android/Workmanager)
const String kMorningNotificationTask = "morningNotificationTask";
const String kNightNotificationTask = "nightNotificationTask";

// --- WORKMANAGER CALLBACK (SOLO ANDROID) ---
// (Esta función solo será llamada en móvil, por lo que es segura)
@pragma('vm:entry-point') // Recomendado por la documentación de Workmanager
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
// (Esta función solo será llamada en móvil gracias al kIsWeb)
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

  // iOS: El permiso se pide al inicializar el plugin
  // (DarwinInitializationSettings)
  // Pero marcamos que ya se pidió para no insistir.
  if (Platform.isIOS) {
    // La inicialización en main() ya pide el permiso.
    // Solo necesitamos registrar que el intento se hizo.
    await prefs.setBool('permisoNotificacionesPedido', true);
  }
}

// --- Programar tareas Workmanager (SOLO ANDROID) ---
Future<void> scheduleAndroidTasks() async {
  DateTime now = DateTime.now();

  // Morning: 08:00
  DateTime nextMorning = DateTime(now.year, now.month, now.day, 8, 00);
  if (now.isAfter(nextMorning))
    nextMorning = nextMorning.add(Duration(days: 1));
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
    existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    
  );

  await Workmanager().registerPeriodicTask(
    "night_task_id",
    kNightNotificationTask,
    frequency: const Duration(hours: 24),
    initialDelay: delayNight,
    existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    
  );
}

// --- !! NUEVA FUNCIÓN SOLO PARA iOS !! ---
// Esta usa el planificador del propio plugin de notificaciones
Future<void> scheduleIOSTasks() async {
  // Función para calcular la próxima hora (ej. 8:00 AM)
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // 1. Notificación de la mañana (8:00)
  await flutterLocalNotificationsPlugin.zonedSchedule(
    1, // ID de la notificación
    '¡Inicia el día!',
    'Empieza a contabilizar tus pasos desde ya 🚶‍♂️',
    _nextInstanceOf(8, 0), // 08:00
    const NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    androidAllowWhileIdle: false, // No aplica a iOS
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time, // ¡Repetir diariamente!
  );

  // 2. Notificación de la noche (22:30)
  await flutterLocalNotificationsPlugin.zonedSchedule(
    2, // ID de la notificación
    '¡Mira tus pasos!',
    'Consulta cuántos pasos has hecho hoy y revisa tu ranking en la app.',
    _nextInstanceOf(22, 30), // 22:30
    const NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    androidAllowWhileIdle: false, // No aplica a iOS
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time, // ¡Repetir diariamente!
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);

  // --- INICIO DE LA CORRECCIÓN PARA MÓVIL (iOS/Android) ---
  // Comprueba si NO estamos en un navegador web.
  if (!kIsWeb) {
    // 1. Inicializar Timezones (necesario para zonedSchedule)
    tz.initializeTimeZones();

    // 2. Inicializar el plugin de notificaciones (para ambas plataformas)
    const androidInit = AndroidInitializationSettings('ic_notificacion');
    // Necesario para que la app pida permiso en iOS
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    // Nota: La solicitud de permiso de iOS se dispara aquí
    await flutterLocalNotificationsPlugin.initialize(initSettings);

    // 3. Pedir permisos de Android si es necesario
    // (y registrar que ya se pidió en iOS)
    await requestNotificationPermissionIfNeeded();

    // 4. LÓGICA DE TAREAS SEPARADA POR PLATAFORMA
    if (Platform.isAndroid) {
      // Usa Workmanager para Android
      await Workmanager().initialize(callbackDispatcher);
      await scheduleAndroidTasks(); // Tu función original
    } else if (Platform.isIOS) {
      // Usa Notificaciones Locales Programadas para iOS
      await scheduleIOSTasks(); // La nueva función
    }
  }
  // --- FIN DE LA CORRECCIÓN ---

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProfileViewModel()..fetchProfile(),
        ),
        ChangeNotifierProvider(create: (_) => ClientViewModel()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (context, child) => const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
        //'/online': (context) => OnlineClientScreen(),
      },
      supportedLocales: const [Locale('es', ''), Locale('en', '')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('es', 'Es'), // Forzar español
    );
  }
}
