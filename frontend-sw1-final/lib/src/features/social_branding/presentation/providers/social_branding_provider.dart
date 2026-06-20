import 'package:flutter/foundation.dart';
import '../../../../core/services/social_branding_service.dart';

class SocialBrandingProvider extends ChangeNotifier {
  bool _loading = false;
  String? _error;
  SocialBrandingResult? _result;
  String _selectedNetwork = 'instagram';

  bool get loading => _loading;
  String? get error => _error;
  SocialBrandingResult? get result => _result;
  String get selectedNetwork => _selectedNetwork;

  void selectNetwork(String network) {
    if (_selectedNetwork == network) return;
    _selectedNetwork = network;
    _result = null;
    _error = null;
    notifyListeners();
    load();
  }

  Future<void> load({bool refresh = false}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _result = await SocialBrandingService.getRecommendations(
        _selectedNetwork,
        refresh: refresh,
      );
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
