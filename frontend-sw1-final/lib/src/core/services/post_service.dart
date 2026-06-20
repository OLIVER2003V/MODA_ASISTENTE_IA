import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

// ── Constantes de reacciones ────────────────────────────────────────────────

const reactionEmojis = {
  'LIKE': '❤️',
  'LOVE': '😍',
  'FIRE': '🔥',
  'WOW': '😮',
};

const reactionLabels = {
  'LIKE': 'Me gusta',
  'LOVE': 'Me encanta',
  'FIRE': '¡Fuego!',
  'WOW': '¡Wow!',
};

const reactionTypes = ['LIKE', 'LOVE', 'FIRE', 'WOW'];

// ── Modelos ─────────────────────────────────────────────────────────────────

class PostUser {
  final String id;
  final String? name;
  final String? profilePhoto;
  final String? avatarStyle;

  PostUser({required this.id, this.name, this.profilePhoto, this.avatarStyle});

  factory PostUser.fromJson(Map<String, dynamic> json) => PostUser(
        id: json['id'] ?? '',
        name: json['name'],
        profilePhoto: json['profilePhoto'],
        avatarStyle: json['avatarStyle'],
      );

  String get displayName => name ?? 'Usuario';

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String? get avatarUrl {
    if (profilePhoto != null && profilePhoto!.isNotEmpty) return profilePhoto;
    if (avatarStyle != null && avatarStyle!.isNotEmpty) {
      return 'https://api.dicebear.com/9.x/$avatarStyle/svg?seed=${Uri.encodeComponent(id)}';
    }
    return null;
  }
}

class Post {
  final String id;
  final String postType;
  final String? outfitId;
  final String? imageUrl;
  final String? caption;
  final List<String> tags;
  final int reactionCount;
  final int commentCount;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PostUser? user;
  final PostOutfit? outfit;

  const Post({
    required this.id,
    required this.postType,
    this.outfitId,
    this.imageUrl,
    this.caption,
    this.tags = const [],
    required this.reactionCount,
    required this.commentCount,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.outfit,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'],
        postType: json['postType'] ?? 'OUTFIT',
        outfitId: json['outfitId'],
        imageUrl: json['imageUrl'],
        caption: json['caption'],
        tags: (json['tags'] as List<dynamic>?)
                ?.map((t) => t.toString())
                .toList() ??
            [],
        reactionCount: json['reactionCount'] ?? 0,
        commentCount: json['commentCount'] ?? 0,
        userId: json['userId'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        user: json['user'] != null ? PostUser.fromJson(json['user']) : null,
        outfit:
            json['outfit'] != null ? PostOutfit.fromJson(json['outfit']) : null,
      );

  Post copyWith({int? reactionCount, int? commentCount}) => Post(
        id: id,
        postType: postType,
        outfitId: outfitId,
        imageUrl: imageUrl,
        caption: caption,
        tags: tags,
        reactionCount: reactionCount ?? this.reactionCount,
        commentCount: commentCount ?? this.commentCount,
        userId: userId,
        createdAt: createdAt,
        updatedAt: updatedAt,
        user: user,
        outfit: outfit,
      );
}

class PostOutfit {
  final String id;
  final String? name;
  final int? score;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PostGarmentOutfit> garmentOutfits;

  PostOutfit({
    required this.id,
    this.name,
    this.score,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.garmentOutfits,
  });

  factory PostOutfit.fromJson(Map<String, dynamic> json) => PostOutfit(
        id: json['id'],
        name: json['name'],
        score: json['score'],
        description: json['description'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        garmentOutfits: (json['garmentOutfits'] as List<dynamic>?)
                ?.map((item) => PostGarmentOutfit.fromJson(item))
                .toList() ??
            [],
      );
}

class PostGarmentOutfit {
  final String id;
  final String garmentId;
  final String outfitId;
  final int order;
  final DateTime createdAt;
  final PostGarment? garment;

  PostGarmentOutfit({
    required this.id,
    required this.garmentId,
    required this.outfitId,
    required this.order,
    required this.createdAt,
    this.garment,
  });

  factory PostGarmentOutfit.fromJson(Map<String, dynamic> json) =>
      PostGarmentOutfit(
        id: json['id'],
        garmentId: json['garmentId'],
        outfitId: json['outfitId'],
        order: json['order'] ?? 0,
        createdAt: DateTime.parse(json['createdAt']),
        garment:
            json['garment'] != null ? PostGarment.fromJson(json['garment']) : null,
      );
}

class PostGarment {
  final String id;
  final String? name;
  final String? description;
  final String? category;
  final String? path;

  PostGarment({
    required this.id,
    this.name,
    this.description,
    this.category,
    this.path,
  });

  factory PostGarment.fromJson(Map<String, dynamic> json) => PostGarment(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        category: json['category'],
        path: json['path'],
      );
}

class Interaction {
  final String id;
  final String userId;
  final String postId;
  final String reactionType;
  final DateTime createdAt;
  final PostUser? user;

  Interaction({
    required this.id,
    required this.userId,
    required this.postId,
    required this.reactionType,
    required this.createdAt,
    this.user,
  });

  factory Interaction.fromJson(Map<String, dynamic> json) => Interaction(
        id: json['id'],
        userId: json['userId'],
        postId: json['postId'],
        reactionType: json['reactionType'] ?? 'LIKE',
        createdAt: DateTime.parse(json['createdAt']),
        user: json['user'] != null ? PostUser.fromJson(json['user']) : null,
      );
}

class Comment {
  final String id;
  final String content;
  final String userId;
  final String postId;
  final DateTime createdAt;
  final PostUser? user;

  Comment({
    required this.id,
    required this.content,
    required this.userId,
    required this.postId,
    required this.createdAt,
    this.user,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json['id'],
        content: json['content'],
        userId: json['userId'],
        postId: json['postId'],
        createdAt: DateTime.parse(json['createdAt']),
        user: json['user'] != null ? PostUser.fromJson(json['user']) : null,
      );
}

class SimpleOutfit {
  final String id;
  final String? name;
  final String? description;
  final int score;
  final List<PostGarmentOutfit> garmentOutfits;

  SimpleOutfit({
    required this.id,
    this.name,
    this.description,
    required this.score,
    required this.garmentOutfits,
  });

  factory SimpleOutfit.fromJson(Map<String, dynamic> json) => SimpleOutfit(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        score: json['score'] ?? 0,
        garmentOutfits: (json['garmentOutfits'] as List<dynamic>?)
                ?.map((item) => PostGarmentOutfit.fromJson(item))
                .toList() ??
            [],
      );
}

// ── Servicio ─────────────────────────────────────────────────────────────────

class PostService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No hay sesión activa');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Feed ──────────────────────────────────────────────────────────────────

  static Future<List<Post>> getPosts({int page = 1, int limit = 20}) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/post?page=$page&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final list = data is Map ? (data['posts'] as List<dynamic>?) : (data as List<dynamic>?);
        return list?.map((e) => Post.fromJson(e)).toList() ?? [];
      }
      throw Exception(json.decode(res.body)['message'] ?? 'Error al cargar posts');
    } catch (e) {
      throw Exception('$e');
    }
  }

  static Future<List<Post>> getPostsByUser(String userId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/post/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final list = data is List ? data : (data['posts'] as List<dynamic>?);
        return list?.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList() ?? [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<Post>> getFollowingFeed({int page = 1, int limit = 20}) async {
    try {
      final headers = await _authHeaders();
      final res = await http.get(
        Uri.parse('$baseUrl/post/feed/following?page=$page&limit=$limit'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final list = data is Map ? (data['posts'] as List<dynamic>?) : (data as List<dynamic>?);
        return list?.map((e) => Post.fromJson(e)).toList() ?? [];
      }
      throw Exception(json.decode(res.body)['message'] ?? 'Error al cargar feed');
    } catch (e) {
      throw Exception('$e');
    }
  }

  static Future<List<Post>> getPostsByTag(String tag, {int page = 1, int limit = 20}) async {
    final normalized = tag.startsWith('#') ? tag.substring(1) : tag;
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/post/tag/$normalized?page=$page&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final list = data is Map ? (data['posts'] as List<dynamic>?) : (data as List<dynamic>?);
        return list?.map((e) => Post.fromJson(e)).toList() ?? [];
      }
      throw Exception(json.decode(res.body)['message'] ?? 'Error al buscar por hashtag');
    } catch (e) {
      throw Exception('$e');
    }
  }

  // ── Mis reacciones (batch, una sola llamada) ───────────────────────────────

  static Future<Map<String, String>> getMyReactions() async {
    try {
      final headers = await _authHeaders();
      final res = await http.get(
        Uri.parse('$baseUrl/post/my/reactions'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List<dynamic>;
        return {
          for (final item in list)
            item['postId'].toString(): item['reactionType'].toString()
        };
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  // ── Reacciones ────────────────────────────────────────────────────────────

  static Future<void> reactToPost(String postId, {String reactionType = 'LIKE'}) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/post/$postId/react'),
      headers: headers,
      body: json.encode({'reactionType': reactionType}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(json.decode(res.body)['message'] ?? 'Error al reaccionar');
    }
  }

  static Future<void> removeReaction(String postId) async {
    final headers = await _authHeaders();
    final res = await http.delete(
      Uri.parse('$baseUrl/post/$postId/react'),
      headers: headers,
    );
    if (res.statusCode != 200) {
      throw Exception(json.decode(res.body)['message'] ?? 'Error al quitar reacción');
    }
  }

  static Future<List<Interaction>> getPostReactions(String postId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/post/$postId/reactions'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List<dynamic>;
        return list.map((e) => Interaction.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, int>> getReactionSummary(String postId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/post/$postId/reactions/summary'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List<dynamic>;
        return {for (final e in list) e['type'].toString(): (e['count'] as num).toInt()};
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  // ── Comentarios ───────────────────────────────────────────────────────────

  static Future<List<Comment>> getComments(String postId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/post/$postId/comments'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List<dynamic>;
        return list.map((e) => Comment.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Comment> createComment(String postId, String content) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/post/$postId/comment'),
      headers: headers,
      body: json.encode({'content': content}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return Comment.fromJson(json.decode(res.body));
    }
    throw Exception(json.decode(res.body)['message'] ?? 'Error al comentar');
  }

  static Future<void> deleteComment(String commentId) async {
    final headers = await _authHeaders();
    final res = await http.delete(
      Uri.parse('$baseUrl/post/comment/$commentId'),
      headers: headers,
    );
    if (res.statusCode != 200) {
      throw Exception(json.decode(res.body)['message'] ?? 'Error al eliminar comentario');
    }
  }

  // ── Crear posts ───────────────────────────────────────────────────────────

  static Future<Post> createOutfitPost(String outfitId, {String? caption}) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{'postType': 'OUTFIT', 'outfitId': outfitId};
    if (caption != null && caption.isNotEmpty) body['caption'] = caption;
    final res = await http.post(
      Uri.parse('$baseUrl/post'),
      headers: headers,
      body: json.encode(body),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return Post.fromJson(json.decode(res.body));
    }
    throw Exception(json.decode(res.body)['message'] ?? 'Error al publicar');
  }

  static Future<Post> createPhotoPost(String imageUrl, {String? caption}) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{'postType': 'PHOTO', 'imageUrl': imageUrl};
    if (caption != null && caption.isNotEmpty) body['caption'] = caption;
    final res = await http.post(
      Uri.parse('$baseUrl/post'),
      headers: headers,
      body: json.encode(body),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return Post.fromJson(json.decode(res.body));
    }
    throw Exception(json.decode(res.body)['message'] ?? 'Error al publicar');
  }

  static Future<Post> createTipPost(String caption) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/post'),
      headers: headers,
      body: json.encode({'postType': 'TIP', 'caption': caption}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return Post.fromJson(json.decode(res.body));
    }
    throw Exception(json.decode(res.body)['message'] ?? 'Error al publicar');
  }

  static Future<String> uploadPostImage(File file) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No hay sesión activa');
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/post/upload-image'));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return json.decode(res.body)['imageUrl'] as String;
    }
    throw Exception(json.decode(res.body)['message'] ?? 'Error al subir imagen');
  }

  static Future<void> deletePost(String postId) async {
    final headers = await _authHeaders();
    final res = await http.delete(
      Uri.parse('$baseUrl/post/$postId'),
      headers: headers,
    );
    if (res.statusCode != 200) {
      throw Exception(json.decode(res.body)['message'] ?? 'Error al eliminar post');
    }
  }

  // ── Outfits del usuario (para publicar) ──────────────────────────────────

  static Future<List<SimpleOutfit>> getUserOutfits(String userId) async {
    try {
      final headers = await _authHeaders();
      final res = await http.get(
        Uri.parse('$baseUrl/outfit/user/$userId'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List<dynamic>;
        return list.map((e) => SimpleOutfit.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
