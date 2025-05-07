import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'screens/login_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/client_screen.dart';
import 'screens/online_client_screen.dart';
import 'screens/splash_screen.dart'; // Añade esta importación

void main() {
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
      home: SplashScreen(), // Cambia a SplashScreen
      routes: {
        '/login': (context) => LoginScreen(), // Añade esta ruta
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