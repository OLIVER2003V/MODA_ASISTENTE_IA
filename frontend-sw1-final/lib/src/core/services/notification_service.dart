import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

// ── Modelos ───────────────────────────────────────────────────────────────────

class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  bool read;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    this.data,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        userId: j['userId'] as String? ?? '',
        type: j['type'] as String? ?? 'info',
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        read: j['read'] as bool? ?? false,
        data: j['data'] as Map<String, dynamic>?,
        createdAt: j['createdAt'] != null
            ? DateTime.parse(j['createdAt'] as String)
            : DateTime.now(),
      );

  // Ícono según tipo
  String get icon => switch (type) {
        'reaction' => '❤️',
        'comment'  => '💬',
        'follow'   => '👤',
        'message'  => '✉️',
        _          => '🔔',
      };
}

// ── Service ───────────────────────────────────────────────────────────────────

class NotificationService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, String>> get _authHeaders async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<AppNotification>> getNotifications() async {
    final res = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: await _authHeaders,
    );
    if (res.statusCode != 200) {
      throw Exception('Error al cargar notificaciones');
    }
    final data = json.decode(res.body);
    final list =
        data is List ? data : (data['notifications'] as List? ?? []);
    return list
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<int> getUnreadCount() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/notifications/unread-count'),
        headers: await _authHeaders,
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return (data['count'] as num?)?.toInt() ??
            (data['unreadCount'] as num?)?.toInt() ??
            0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> markRead(String notificationId) async {
    await http.patch(
      Uri.parse('$baseUrl/notifications/$notificationId/read'),
      headers: await _authHeaders,
    );
  }

  static Future<void> markAllRead() async {
    await http.patch(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: await _authHeaders,
    );
  }
}
