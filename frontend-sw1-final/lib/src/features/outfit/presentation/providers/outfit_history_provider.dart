import 'package:flutter/foundation.dart';
import '../../../../core/services/outfit_service.dart';
import '../../../../core/services/storage_service.dart';

class OutfitHistoryProvider extends ChangeNotifier {
  List<SavedOutfit> _outfits = [];
  bool _isLoading = false;
  String? _error;
  String? _lastUserId;

  List<SavedOutfit> get outfits => _outfits;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => !_isLoading && _outfits.isEmpty && _error == null;

  Future<void> load({bool force = false}) async {
    final user = await StorageService.getUser();
    if (user == null) return;

    if (!force && _lastUserId == user.id && _outfits.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _outfits = await OutfitService.getUserOutfits(user.id);
      _lastUserId = user.id;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createManual({
    required String name,
    required List<String> garmentIds,
  }) async {
    try {
      final outfit = await OutfitService.createManualOutfit(
          name: name, garmentIds: garmentIds);
      _outfits.insert(0, outfit);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> remove(String outfitId) async {
    final prev = List<SavedOutfit>.from(_outfits);
    _outfits.removeWhere((o) => o.id == outfitId);
    notifyListeners();

    try {
      await OutfitService.deleteOutfit(outfitId);
      return true;
    } catch (e) {
      _outfits = prev;
      notifyListeners();
      return false;
    }
  }
}
