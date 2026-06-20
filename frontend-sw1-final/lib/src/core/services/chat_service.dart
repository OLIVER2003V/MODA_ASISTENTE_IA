import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

class ChatService {
  static String get baseUrl => ApiConfig.baseUrl;

  /// Crea una nueva conversacion de chat
  static Future<ChatConversation> createConversation(
    String userId, {
    double? lat,
    double? lon,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticacion');
      }

      final body = <String, dynamic>{'userId': userId};
      if (lat != null && lon != null) {
        body['lat'] = lat;
        body['lon'] = lon;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/chat/conversations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ChatConversation.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Error al crear conversacion');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al crear conversacion: $e');
    }
  }

  /// Lista todas las conversaciones de un usuario
  static Future<List<ChatConversation>> getConversations(String userId) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticacion');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/chat/conversations/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        return data
            .map(
              (item) => ChatConversation.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else {
        final error = json.decode(response.body);
        throw Exception(
          error['message'] ?? 'Error al obtener historial de chats',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al obtener historial de chats: $e');
    }
  }

  /// Envia un mensaje a una conversacion existente
  static Future<ChatConversation> sendMessage(
    String conversationId,
    String content,
  ) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticacion');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/chat/conversations/$conversationId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'content': content}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ChatConversation.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Error al enviar mensaje');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al enviar mensaje: $e');
    }
  }

  /// Envia una imagen del rostro para recomendacion de peinado
  static Future<ChatConversation> sendFaceImage(
    String conversationId,
    File imageFile,
  ) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticacion');
      }

      final uri = Uri.parse(
        '$baseUrl/chat/conversations/$conversationId/face-image',
      );
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final client = http.Client();
      final streamedResponse = await client
          .send(request)
          .timeout(
            const Duration(seconds: 120),
            onTimeout: () {
              client.close();
              throw Exception(
                'El servidor tardo demasiado en responder. Intenta de nuevo.',
              );
            },
          );
      final response = await http.Response.fromStream(streamedResponse);

      final body = response.body;

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> data;
        try {
          data = json.decode(body);
        } on FormatException {
          throw Exception(
            'La respuesta del servidor no es JSON valido: ${body.length > 200 ? body.substring(0, 200) : body}',
          );
        }
        try {
          return ChatConversation.fromJson(data);
        } catch (e) {
          throw Exception('Error al parsear la conversacion: $e');
        }
      } else {
        String message =
            'Error al enviar imagen del rostro (${response.statusCode})';
        try {
          final error = json.decode(body);
          message = error['message'] ?? message;
        } catch (_) {
          // La respuesta de error no es JSON
        }
        throw Exception(message);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al enviar imagen del rostro: $e');
    }
  }

  /// Envía un audio grabado y lo transcribe automáticamente
  static Future<ChatConversation> sendAudio(
    String conversationId,
    File audioFile,
  ) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No hay token de autenticacion');

      final uri = Uri.parse('$baseUrl/chat/conversations/$conversationId/audio');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('file', audioFile.path),
      );

      final client = http.Client();
      final streamedResponse = await client.send(request).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          client.close();
          throw Exception('El servidor tardó demasiado. Intenta de nuevo.');
        },
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ChatConversation.fromJson(data as Map<String, dynamic>);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Error al enviar audio');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al enviar audio: $e');
    }
  }
}

/// Modelo para una conversacion de chat
class ChatConversation {
  final String id;
  final String status;
  final String? event;
  final String? weather;
  final String userId;
  final String? outfitId;
  final List<ChatMessage> messages;
  final ChatOutfit? outfit;
  final RecommendedHairstyle? recommendedHairstyle;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatConversation({
    required this.id,
    required this.status,
    this.event,
    this.weather,
    required this.userId,
    this.outfitId,
    required this.messages,
    this.outfit,
    this.recommendedHairstyle,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'],
      status: json['status'] ?? '',
      event: json['event'],
      weather: json['weather'],
      userId: json['userId'],
      outfitId: json['outfitId'],
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((item) => ChatMessage.fromJson(item))
              .toList() ??
          [],
      outfit: json['outfit'] != null
          ? ChatOutfit.fromJson(json['outfit'])
          : null,
      recommendedHairstyle: json['recommendedHairstyle'] != null
          ? RecommendedHairstyle.fromJson(json['recommendedHairstyle'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

/// Modelo para un mensaje de chat
class ChatMessage {
  final String id;
  final String content;
  final String role; // USER o ASSISTANT
  final String conversationId;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.conversationId,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      content: json['content'] ?? '',
      role: json['role'] ?? 'USER',
      conversationId: json['conversationId'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

/// Modelo para el outfit generado en el chat
class ChatOutfit {
  final String id;
  final String name;
  final int? score;
  final String? description;
  final List<ChatGarmentOutfit> garmentOutfits;

  ChatOutfit({
    required this.id,
    required this.name,
    this.score,
    this.description,
    required this.garmentOutfits,
  });

  factory ChatOutfit.fromJson(Map<String, dynamic> json) {
    return ChatOutfit(
      id: json['id'],
      name: json['name'] ?? '',
      score: json['score'],
      description: json['description'],
      garmentOutfits:
          (json['garmentOutfits'] as List<dynamic>?)
              ?.map((item) => ChatGarmentOutfit.fromJson(item))
              .toList() ??
          [],
    );
  }
}

/// Modelo para la relacion prenda-outfit en el chat
class ChatGarmentOutfit {
  final String id;
  final String garmentId;
  final String outfitId;
  final int order;
  final ChatGarment? garment;

  ChatGarmentOutfit({
    required this.id,
    required this.garmentId,
    required this.outfitId,
    required this.order,
    this.garment,
  });

  factory ChatGarmentOutfit.fromJson(Map<String, dynamic> json) {
    return ChatGarmentOutfit(
      id: json['id'],
      garmentId: json['garmentId'] ?? '',
      outfitId: json['outfitId'] ?? '',
      order: json['order'] ?? 0,
      garment: json['garment'] != null
          ? ChatGarment.fromJson(json['garment'])
          : null,
    );
  }
}

/// Modelo para una prenda en el chat
class ChatGarment {
  final String id;
  final String? name;
  final String? description;
  final String? category;
  final String? path;
  final String? pathLocal;
  final String? closetId;

  ChatGarment({
    required this.id,
    this.name,
    this.description,
    this.category,
    this.path,
    this.pathLocal,
    this.closetId,
  });

  factory ChatGarment.fromJson(Map<String, dynamic> json) {
    return ChatGarment(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      path: json['path'],
      pathLocal: json['pathLocal'],
      closetId: json['closetId'],
    );
  }
}

/// Modelo para el peinado recomendado
class RecommendedHairstyle {
  final String id;
  final String description;
  final String? imageUrl;
  final String? gender;

  RecommendedHairstyle({
    required this.id,
    required this.description,
    this.imageUrl,
    this.gender,
  });

  factory RecommendedHairstyle.fromJson(Map<String, dynamic> json) {
    return RecommendedHairstyle(
      id: json['id'],
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      gender: json['gender'],
    );
  }
}
