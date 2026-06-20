import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

// ── Modelos ───────────────────────────────────────────────────────────────────

class SubscriptionInfo {
  final String status; // FREE | PREMIUM | CANCELLED | PAST_DUE
  final bool isPremium;
  final DateTime? currentPeriodEnd;

  SubscriptionInfo({
    required this.status,
    required this.isPremium,
    this.currentPeriodEnd,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> j) {
    return SubscriptionInfo(
      status: j['status'] as String? ?? 'FREE',
      isPremium: j['isPremium'] as bool? ?? false,
      currentPeriodEnd: j['currentPeriodEnd'] != null
          ? DateTime.tryParse(j['currentPeriodEnd'] as String)
          : null,
    );
  }

  // Estado por defecto cuando no existe suscripción
  factory SubscriptionInfo.free() =>
      SubscriptionInfo(status: 'FREE', isPremium: false);
}

class CheckoutResult {
  final String clientSecret;
  final String subscriptionId;

  CheckoutResult({required this.clientSecret, required this.subscriptionId});

  factory CheckoutResult.fromJson(Map<String, dynamic> j) => CheckoutResult(
        clientSecret: j['clientSecret'] as String,
        subscriptionId: j['subscriptionId'] as String,
      );
}

// ── Service ───────────────────────────────────────────────────────────────────

class SubscriptionService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, String>> get _authHeaders async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No hay token de autenticación');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Obtiene el estado actual de suscripción del usuario
  static Future<SubscriptionInfo> getStatus() async {
    final res = await http.get(
      Uri.parse('$baseUrl/subscription/status'),
      headers: await _authHeaders,
    );
    if (res.statusCode == 404) return SubscriptionInfo.free();
    if (res.statusCode != 200) {
      final err = json.decode(res.body);
      throw Exception(err['message'] ?? 'Error al obtener estado');
    }
    return SubscriptionInfo.fromJson(
        json.decode(res.body) as Map<String, dynamic>);
  }

  /// Inicia el proceso de checkout y retorna el clientSecret de Stripe
  static Future<CheckoutResult> createCheckout(String planId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/subscription/checkout'),
      headers: await _authHeaders,
      body: json.encode({'planId': planId}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      final err = json.decode(res.body);
      throw Exception(err['message'] ?? 'Error al iniciar suscripción');
    }
    return CheckoutResult.fromJson(
        json.decode(res.body) as Map<String, dynamic>);
  }
}
