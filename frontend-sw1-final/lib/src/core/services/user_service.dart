import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

// ── Modelos ───────────────────────────────────────────────────────────────────

class UserSuggestion {
  final String id;
  final String name;
  final String? profilePhoto;
  final String? avatarStyle;
  final int followerCount;
  final int postCount;
  bool isFollowing;

  UserSuggestion({
    required this.id,
    required this.name,
    this.profilePhoto,
    this.avatarStyle,
    required this.followerCount,
    required this.postCount,
    required this.isFollowing,
  });

  factory UserSuggestion.fromJson(Map<String, dynamic> j) => UserSuggestion(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Usuario',
        profilePhoto: j['profilePhoto'] as String?,
        avatarStyle: j['avatarStyle'] as String?,
        followerCount: (j['followerCount'] as num?)?.toInt() ?? 0,
        postCount: (j['postCount'] as num?)?.toInt() ?? 0,
        isFollowing: j['isFollowing'] as bool? ?? false,
      );

  String get displayName => name.isNotEmpty ? name : 'Usuario';

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String? get avatarUrl {
    if (profilePhoto != null && profilePhoto!.isNotEmpty) return profilePhoto;
    if (avatarStyle != null && avatarStyle!.isNotEmpty) {
      return 'https://api.dicebear.com/9.x/$avatarStyle/png?seed=$id';
    }
    return null;
  }
}

class PublicProfile {
  final String id;
  final String name;
  final String? profilePhoto;
  final String? avatarStyle;
  int followerCount;
  final int followingCount;
  final int postCount;
  bool isFollowing;

  PublicProfile({
    required this.id,
    required this.name,
    this.profilePhoto,
    this.avatarStyle,
    required this.followerCount,
    required this.followingCount,
    required this.postCount,
    required this.isFollowing,
  });

  factory PublicProfile.fromJson(Map<String, dynamic> j) => PublicProfile(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Usuario',
        profilePhoto: j['profilePhoto'] as String?,
        avatarStyle: j['avatarStyle'] as String?,
        followerCount: (j['followerCount'] as num?)?.toInt() ?? 0,
        followingCount: (j['followingCount'] as num?)?.toInt() ?? 0,
        postCount: (j['postCount'] as num?)?.toInt() ?? 0,
        isFollowing: j['isFollowing'] as bool? ?? false,
      );

  String get displayName => name.isNotEmpty ? name : 'Usuario';

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String? get avatarUrl {
    if (profilePhoto != null && profilePhoto!.isNotEmpty) return profilePhoto;
    if (avatarStyle != null && avatarStyle!.isNotEmpty) {
      return 'https://api.dicebear.com/9.x/$avatarStyle/png?seed=$id';
    }
    return null;
  }
}

class FollowUser {
  final String id;
  final String name;
  final String? profilePhoto;
  final String? avatarStyle;

  FollowUser({
    required this.id,
    required this.name,
    this.profilePhoto,
    this.avatarStyle,
  });

  factory FollowUser.fromJson(Map<String, dynamic> j) => FollowUser(
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

  String? get avatarUrl {
    if (profilePhoto != null && profilePhoto!.isNotEmpty) return profilePhoto;
    if (avatarStyle != null && avatarStyle!.isNotEmpty) {
      return 'https://api.dicebear.com/9.x/$avatarStyle/png?seed=$id';
    }
    return null;
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

class UserService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, String>> get _authHeaders async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  // ── FCM ───────────────────────────────────────────────────────────────────

  static Future<void> registerFcmToken(String fcmToken) async {
    try {
      final user = await StorageService.getUser();
      if (user == null) throw Exception('No hay usuario autenticado');
      final response = await http
          .patch(
            Uri.parse('$baseUrl/users/register-fcm/${user.id}'),
            headers: await _authHeaders,
            body: json.encode({'fcmToken': fcmToken}),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Error al registrar FCM token');
      }
    } catch (e) {
      throw Exception('Error al registrar FCM token: $e');
    }
  }

  // ── Sugerencias ───────────────────────────────────────────────────────────

  static Future<List<UserSuggestion>> getSuggestions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/suggestions'),
      headers: await _authHeaders,
    );
    if (response.statusCode != 200) {
      throw Exception('Error al obtener sugerencias');
    }
    final data = json.decode(response.body);
    final list = data is List ? data : (data['users'] as List? ?? []);
    return list.map((e) => UserSuggestion.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Búsqueda ──────────────────────────────────────────────────────────────

  static Future<List<UserSuggestion>> searchUsers(String q) async {
    if (q.trim().isEmpty) return [];
    final uri = Uri.parse('$baseUrl/users/search').replace(queryParameters: {'q': q.trim()});
    final response = await http.get(uri, headers: await _authHeaders);
    if (response.statusCode != 200) {
      throw Exception('Error en búsqueda');
    }
    final data = json.decode(response.body);
    final list = data is List ? data : (data['users'] as List? ?? []);
    return list.map((e) => UserSuggestion.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Follow / Unfollow ─────────────────────────────────────────────────────

  static Future<void> follow(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/follow'),
      headers: await _authHeaders,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Error al seguir usuario');
    }
  }

  static Future<void> unfollow(String userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$userId/follow'),
      headers: await _authHeaders,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Error al dejar de seguir');
    }
  }

  // ── Perfil público ────────────────────────────────────────────────────────

  static Future<PublicProfile> getPublicProfile(String userId) async {
    final headers = await _authHeaders;
    final uri = Uri.parse('$baseUrl/users/$userId/public-profile');
    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Error al obtener perfil');
    }
    return PublicProfile.fromJson(json.decode(response.body) as Map<String, dynamic>);
  }

  // ── Seguidores / Siguiendo ────────────────────────────────────────────────

  static Future<List<FollowUser>> getFollowers(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/followers'),
      headers: await _authHeaders,
    );
    if (response.statusCode != 200) return [];
    final data = json.decode(response.body);
    final list = data is List ? data : (data['followers'] as List? ?? []);
    return list.map((e) => FollowUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<FollowUser>> getFollowing(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/following'),
      headers: await _authHeaders,
    );
    if (response.statusCode != 200) return [];
    final data = json.decode(response.body);
    final list = data is List ? data : (data['following'] as List? ?? []);
    return list.map((e) => FollowUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Editar perfil ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> updateName(String name) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/users/profile'),
      headers: await _authHeaders,
      body: json.encode({'name': name}),
    );
    if (res.statusCode != 200) {
      final err = json.decode(res.body);
      throw Exception(err['message'] ?? 'Error al actualizar nombre');
    }
    return json.decode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> uploadProfilePhoto(File imageFile) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final uri = Uri.parse('$baseUrl/users/photo');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token';

    final filename = imageFile.path.split('/').last.split('\\').last;
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
      filename: filename,
    ));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200 && res.statusCode != 201) {
      final err = json.decode(res.body);
      throw Exception(err['message'] ?? 'Error al subir foto');
    }
    return json.decode(res.body) as Map<String, dynamic>;
  }

  static Future<void> deleteProfilePhoto() async {
    final res = await http.delete(
      Uri.parse('$baseUrl/users/photo'),
      headers: await _authHeaders,
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      final err = json.decode(res.body);
      throw Exception(err['message'] ?? 'Error al eliminar foto');
    }
  }

  static Future<Map<String, dynamic>> setAvatar(String style) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/users/avatar'),
      headers: await _authHeaders,
      body: json.encode({'style': style}),
    );
    if (res.statusCode != 200) {
      final err = json.decode(res.body);
      throw Exception(err['message'] ?? 'Error al cambiar avatar');
    }
    return json.decode(res.body) as Map<String, dynamic>;
  }
}
