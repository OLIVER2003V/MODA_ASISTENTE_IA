import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

// ── Models ───────────────────────────────────────────────────────────────────

class SocialBrandingImagen {
  final String titulo;
  final List<String> paleta;
  final List<String> keywords;
  final List<String> tips;

  const SocialBrandingImagen({
    required this.titulo,
    required this.paleta,
    required this.keywords,
    required this.tips,
  });

  factory SocialBrandingImagen.fromJson(Map<String, dynamic> json) =>
      SocialBrandingImagen(
        titulo: json['titulo'] as String? ?? '',
        paleta: List<String>.from(json['paleta'] as List? ?? []),
        keywords: List<String>.from(json['keywords'] as List? ?? []),
        tips: List<String>.from(json['tips'] as List? ?? []),
      );
}

class SocialBrandingContenido {
  final List<String> tipos;
  final String frecuencia;
  final List<String> ideas;

  const SocialBrandingContenido({
    required this.tipos,
    required this.frecuencia,
    required this.ideas,
  });

  factory SocialBrandingContenido.fromJson(Map<String, dynamic> json) =>
      SocialBrandingContenido(
        tipos: List<String>.from(json['tipos'] as List? ?? []),
        frecuencia: json['frecuencia'] as String? ?? '',
        ideas: List<String>.from(json['ideas'] as List? ?? []),
      );
}

class SocialBrandingHorarios {
  final List<String> mejores;
  final String evitar;

  const SocialBrandingHorarios({required this.mejores, required this.evitar});

  factory SocialBrandingHorarios.fromJson(Map<String, dynamic> json) =>
      SocialBrandingHorarios(
        mejores: List<String>.from(json['mejores'] as List? ?? []),
        evitar: json['evitar'] as String? ?? '',
      );
}

class SocialBrandingTono {
  final String titulo;
  final String descripcion;
  final List<String> tips;

  const SocialBrandingTono({
    required this.titulo,
    required this.descripcion,
    required this.tips,
  });

  factory SocialBrandingTono.fromJson(Map<String, dynamic> json) =>
      SocialBrandingTono(
        titulo: json['titulo'] as String? ?? '',
        descripcion: json['descripcion'] as String? ?? '',
        tips: List<String>.from(json['tips'] as List? ?? []),
      );
}

class CaptionSet {
  final String idea;
  final String corta;
  final String media;
  final String larga;

  const CaptionSet({
    required this.idea,
    required this.corta,
    required this.media,
    required this.larga,
  });

  factory CaptionSet.fromJson(Map<String, dynamic> json) => CaptionSet(
        idea:  json['idea']  as String? ?? '',
        corta: json['corta'] as String? ?? '',
        media: json['media'] as String? ?? '',
        larga: json['larga'] as String? ?? '',
      );
}

class CalendarDay {
  final String day;
  final String type; // OUTFIT | PHOTO | TIP | REST
  final String hour;
  final String idea;

  const CalendarDay({
    required this.day,
    required this.type,
    required this.hour,
    required this.idea,
  });

  factory CalendarDay.fromJson(Map<String, dynamic> json) => CalendarDay(
        day:  json['day']  as String? ?? '',
        type: json['type'] as String? ?? 'REST',
        hour: json['hour'] as String? ?? '',
        idea: json['idea'] as String? ?? '',
      );

  bool get isRest => type == 'REST';
}

class SocialBrandingResult {
  final String network;
  final bool hasProfile;
  final SocialBrandingImagen imagen;
  final SocialBrandingContenido contenido;
  final SocialBrandingHorarios horarios;
  final List<String> hashtags;
  final SocialBrandingTono tono;
  final List<CaptionSet> captionTemplates;
  final List<CalendarDay> contentCalendar;
  final List<String> trendingSearches;
  final List<String> profileChecklist;

  const SocialBrandingResult({
    required this.network,
    required this.hasProfile,
    required this.imagen,
    required this.contenido,
    required this.horarios,
    required this.hashtags,
    required this.tono,
    required this.captionTemplates,
    required this.contentCalendar,
    required this.trendingSearches,
    required this.profileChecklist,
  });

  factory SocialBrandingResult.fromJson(Map<String, dynamic> json) =>
      SocialBrandingResult(
        network: json['network'] as String? ?? '',
        hasProfile: json['hasProfile'] as bool? ?? false,
        imagen: SocialBrandingImagen.fromJson(
            json['imagen'] as Map<String, dynamic>? ?? {}),
        contenido: SocialBrandingContenido.fromJson(
            json['contenido'] as Map<String, dynamic>? ?? {}),
        horarios: SocialBrandingHorarios.fromJson(
            json['horarios'] as Map<String, dynamic>? ?? {}),
        hashtags: List<String>.from(json['hashtags'] as List? ?? []),
        tono: SocialBrandingTono.fromJson(
            json['tono'] as Map<String, dynamic>? ?? {}),
        captionTemplates: (json['captionTemplates'] as List? ?? [])
            .map((e) => CaptionSet.fromJson(e as Map<String, dynamic>))
            .toList(),
        contentCalendar: (json['contentCalendar'] as List? ?? [])
            .map((e) => CalendarDay.fromJson(e as Map<String, dynamic>))
            .toList(),
        trendingSearches:
            List<String>.from(json['trendingSearches'] as List? ?? []),
        profileChecklist:
            List<String>.from(json['profileChecklist'] as List? ?? []),
      );
}

// ── Service ──────────────────────────────────────────────────────────────────

class SocialBrandingService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<SocialBrandingResult> getRecommendations(
    String network, {
    bool refresh = false,
  }) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final response = await http
        .post(
          Uri.parse('$baseUrl/social-branding/recommendations'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'network': network,
            if (refresh) 'refresh': true,
          }),
        )
        .timeout(
          const Duration(seconds: 60),
          onTimeout: () => throw Exception(
            'El servidor tardó demasiado. Intenta de nuevo.',
          ),
        );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return SocialBrandingResult.fromJson(data);
    } else {
      final error = json.decode(response.body);
      throw Exception(
        error['message'] ?? 'Error al obtener recomendaciones de branding',
      );
    }
  }
}
