import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

class OutfitService {
  static String get baseUrl => ApiConfig.baseUrl;

  /// Genera un outfit recomendado por IA
  /// [userId] - ID del usuario
  /// [event] - Tipo de evento (ej: "cena formal", "reunión de trabajo")
  /// [weather] - Clima (ej: "templado", "frío", "caluroso")
  static Future<OutfitGenerationResponse> generateOutfit({
    required String userId,
    required String event,
    required String weather,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/ai/generate-outfit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'userId': userId,
          'event': event,
          'weather': weather,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return OutfitGenerationResponse.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Error al generar outfit');
      }
    } catch (e) {
      throw Exception('Error al generar outfit: $e');
    }
  }

  /// Devuelve todos los outfits guardados de un usuario
  static Future<List<SavedOutfit>> getUserOutfits(String userId) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');
    final res = await http.get(
      Uri.parse('$baseUrl/outfit/user/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      final err = json.decode(res.body);
      throw Exception(err['message'] ?? 'Error al obtener outfits');
    }
    final data = json.decode(res.body);
    final List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map) {
      list = (data['outfits'] ?? data['data'] ?? data['items'] ?? []) as List<dynamic>;
    } else {
      list = [];
    }
    return list
        .map((e) => SavedOutfit.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Crea un outfit manualmente seleccionando prendas
  static Future<SavedOutfit> createManualOutfit({
    required String name,
    required List<String> garmentIds,
  }) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');
    final res = await http.post(
      Uri.parse('$baseUrl/outfit/manual'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'name': name, 'garmentIds': garmentIds}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = json.decode(res.body);
      final outfitMap = data is Map<String, dynamic>
          ? data
          : (data['outfit'] ?? data['data']) as Map<String, dynamic>;
      return SavedOutfit.fromJson(outfitMap);
    }
    final err = json.decode(res.body);
    throw Exception(err['message'] ?? 'Error al crear outfit');
  }

  /// Genera imagen de try-on realista para un outfit (usa caché si ya existe)
  static Future<String> generateTryOn(String outfitId) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');
    final res = await http.post(
      Uri.parse('$baseUrl/outfit/$outfitId/try-on'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(minutes: 3));
    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      return data['tryOnImageUrl'] as String;
    }
    final err = json.decode(res.body);
    throw Exception(err['message'] ?? 'Error al generar try-on');
  }

  /// Fuerza regenerar la imagen de try-on (ignora caché)
  static Future<String> regenerateTryOn(String outfitId) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');
    final res = await http.post(
      Uri.parse('$baseUrl/outfit/$outfitId/try-on/regenerate'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(minutes: 3));
    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      return data['tryOnImageUrl'] as String;
    }
    final err = json.decode(res.body);
    throw Exception(err['message'] ?? 'Error al regenerar try-on');
  }

  /// Elimina un outfit por ID
  static Future<void> deleteOutfit(String outfitId) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');
    final res = await http.delete(
      Uri.parse('$baseUrl/outfit/$outfitId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      final err = json.decode(res.body);
      throw Exception(err['message'] ?? 'Error al eliminar outfit');
    }
  }

  /// Dispara el reentrenamiento del modelo de compatibilidad en el Python service
  static Future<RetrainingMetrics> retrainModel() async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');
    final res = await http.post(
      Uri.parse('$baseUrl/ai/retrain'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(minutes: 3));
    if (res.statusCode == 200 || res.statusCode == 201) {
      return RetrainingMetrics.fromJson(
          json.decode(res.body) as Map<String, dynamic>);
    }
    final err = json.decode(res.body);
    throw Exception(err['message'] ?? 'Error al reentrenar el modelo');
  }

  /// Obtiene las prendas de un outfit específico
  /// [outfitId] - ID del outfit
  static Future<List<Garment>> getGarmentsByOutfitId(String outfitId) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/garment/$outfitId/outfit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Garment.fromJson(item)).toList();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Error al obtener prendas');
      }
    } catch (e) {
      throw Exception('Error al obtener prendas: $e');
    }
  }
}

/// Modelo para la respuesta de generación de outfit
class OutfitGenerationResponse {
  final bool success;
  final GeneratedOutfit outfit;
  final AiSuggestion? aiSuggestion;

  OutfitGenerationResponse({
    required this.success,
    required this.outfit,
    this.aiSuggestion,
  });

  factory OutfitGenerationResponse.fromJson(Map<String, dynamic> json) {
    return OutfitGenerationResponse(
      success: json['success'] ?? false,
      outfit: GeneratedOutfit.fromJson(json['outfit']),
      aiSuggestion: json['aiSuggestion'] != null
          ? AiSuggestion.fromJson(json['aiSuggestion'])
          : null,
    );
  }
}

/// Modelo para el outfit generado
class GeneratedOutfit {
  final String id;
  final String name;
  final String? description;
  final List<GarmentOutfit> garmentOutfits;

  GeneratedOutfit({
    required this.id,
    required this.name,
    this.description,
    required this.garmentOutfits,
  });

  factory GeneratedOutfit.fromJson(Map<String, dynamic> json) {
    return GeneratedOutfit(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      garmentOutfits: (json['garmentOutfits'] as List<dynamic>?)
              ?.map((item) => GarmentOutfit.fromJson(item))
              .toList() ??
          [],
    );
  }
}

/// Modelo para la relación prenda-outfit
class GarmentOutfit {
  final int order;
  final Garment garment;

  GarmentOutfit({
    required this.order,
    required this.garment,
  });

  factory GarmentOutfit.fromJson(Map<String, dynamic> json) {
    return GarmentOutfit(
      order: json['order'] ?? 0,
      garment: Garment.fromJson(json['garment']),
    );
  }
}

/// Modelo para una prenda
class Garment {
  final String id;
  final String? name;
  final String? path;
  final String? pathLocal;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? closetId;

  Garment({
    required this.id,
    this.name,
    this.path,
    this.pathLocal,
    this.createdAt,
    this.updatedAt,
    this.closetId,
  });

  factory Garment.fromJson(Map<String, dynamic> json) {
    return Garment(
      id: json['id'],
      name: json['name'],
      path: json['path'],
      pathLocal: json['pathLocal'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      closetId: json['closetId'],
    );
  }
}

/// Modelo para la sugerencia de IA
class AiSuggestion {
  final String? reasoning;
  final String? tips;
  final Map<String, dynamic>? raw;

  AiSuggestion({
    this.reasoning,
    this.tips,
    this.raw,
  });

  factory AiSuggestion.fromJson(Map<String, dynamic> json) {
    return AiSuggestion(
      reasoning: json['reasoning'],
      tips: json['tips'],
      raw: json,
    );
  }
}

/// Outfit guardado en el historial del usuario
class SavedOutfit {
  final String id;
  final String? name;
  final String? description;
  final int score;
  final String? tryOnImageUrl;
  final DateTime createdAt;
  final List<GarmentOutfit> garmentOutfits;

  SavedOutfit({
    required this.id,
    this.name,
    this.description,
    required this.score,
    this.tryOnImageUrl,
    required this.createdAt,
    required this.garmentOutfits,
  });

  factory SavedOutfit.fromJson(Map<String, dynamic> json) {
    return SavedOutfit(
      id: json['id'] as String,
      name: json['name'] as String?,
      description: json['description'] as String?,
      score: (json['score'] as num?)?.toInt() ?? 0,
      tryOnImageUrl: json['tryOnImageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      garmentOutfits: (json['garmentOutfits'] as List<dynamic>?)
              ?.map((e) => GarmentOutfit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class RetrainingMetrics {
  final double accuracy;
  final double f1Score;
  final double aucRoc;
  final int nTrain;
  final int nTest;
  final bool clipUsed;

  const RetrainingMetrics({
    required this.accuracy,
    required this.f1Score,
    required this.aucRoc,
    required this.nTrain,
    required this.nTest,
    required this.clipUsed,
  });

  factory RetrainingMetrics.fromJson(Map<String, dynamic> json) {
    final metrics = json['metrics'] as Map<String, dynamic>? ?? json;
    return RetrainingMetrics(
      accuracy: (metrics['accuracy'] as num).toDouble(),
      f1Score: (metrics['f1_score'] as num).toDouble(),
      aucRoc: (metrics['auc_roc'] as num).toDouble(),
      nTrain: (metrics['n_train'] as num).toInt(),
      nTest: (metrics['n_test'] as num).toInt(),
      clipUsed: metrics['clip_used'] as bool? ?? false,
    );
  }
}
