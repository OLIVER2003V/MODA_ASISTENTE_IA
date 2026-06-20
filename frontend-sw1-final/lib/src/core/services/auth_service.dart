import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/auth/data/models/auth_response_model.dart';
import '../../features/auth/data/models/user_model.dart';
import '../config/api_config.dart';
import 'storage_service.dart';
import '../utils/jwt_utils.dart';

class AuthService {
  static String get baseUrl => '${ApiConfig.baseUrl}/auth';

  // Login
  static Future<AuthResponse> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'email': email, 'password': password}),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Tiempo de espera agotado. Verificá tu conexión.'),
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(json.decode(response.body));
        // Guardar token e información del usuario
        await StorageService.saveToken(authResponse.accessToken);
        await StorageService.saveUser(authResponse.user);
        // Guardar preferencia de "Remember Me"
        await StorageService.saveRememberMe(rememberMe);
        return authResponse;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Credenciales incorrectas. Verificá tu email y contraseña.');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Error al iniciar sesión');
      }
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Error de conexión. Verificá que el servidor esté activo.');
    }
  }

  // Register
  static Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name, 'email': email, 'password': password}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(json.decode(response.body));
        // Guardar token e información del usuario
        await StorageService.saveToken(authResponse.accessToken);
        await StorageService.saveUser(authResponse.user);
        // Usuarios nuevos mantienen sesión por defecto
        await StorageService.saveRememberMe(true);
        return authResponse;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Error al registrarse');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Get Profile
  static Future<User> getProfile({bool forceRefresh = false}) async {
    try {
      // Si no se fuerza refresh, intentar obtener usuario guardado localmente
      if (!forceRefresh) {
        final cachedUser = await StorageService.getUser();
        if (cachedUser != null) {
          // Verificar si el token sigue siendo válido antes de retornar cache
          final token = await StorageService.getToken();
          if (token != null && JwtUtils.isTokenValid(token)) {
            // Intentar actualizar en segundo plano sin bloquear
            _refreshProfileInBackground();
            return cachedUser;
          }
        }
      }

      // Si no hay cache o se fuerza refresh, obtener del servidor
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      // Debug: verificar estado del token
      final isExpired = JwtUtils.isTokenExpired(token);
      final expDate = JwtUtils.getExpirationDate(token);
      print('Token expirado: $isExpired');
      print('Fecha expiración: $expDate');
      print('Fecha actual: ${DateTime.now()}');

      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(json.decode(response.body));
        // Guardar usuario actualizado
        await StorageService.saveUser(user);
        return user;
      } else if (response.statusCode == 401) {
        // Token inválido o expirado
        await StorageService.clearAll();
        throw Exception('Sesión expirada');
      } else {
        throw Exception('Error al obtener perfil');
      }
    } catch (e) {
      // Si falla la petición pero tenemos usuario cacheado, retornarlo
      if (!forceRefresh) {
        final cachedUser = await StorageService.getUser();
        if (cachedUser != null) {
          return cachedUser;
        }
      }
      throw Exception('Error de conexión: $e');
    }
  }

  // Actualizar perfil en segundo plano
  static void _refreshProfileInBackground() {
    // Ejecutar en segundo plano sin esperar
    getProfile(forceRefresh: true).catchError((_) {
      // Ignorar errores en background refresh
    });
  }

  // Logout
  static Future<void> logout() async {
    await StorageService.clearAll();
  }

  // Verificar si está autenticado (optimizado con validación local primero)
  static Future<bool> isAuthenticated({bool verifyWithServer = false}) async {
    try {
      // 1. Verificar si existe token
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      // 2. Validar token localmente (formato y expiración si es JWT)
      if (!JwtUtils.isTokenValid(token)) {
        // Token expirado o inválido, limpiar
        await StorageService.clearAll();
        return false;
      }

      // 3. Si se requiere verificación con servidor, hacer petición HTTP
      if (verifyWithServer) {
        try {
          await getProfile(forceRefresh: true);
          return true;
        } catch (e) {
          // Si falla la verificación con servidor pero el token es válido localmente,
          // aún consideramos autenticado (útil para modo offline)
          return true;
        }
      }

      // 4. Si no se requiere verificación con servidor, retornar true
      // (el token existe y es válido localmente)
      return true;
    } catch (e) {
      return false;
    }
  }

  // Obtener usuario desde cache (rápido, sin petición HTTP)
  static Future<User?> getCachedUser() async {
    return await StorageService.getUser();
  }
}
