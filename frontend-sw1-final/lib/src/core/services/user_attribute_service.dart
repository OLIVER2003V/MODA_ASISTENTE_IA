import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../features/profile/data/models/user_attribute_model.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

class UserAttributeService {
  static String get baseUrl => '${ApiConfig.baseUrl}/user-attribute';

  // Enviar atributos del usuario
  static Future<void> saveUserAttributes(UserAttribute attributes) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(attributes.toJson()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Error al guardar atributos');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Actualizar atributos existentes
  static Future<UserAttribute> updateAttributes(
      String attributeId, Map<String, dynamic> data) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final response = await http.patch(
      Uri.parse('$baseUrl/$attributeId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return UserAttribute.fromJson(json.decode(response.body));
    }
    final error = json.decode(response.body);
    throw Exception(error['message'] ?? 'Error al actualizar atributos');
  }

  /// Sube foto de cuerpo completo para usar en try-on de outfits
  static Future<String> uploadBodyPhoto(File imageFile) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final uri = Uri.parse('$baseUrl/body-photo');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      return data['bodyPhotoUrl'] as String;
    }
    final err = json.decode(res.body);
    throw Exception(err['message'] ?? 'Error al subir foto de cuerpo');
  }

  /// Obtiene la URL pública de la foto de cuerpo del usuario autenticado
  static Future<String?> getBodyPhotoUrl() async {
    final token = await StorageService.getToken();
    if (token == null) return null;
    final res = await http.get(
      Uri.parse('$baseUrl/body-photo/url'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      if (data is String) return data;
      if (data is Map) return data['url'] as String?;
    }
    return null;
  }

  // Obtener atributos del usuario
  static Future<UserAttribute?> getUserAttributes(String userId) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        // Sin token, retornar null (irá al onboarding después del login)
        return null;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/by-user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserAttribute.fromJson(data);
      } else {
        // 404 u otro error = no hay atributos, retornar null
        return null;
      }
    } catch (e) {
      // Error de conexión o parsing, retornar null para no bloquear el flujo
      // El usuario irá al onboarding y podrá completar sus datos
      return null;
    }
  }
}
