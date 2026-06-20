import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'storage_service.dart';
import 'user_service.dart';

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static String? _currentToken;

  /// Canal de notificaciones para Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notificaciones',
    description: 'Canal para notificaciones importantes',
    importance: Importance.high,
  );

  /// Inicializa Firebase Cloud Messaging
  static Future<void> initialize() async {
    // Solicitar permisos
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('FCM: Usuario autorizo notificaciones');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('FCM: Usuario autorizo notificaciones provisionales');
    } else {
      debugPrint('FCM: Usuario denego notificaciones');
      return;
    }

    // Inicializar notificaciones locales
    await _initializeLocalNotifications();

    // Obtener token FCM
    await _getAndRegisterToken();

    // Escuchar cambios de token
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM: Token actualizado');
      _registerTokenWithServer(newToken);
    });

    // Configurar handlers de mensajes
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Verificar si la app fue abierta desde una notificacion
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// Inicializa las notificaciones locales
  static Future<void> _initializeLocalNotifications() async {
    // Configuracion para Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuracion para iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Crear canal de notificaciones en Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  /// Maneja cuando el usuario toca una notificacion local
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('FCM: Notificacion local tocada: ${response.payload}');
  }

  /// Obtiene el token FCM y lo registra en el servidor
  static Future<void> _getAndRegisterToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        _currentToken = token;
        debugPrint('FCM Token: $token');
        await _registerTokenWithServer(token);
      }
    } catch (e) {
      debugPrint('FCM: Error obteniendo token: $e');
    }
  }

  /// Registra el token FCM en el servidor
  static Future<void> _registerTokenWithServer(String token) async {
    try {
      // Verificar si hay usuario autenticado
      final user = await StorageService.getUser();
      if (user == null) {
        debugPrint('FCM: No hay usuario autenticado, guardando token para despues');
        return;
      }

      // Registrar token en el servidor
      await UserService.registerFcmToken(token);
      debugPrint('FCM: Token registrado exitosamente');
    } catch (e) {
      debugPrint('FCM: Error registrando token: $e');
    }
  }

  /// Registra el token FCM cuando el usuario inicia sesion
  static Future<void> registerTokenOnLogin() async {
    if (_currentToken != null) {
      await _registerTokenWithServer(_currentToken!);
    } else {
      await _getAndRegisterToken();
    }
  }

  /// Maneja mensajes recibidos en primer plano
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('FCM: Mensaje recibido en primer plano');
    debugPrint('FCM: Titulo: ${message.notification?.title}');
    debugPrint('FCM: Cuerpo: ${message.notification?.body}');
    debugPrint('FCM: Data: ${message.data}');

    // Mostrar notificacion local
    _showLocalNotification(message);
  }

  /// Muestra una notificacion local
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  /// Maneja cuando el usuario abre la app desde una notificacion
  static void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('FCM: App abierta desde notificacion: ${message.data}');
    _handleNavigation(message.data);
  }

  static void _handleNavigation(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'dm':
        // La pantalla de DMs se abre desde el ícono de mensajes en el perfil.
        // Guardamos el conversationId para que la app lo abra al iniciar.
        _pendingConversationId = data['conversationId'] as String?;
        break;
      case 'outfit_ready':
        // El chat ya actualiza en tiempo real; solo traemos la app al frente.
        break;
      default:
        break;
    }
  }

  static String? _pendingConversationId;
  static String? consumePendingConversationId() {
    final id = _pendingConversationId;
    _pendingConversationId = null;
    return id;
  }

  /// Obtiene el token actual
  static String? get currentToken => _currentToken;
}
