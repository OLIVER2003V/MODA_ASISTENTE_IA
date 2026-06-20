import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

class VirtualTryOnService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<String> tryOn(String garmentId, File personPhoto) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/garment/$garmentId/try-on'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('photo', personPhoto.path));

    final streamed = await request.send().timeout(const Duration(minutes: 2));
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      return data['tryOnUrl'] as String;
    }
    final err = json.decode(res.body) as Map<String, dynamic>;
    throw Exception(err['message'] ?? 'Error en prueba virtual de ropa');
  }
}
