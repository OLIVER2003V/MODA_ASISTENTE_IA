import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

class SelfieAnalysisResult {
  final String? faceType;
  final String? skinTone;
  final String? skinSubtone;
  final String? hairColor;
  final String? hairType;
  final String? eyeColor;
  final String? gender;
  final String? bodyType;
  final Map<String, int> confidence;

  SelfieAnalysisResult({
    this.faceType,
    this.skinTone,
    this.skinSubtone,
    this.hairColor,
    this.hairType,
    this.eyeColor,
    this.gender,
    this.bodyType,
    required this.confidence,
  });

  factory SelfieAnalysisResult.fromJson(Map<String, dynamic> json) {
    final raw = json['confidence'];
    final conf = <String, int>{};
    if (raw is Map) {
      raw.forEach((k, v) => conf[k.toString()] = (v as num).round());
    }
    return SelfieAnalysisResult(
      faceType:    json['faceType']    as String?,
      skinTone:    json['skinTone']    as String?,
      skinSubtone: json['skinSubtone'] as String?,
      hairColor:   json['hairColor']   as String?,
      hairType:    json['hairType']    as String?,
      eyeColor:    json['eyeColor']    as String?,
      gender:      json['gender']      as String?,
      bodyType:    json['bodyType']    as String?,
      confidence:  conf,
    );
  }

  int conf(String field) => confidence[field] ?? 0;
}

class SelfieAnalysisService {
  static Future<SelfieAnalysisResult> analyze(
    File photo, {
    bool isFullBody = false,
  }) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/ai/analyze-selfie'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['isFullBody'] = isFullBody.toString();
    request.files.add(await http.MultipartFile.fromPath('file', photo.path));

    final streamed = await request.send().timeout(const Duration(seconds: 90));
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return SelfieAnalysisResult.fromJson(
        json.decode(res.body) as Map<String, dynamic>,
      );
    }
    final err = json.decode(res.body) as Map<String, dynamic>;
    throw Exception(err['message'] ?? 'Error al analizar la imagen');
  }
}
