import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../features/wardrobe/data/models/closet_response_model.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

class ClosetService {
  static String get baseUrl => ApiConfig.baseUrl;

  /// Obtener el closet del usuario con sus prendas
  /// Retorna null si el usuario no tiene closet (404)
  static Future<ClosetResponse?> getClosetByUserId(String userId) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/closet/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      // El backend retorna HTTP 200 pero con error interno cuando no hay closet
      if (data is Map<String, dynamic>) {
        // Verificar si es un error interno (status 404 en el body)
        if (data['status'] == 404 || data['name'] == 'HttpException') {
          return null;
        }
        // Verificar que tenga la estructura esperada de closet
        if (data.containsKey('closet') && data.containsKey('garments')) {
          return ClosetResponse.fromJson(data);
        }
      }

      if (response.statusCode == 404) {
        return null;
      }

      if (response.statusCode != 200) {
        throw Exception(data['message'] ?? 'Error al obtener el armario');
      }

      return null;
    } catch (e) {
      if (e.toString().contains('404') ||
          e.toString().contains('No encontrado') ||
          e.toString().contains('No closets found')) {
        return null;
      }
      rethrow;
    }
  }

  /// Crear un closet con múltiples prendas
  /// [closetName] - Nombre del closet
  /// [closetDescription] - Descripción opcional del closet
  /// [imageFiles] - Lista de archivos de imagen
  /// [pathLocals] - Lista de rutas locales (en el mismo orden que los archivos)
  static Future<void> createClosetWithGarments({
    required String closetName,
    String? closetDescription,
    required List<File> imageFiles,
    required List<String> pathLocals,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      // Debug: verificar token
      print('Token obtenido: ${token.substring(0, 20)}...');

      final uri = Uri.parse('$baseUrl/garment/bulk');
      final request = http.MultipartRequest('POST', uri);

      // Headers - asegurar formato correcto
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Campos del formulario
      request.fields['closetName'] = closetName;
      if (closetDescription != null && closetDescription.isNotEmpty) {
        request.fields['closetDescription'] = closetDescription;
      }

      // Agregar pathLocals como campos individuales con índice
      for (int i = 0; i < pathLocals.length; i++) {
        request.fields['pathLocals[$i]'] = pathLocals[i];
      }

      // Agregar archivos
      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        // Usar Uri.file para obtener el nombre del archivo (funciona en Windows y Unix)
        final filename = Uri.file(file.path).pathSegments.last;

        final multipartFile = await http.MultipartFile.fromPath(
          'files',
          file.path,
          filename: filename,
        );
        request.files.add(multipartFile);
      }

      print('Enviando request a: $uri');
      print('Headers: ${request.headers}');
      print('Fields: ${request.fields}');
      print('Files count: ${request.files.length}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Error al crear el armario');
      }
    } catch (e) {
      print('Error en createClosetWithGarments: $e');
      throw Exception('Error al crear armario: $e');
    }
  }

  /// Agregar una prenda individual a un closet existente
  static Future<void> addGarment({
    required String closetId,
    required File imageFile,
    required String pathLocal,
    String? name,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final uri = Uri.parse('$baseUrl/garment');
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['closetId'] = closetId;
      request.fields['pathLocal'] = pathLocal;
      if (name != null && name.isNotEmpty) {
        request.fields['name'] = name;
      }

      final filename = Uri.file(imageFile.path).pathSegments.last;
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: filename,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Error al agregar prenda');
      }
    } catch (e) {
      throw Exception('Error al agregar prenda: $e');
    }
  }

  /// Eliminar una prenda
  static Future<void> deleteGarment(String garmentId) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/garment/$garmentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Error al eliminar prenda');
      }
    } catch (e) {
      throw Exception('Error al eliminar prenda: $e');
    }
  }

  /// Actualizar nombre de una prenda
  static Future<void> updateGarment(String garmentId, {String? name}) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');

    final response = await http.patch(
      Uri.parse('$baseUrl/garment/$garmentId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({if (name != null) 'name': name}),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Error al actualizar prenda');
    }
  }

  /// Actualizar nombre y/o descripción del closet
  static Future<void> updateCloset({
    required String closetId,
    String? name,
    String? description,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;

      final response = await http.patch(
        Uri.parse('$baseUrl/closet/$closetId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Error al actualizar armario');
      }
    } catch (e) {
      throw Exception('Error al actualizar armario: $e');
    }
  }

  /// Eliminar un closet completo
  static Future<void> deleteCloset(String closetId) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/closet/$closetId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Error al eliminar armario');
      }
    } catch (e) {
      throw Exception('Error al eliminar armario: $e');
    }
  }
}
