import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isInitialized = false;

  Future<void> initNotifications() async {
    if (_isInitialized) return;

    // 1. Configuración de Notificaciones Locales (Android)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // 1.1 Configuración de Notificaciones Locales (iOS)
    // "presentAlert: true" es la CLAVE para que se vea con la app abierta
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true, // <--- ¡IMPORTANTE!
      defaultPresentBanner: true, // <--- ¡IMPORTANTE!
      defaultPresentSound: true, // <--- ¡IMPORTANTE!
    );

    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _localNotifications.initialize(initSettings);

    // 2. Crear Canal de Android (Para que suene y vibre)
    final androidChannel = const AndroidNotificationChannel(
      'high_importance_channel', // id
      'Notificaciones Importantes', // título
      description: 'Este canal se usa para notificaciones importantes.',
      importance: Importance.max, // <--- ¡IMPORTANTE! Max hace que aparezca encima (Heads-up)
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // 3. Pedir permisos a Firebase
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permiso de notificaciones concedido');
      
      // Obtener y enviar token
      String? token = await _fcm.getToken();
      if (token != null) {
        await _enviarTokenAlBackend(token);
      }
      _fcm.onTokenRefresh.listen(_enviarTokenAlBackend);

    } else {
      print('❌ Permiso de notificaciones denegado');
    }

    // 4. LISTENER: Cuando la app está ABIERTA (Primer Plano)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 Notificación recibida en primer plano: ${message.notification?.title}');
      
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // Si la notificación tiene datos visuales, la forzamos a mostrarse
      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel', // Debe coincidir con el canal creado arriba
              'Notificaciones Importantes',
              channelDescription: 'Canal para alertas importantes',
              icon: '@mipmap/ic_launcher',
              importance: Importance.max, // Prioridad Máxima para que salga el banner
              priority: Priority.high,
              playSound: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true, // Mostrar alerta visual en iOS
              presentBanner: true, // Bajar el banner
              presentSound: true, // Reproducir sonido
            ),
          ),
        );
      }
    });

    _isInitialized = true;
  }

  Future<void> _enviarTokenAlBackend(String fcmToken) async {
    String? jwtToken = await _storage.read(key: 'jwt_token');

    if (jwtToken == null) return;

    final String apiUrl = '${AppConstants.baseUrl}/api/usuarios/register-fcm-token'; 
    
    try {
      await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({'token': fcmToken}),
      );
      print('🚀 Token registrado/actualizado en servidor.');
    } catch (e) {
      print('❌ Error enviando token: $e');
    }
  }
}