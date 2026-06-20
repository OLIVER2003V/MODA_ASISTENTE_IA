import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

// ── Models ────────────────────────────────────────────────────────────────────

class CurrencyInfo {
  final String code;
  final String symbol;
  final String name;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
  });
}

class ConvertedPrice {
  final double amount;
  final String formatted;
  final String currencyCode;
  final String symbol;
  final bool isConverted;

  const ConvertedPrice({
    required this.amount,
    required this.formatted,
    required this.currencyCode,
    required this.symbol,
    required this.isConverted,
  });
}

// ── Service ───────────────────────────────────────────────────────────────────

class CurrencyService {
  static Map<String, double>? _rates;
  static DateTime? _lastFetch;

  // Country code → currency info
  static const Map<String, CurrencyInfo> _map = {
    'AR': CurrencyInfo(code: 'ARS', symbol: '\$', name: 'Pesos arg.'),
    'BR': CurrencyInfo(code: 'BRL', symbol: 'R\$', name: 'Reales'),
    'MX': CurrencyInfo(code: 'MXN', symbol: '\$', name: 'Pesos mex.'),
    'CO': CurrencyInfo(code: 'COP', symbol: '\$', name: 'Pesos col.'),
    'CL': CurrencyInfo(code: 'CLP', symbol: '\$', name: 'Pesos chil.'),
    'PE': CurrencyInfo(code: 'PEN', symbol: 'S/', name: 'Soles'),
    'UY': CurrencyInfo(code: 'UYU', symbol: '\$', name: 'Pesos uru.'),
    'PY': CurrencyInfo(code: 'PYG', symbol: '₲', name: 'Guaraníes'),
    'BO': CurrencyInfo(code: 'BOB', symbol: 'Bs', name: 'Bolivianos'),
    'EC': CurrencyInfo(code: 'USD', symbol: '\$', name: 'USD'),
    'VE': CurrencyInfo(code: 'USD', symbol: '\$', name: 'USD'),
    'GB': CurrencyInfo(code: 'GBP', symbol: '£', name: 'Libras'),
    'DE': CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euros'),
    'FR': CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euros'),
    'ES': CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euros'),
    'PT': CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euros'),
    'IT': CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euros'),
    'CA': CurrencyInfo(code: 'CAD', symbol: 'CA\$', name: 'Dólares can.'),
    'AU': CurrencyInfo(code: 'AUD', symbol: 'A\$', name: 'Dólares aus.'),
    'JP': CurrencyInfo(code: 'JPY', symbol: '¥', name: 'Yenes'),
  };

  static const CurrencyInfo _usd =
      CurrencyInfo(code: 'USD', symbol: '\$', name: 'USD');

  static CurrencyInfo infoForLocale(Locale locale) {
    final country = locale.countryCode ?? '';
    return _map[country] ?? _usd;
  }

  static Future<Map<String, double>?> _fetchRates() async {
    if (_rates != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!).inHours < 24) {
      return _rates;
    }

    try {
      final res = await http
          .get(Uri.parse('https://open.er-api.com/v6/latest/USD'))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        if (body['result'] == 'success') {
          _rates = Map<String, double>.from(
            (body['rates'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ),
          );
          _lastFetch = DateTime.now();
          return _rates;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<ConvertedPrice?> convert(
    double usdAmount,
    Locale locale,
  ) async {
    final info = infoForLocale(locale);

    if (info.code == 'USD') {
      return ConvertedPrice(
        amount: usdAmount,
        formatted: '\$${usdAmount.toStringAsFixed(2)}',
        currencyCode: 'USD',
        symbol: '\$',
        isConverted: false,
      );
    }

    final rates = await _fetchRates();
    if (rates == null) return null;

    final rate = rates[info.code];
    if (rate == null) return null;

    final converted = usdAmount * rate;
    return ConvertedPrice(
      amount: converted,
      formatted: '${info.symbol} ${_fmt(converted, info.code)}',
      currencyCode: info.code,
      symbol: info.symbol,
      isConverted: true,
    );
  }

  static String _fmt(double amount, String code) {
    // Sin decimales para monedas con valores grandes
    if (['ARS', 'COP', 'CLP', 'PYG', 'JPY'].contains(code)) {
      final n = amount.round();
      return n.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]}.',
          );
    }
    return amount.toStringAsFixed(2);
  }
}
