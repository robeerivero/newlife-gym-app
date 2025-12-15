// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

// --- Imports de Firebase ---
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'theme/app_theme.dart';
import 'viewmodels/video_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/client_viewmodel.dart';
import 'views/splash/splash_screen.dart';
import 'views/login/login_screen.dart';
import 'views/admin/admin_screen.dart';
import 'views/client/client_screen.dart';

// Importa tu nuevo servicio
import 'services/notification_service.dart'; 

// --- HANDLER DE SEGUNDO PLANO (Fuera de Main) ---
// Esto se ejecuta si llega una notificación y la app está cerrada/segundo plano
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🌙 Mensaje en segundo plano recibido: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);

  // 1. Inicializar Firebase
  try {
    await Firebase.initializeApp();
    // Configurar el handler de segundo plano
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // 2. Inicializar nuestro servicio de notificaciones
    await NotificationService().initNotifications();
    
  } catch (e) {
    print("Error inicializando Firebase: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProfileViewModel()..fetchProfile(),
        ),
        ChangeNotifierProvider(create: (_) => ClientViewModel()),
        ChangeNotifierProvider(create: (_) => VideoViewModel()),
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
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: SplashScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/admin': (context) => AdminScreen(),
        '/client': (context) => ClientScreen(),
      },
      supportedLocales: const [Locale('es', ''), Locale('en', '')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('es', 'Es'),
    );
  }
}