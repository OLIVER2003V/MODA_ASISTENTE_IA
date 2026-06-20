import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

// ── Modelos ───────────────────────────────────────────────────────────────────

class DmUser {
  final String id;
  final String name;
  final String? profilePhoto;
  final String? avatarStyle;

  const DmUser({
    required this.id,
    required this.name,
    this.profilePhoto,
    this.avatarStyle,
  });

  factory DmUser.fromJson(Map<String, dynamic> j) => DmUser(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Usuario',
        profilePhoto: j['profilePhoto'] as String?,
        avatarStyle: j['avatarStyle'] as String?,
      );

  String get displayName => name.isNotEmpty ? name : 'Usuario';

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String? get avatarUrl => profilePhoto;
}

class DmMessage {
  final String id;
  final String content;
  final String conversationId;
  final String senderId;
  final bool read;
  final DateTime createdAt;
  final DmUser? sender;

  const DmMessage({
    required this.id,
    required this.content,
    required this.conversationId,
    required this.senderId,
    required this.read,
    required this.createdAt,
    this.sender,
  });

  factory DmMessage.fromJson(Map<String, dynamic> j) => DmMessage(
        id: j['id'] as String,
        content: j['content'] as String,
        conversationId: j['conversationId'] as String,
        senderId: j['senderId'] as String,
        read: j['read'] as bool? ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String),
        sender: j['sender'] != null
            ? DmUser.fromJson(j['sender'] as Map<String, dynamic>)
            : null,
      );
}

class DmLastMessage {
  final String content;
  final String senderId;
  final bool read;
  final DateTime createdAt;

  const DmLastMessage({
    required this.content,
    required this.senderId,
    required this.read,
    required this.createdAt,
  });

  factory DmLastMessage.fromJson(Map<String, dynamic> j) => DmLastMessage(
        content: j['content'] as String? ?? '',
        senderId: j['senderId'] as String? ?? '',
        read: j['read'] as bool? ?? true,
        createdAt: j['createdAt'] != null
            ? DateTime.parse(j['createdAt'] as String)
            : DateTime.now(),
      );
}

class DmConversation {
  final String id;
  final String participant1Id;
  final String participant2Id;
  final DateTime lastMessageAt;
  final DateTime createdAt;
  final DmUser? otherUser;
  final DmLastMessage? lastMessage;
  final int unreadCount;

  const DmConversation({
    required this.id,
    required this.participant1Id,
    required this.participant2Id,
    required this.lastMessageAt,
    required this.createdAt,
    this.otherUser,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory DmConversation.fromJson(Map<String, dynamic> j) {
    final count = j['_count'] as Map<String, dynamic>?;
    final lastMsgJson = j['lastMessage'] as Map<String, dynamic>?;

    return DmConversation(
      id: j['id'] as String,
      participant1Id: j['participant1Id'] as String? ?? '',
      participant2Id: j['participant2Id'] as String? ?? '',
      lastMessageAt: j['lastMessageAt'] != null
          ? DateTime.parse(j['lastMessageAt'] as String)
          : DateTime.now(),
      createdAt: j['createdAt'] != null
          ? DateTime.parse(j['createdAt'] as String)
          : DateTime.now(),
      otherUser: j['otherUser'] != null
          ? DmUser.fromJson(j['otherUser'] as Map<String, dynamic>)
          : null,
      lastMessage:
          lastMsgJson != null ? DmLastMessage.fromJson(lastMsgJson) : null,
      unreadCount: (count?['messages'] as num?)?.toInt() ?? 0,
    );
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

class DmService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, String>> get _authHeaders async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  // ── Conversaciones ────────────────────────────────────────────────────────

  static Future<List<DmConversation>> getConversations() async {
    final res = await http.get(
      Uri.parse('$baseUrl/dm'),
      headers: await _authHeaders,
    );
    if (res.statusCode != 200) {
      throw Exception('Error al cargar conversaciones');
    }
    final data = json.decode(res.body);
    final list = data is List ? data : (data['conversations'] as List? ?? []);
    return list
        .map((e) => DmConversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<DmConversation> getOrCreateConversation(String targetUserId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/dm/with/$targetUserId'),
      headers: await _authHeaders,
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      final err = json.decode(res.body);
      throw Exception(err['message'] ?? 'Error al abrir conversación');
    }
    return DmConversation.fromJson(
        json.decode(res.body) as Map<String, dynamic>);
  }

  // ── Mensajes ──────────────────────────────────────────────────────────────

  static Future<List<DmMessage>> getMessages(String conversationId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/dm/$conversationId/messages'),
      headers: await _authHeaders,
    );
    if (res.statusCode != 200) {
      throw Exception('Error al cargar mensajes');
    }
    final data = json.decode(res.body);
    final list = data is List ? data : (data['messages'] as List? ?? []);
    return list
        .map((e) => DmMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<DmMessage> sendMessage(
      String conversationId, String content) async {
    final res = await http.post(
      Uri.parse('$baseUrl/dm/$conversationId/messages'),
      headers: await _authHeaders,
      body: json.encode({'content': content}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      final err = json.decode(res.body);
      throw Exception(err['message'] ?? 'Error al enviar mensaje');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    final msg = body['message'] ?? body;
    return DmMessage.fromJson(msg as Map<String, dynamic>);
  }

  // ── No leídos ─────────────────────────────────────────────────────────────

  static Future<int> getUnreadCount() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/dm/unread-count'),
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
}
