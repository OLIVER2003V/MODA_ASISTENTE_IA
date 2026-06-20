import 'dart:convert';

/// Utilidad para trabajar con tokens JWT
class JwtUtils {
  /// Decodifica un token JWT y retorna el payload
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      // Decodificar el payload (segunda parte del JWT)
      final payload = parts[1];
      
      // Agregar padding si es necesario para base64
      String normalizedPayload = payload;
      final padding = 4 - (payload.length % 4);
      if (padding != 4) {
        normalizedPayload += '=' * padding;
      }

      final decoded = utf8.decode(base64Url.decode(normalizedPayload));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Verifica si un token JWT está expirado
  /// Retorna true si está expirado o si no se puede verificar
  static bool isTokenExpired(String token) {
    try {
      final payload = decodePayload(token);
      if (payload == null) return true;

      // Verificar si tiene campo 'exp' (expiration time)
      if (payload.containsKey('exp')) {
        final exp = payload['exp'];
        if (exp is int) {
          // 'exp' está en segundos desde epoch
          final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
          final now = DateTime.now();
          
          // Considerar expirado si falta menos de 1 minuto
          return now.isAfter(expirationDate.subtract(const Duration(minutes: 1)));
        }
      }

      // Si no tiene campo 'exp', asumimos que no está expirado
      // (puede ser un token que no expira o un token no-JWT)
      return false;
    } catch (e) {
      // Si hay error al decodificar, consideramos que está expirado
      return true;
    }
  }

  /// Verifica si un token JWT es válido (formato correcto y no expirado)
  static bool isTokenValid(String token) {
    if (token.isEmpty) return false;
    
    final payload = decodePayload(token);
    if (payload == null) return false;
    
    return !isTokenExpired(token);
  }

  /// Obtiene la fecha de expiración del token
  static DateTime? getExpirationDate(String token) {
    try {
      final payload = decodePayload(token);
      if (payload == null) return null;

      if (payload.containsKey('exp')) {
        final exp = payload['exp'];
        if (exp is int) {
          return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
