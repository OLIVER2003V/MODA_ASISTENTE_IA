/// Configuración centralizada de la API
class ApiConfig {
  /// URL base de la API
  /// Cambiá la IP por la de tu PC en la red local (ipconfig → IPv4)
  /// - Emulador Android : http://10.0.2.2:3000/api
  /// - Dispositivo físico: http://<IP_LOCAL>:3000/api   ← estás aquí
  /// - Producción       : https://tu-dominio.com/api
  static const String baseUrl = 'http://192.168.100.148:3000/api';

  /// Clave pública de Stripe (pk_test_... o pk_live_...)
  /// Obtenerla en https://dashboard.stripe.com/apikeys
  static const String stripePublishableKey =
      'pk_test_51SAdplJBBOzsVfxM6xZOdAX5HKTGdtuDBDsM9JwSx4AoSPtklO9JMcGgOm5X4vpluD2FXblT22hBuFm1pqRtnL1n00Q8d4EBmg';
}
