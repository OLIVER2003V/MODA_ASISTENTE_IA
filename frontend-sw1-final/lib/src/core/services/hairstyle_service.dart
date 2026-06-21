import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

// ── Modelos ───────────────────────────────────────────────────────────────────

class HairstyleRecommendResult {
  final HairstyleItem recommended;
  final String explanation;
  final List<HairstyleItem> catalog;

  HairstyleRecommendResult({
    required this.recommended,
    required this.explanation,
    required this.catalog,
  });

  factory HairstyleRecommendResult.fromJson(Map<String, dynamic> j) =>
      HairstyleRecommendResult(
        recommended: HairstyleItem.fromJson(j['recommended'] as Map<String, dynamic>),
        explanation: j['explanation'] as String? ?? '',
        catalog: (j['catalog'] as List<dynamic>?)
                ?.map((e) => HairstyleItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class HairstyleItem {
  final String id;
  final String description;
  final String? imageUrl;
  final String? gender; // 'MALE' | 'FEMALE' | 'UNISEX' | null
  final DateTime? createdAt;

  HairstyleItem({
    required this.id,
    required this.description,
    this.imageUrl,
    this.gender,
    this.createdAt,
  });

  factory HairstyleItem.fromJson(Map<String, dynamic> j) => HairstyleItem(
        id: j['id'] as String,
        description: j['description'] as String? ?? '',
        imageUrl: j['imageUrl'] as String?,
        gender: j['gender'] as String?,
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'] as String)
            : null,
      );

  // Primera oración de la descripción (máx 70 chars)
  String get shortDescription {
    final first = description.split('.').first.trim();
    if (first.length <= 70) return first;
    return '${first.substring(0, 67)}…';
  }

  String get genderLabel {
    switch (gender) {
      case 'MALE':
        return 'Masculino';
      case 'FEMALE':
        return 'Femenino';
      case 'UNISEX':
        return 'Unisex';
      default:
        return 'Unisex';
    }
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

class HairstyleService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, String>> get _authHeaders async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Obtiene el catálogo completo de peinados
  static Future<List<HairstyleItem>> getAll() async {
    final res = await http.get(
      Uri.parse('$baseUrl/hairstyle'),
      headers: await _authHeaders,
    );
    if (res.statusCode != 200) {
      final err = json.decode(res.body);
      throw Exception(err['message'] ?? 'Error al obtener peinados');
    }
    final list = json.decode(res.body) as List<dynamic>;
    return list
        .map((e) => HairstyleItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene los peinados marcados como favoritos del usuario
  static Future<List<HairstyleItem>> getFavorites() async {
    final res = await http.get(
      Uri.parse('$baseUrl/hairstyle/favorites'),
      headers: await _authHeaders,
    );
    if (res.statusCode != 200) {
      final err = json.decode(res.body);
      throw Exception(err['message'] ?? 'Error al obtener favoritos');
    }
    final list = json.decode(res.body) as List<dynamic>;
    return list
        .map((e) => HairstyleItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Agrega un peinado a favoritos
  static Future<void> addFavorite(String hairstyleId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/hairstyle/favorite/$hairstyleId'),
      headers: await _authHeaders,
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      final err = json.decode(res.body);
      throw Exception(err['message'] ?? 'Error al agregar favorito');
    }
  }

  /// Quita un peinado de favoritos
  static Future<void> removeFavorite(String hairstyleId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/hairstyle/favorite/$hairstyleId'),
      headers: await _authHeaders,
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      final err = json.decode(res.body);
      throw Exception(err['message'] ?? 'Error al quitar favorito');
    }
  }

  /// Sube imágenes al catálogo de peinados (solo Admin)
  static Future<List<HairstyleItem>> uploadHairstyles(
    List<File> files,
    String gender,
  ) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/hairstyle/upload'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['gender'] = gender;
    for (final file in files) {
      request.files.add(await http.MultipartFile.fromPath('files', file.path));
    }

    final streamed = await request.send().timeout(const Duration(minutes: 5));
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200 || res.statusCode == 201) {
      final list = json.decode(res.body) as List<dynamic>;
      return list
          .map((e) => HairstyleItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final err = json.decode(res.body);
    throw Exception(err['message'] ?? 'Error al subir peinados');
  }

  /// Elimina un peinado del catálogo (solo Admin)
  static Future<void> deleteHairstyle(String id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/hairstyle/$id'),
      headers: await _authHeaders,
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      final err = json.decode(res.body);
      throw Exception(err['message'] ?? 'Error al eliminar peinado');
    }
  }

  /// Recomienda peinados según foto del rostro (Premium)
  static Future<HairstyleRecommendResult> recommend(File imageFile) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/hairstyle/recommend'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return HairstyleRecommendResult.fromJson(
          json.decode(res.body) as Map<String, dynamic>);
    }
    final err = json.decode(res.body);
    throw Exception(err['message'] ?? 'Error al obtener recomendación');
  }

  /// Aplica un peinado del catálogo sobre una foto del rostro (Premium)
  static Future<String> tryOn(String hairstyleId, File imageFile) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/hairstyle/try-on'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['hairstyleId'] = hairstyleId;
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      return data['tryOnUrl'] as String;
    }
    final err = json.decode(res.body);
    throw Exception(err['message'] ?? 'Error en prueba virtual');
  }
}
