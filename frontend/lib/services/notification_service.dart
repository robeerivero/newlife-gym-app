// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Inicializar
  Future<void> initNotifications() async {
    // 1. Pedir permiso (Crítico para iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permiso de notificaciones concedido');
      
      // 2. Obtener el token (esto identifica al dispositivo)
      String? token = await _fcm.getToken();
      
      if (token != null) {
        print('📬 FCM Token: $token');
        // Aquí deberíamos intentar enviarlo al backend si el usuario ya está logueado
        await _enviarTokenAlBackend(token);
      }
      
      // 3. Escuchar cambios de token (si se refresca)
      _fcm.onTokenRefresh.listen((newToken) {
         _enviarTokenAlBackend(newToken);
      });

    } else {
      print('❌ Permiso de notificaciones denegado');
    }

    // 4. Configurar handlers para cuando la app está abierta
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 Notificación en primer plano: ${message.notification?.title}');
      // Aquí podrías mostrar un "SnackBar" o un diálogo si quieres
    });
  }

  // Enviar al Backend
  Future<void> _enviarTokenAlBackend(String fcmToken) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jwtToken = prefs.getString('token'); // Tu token de autenticación (JWT)

    if (jwtToken == null) return; // Si no hay usuario logueado, no enviamos nada

    // CAMBIA ESTO POR TU URL REAL (localhost para emulador Android es 10.0.2.2)
    // Si usas dispositivo físico, usa la IP de tu PC (ej. 192.168.1.XX)
    const String apiUrl = 'http://10.0.2.2:5000/api/usuarios/register-fcm-token'; 

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({'token': fcmToken}),
      );

      if (response.statusCode == 200) {
        print('🚀 Token registrado en el servidor correctamente.');
      } else {
        print('⚠️ Error al registrar token en servidor: ${response.body}');
      }
    } catch (e) {
      print('❌ Error de conexión al enviar token: $e');
    }
  }
}