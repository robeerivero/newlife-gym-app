import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Importar localizaciones
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'screens/login_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/client_screen.dart';
import 'screens/online_client_screen.dart';

void main() {
  runApp(
    ScreenUtilInit(
      designSize: Size(360, 690), // Tamaño base del diseño
      minTextAdapt: true,
      builder: (context, child) =>  MyApp(),
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
      home: LoginScreen(),
      routes: {
        '/admin': (context) => AdminScreen(),
        '/client': (context) => ClientScreen(),
        '/online': (context) => OnlineClientScreen(),
      },
      supportedLocales: const [
        Locale('es', ''), // Español
        Locale('en', ''), // Inglés
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

