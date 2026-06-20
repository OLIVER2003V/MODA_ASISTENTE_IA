import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../../core/services/subscription_service.dart';

enum CheckoutState { idle, loadingCheckout, processingPayment, success, error }

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionInfo _info = SubscriptionInfo.free();
  bool _isLoadingStatus = false;
  String? _statusError;

  CheckoutState _checkoutState = CheckoutState.idle;
  String? _checkoutError;
  bool _loaded = false;

  // Getters
  SubscriptionInfo get info => _info;
  bool get isLoadingStatus => _isLoadingStatus;
  String? get statusError => _statusError;
  CheckoutState get checkoutState => _checkoutState;
  String? get checkoutError => _checkoutError;
  bool get isPremium => _info.isPremium;

  // ── Estado de suscripción ─────────────────────────────────────────────────

  Future<void> loadStatus({bool force = false}) async {
    if (_loaded && !force) return;
    _isLoadingStatus = true;
    _statusError = null;
    notifyListeners();
    try {
      _info = await SubscriptionService.getStatus();
      _loaded = true;
    } catch (e) {
      _statusError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingStatus = false;
      notifyListeners();
    }
  }

  // ── Checkout con Stripe Payment Sheet ────────────────────────────────────

  Future<bool> startCheckout(String planId) async {
    _checkoutState = CheckoutState.loadingCheckout;
    _checkoutError = null;
    notifyListeners();

    try {
      // 1. Obtener clientSecret del backend
      final result = await SubscriptionService.createCheckout(planId);

      // 2. Inicializar payment sheet de Stripe
      _checkoutState = CheckoutState.processingPayment;
      notifyListeners();

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: result.clientSecret,
          merchantDisplayName: 'StyleAI Premium',
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF667EEA),
            ),
          ),
        ),
      );

      // 3. Presentar al usuario
      await Stripe.instance.presentPaymentSheet();

      // 4. Pago exitoso — refrescar estado (el webhook ya actualizó la DB)
      _checkoutState = CheckoutState.success;
      notifyListeners();

      // Breve pausa para que el webhook procese
      await Future.delayed(const Duration(seconds: 2));
      await loadStatus(force: true);

      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        // Usuario canceló — no es error
        _checkoutState = CheckoutState.idle;
        notifyListeners();
        return false;
      }
      _checkoutState = CheckoutState.error;
      _checkoutError = e.error.localizedMessage ?? 'Error en el pago';
      notifyListeners();
      return false;
    } catch (e) {
      _checkoutState = CheckoutState.error;
      _checkoutError = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void resetCheckout() {
    _checkoutState = CheckoutState.idle;
    _checkoutError = null;
    notifyListeners();
  }
}
