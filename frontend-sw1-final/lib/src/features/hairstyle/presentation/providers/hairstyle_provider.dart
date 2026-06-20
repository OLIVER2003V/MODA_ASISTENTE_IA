import 'package:flutter/foundation.dart';
import '../../../../core/services/hairstyle_service.dart';

class HairstyleProvider extends ChangeNotifier {
  List<HairstyleItem> _catalog = [];
  Set<String> _favoriteIds = {};
  bool _isLoading = false;
  String? _error;
  bool _loaded = false;

  // Filtros
  bool _showFavoritesOnly = false;
  String _genderFilter = 'ALL'; // 'ALL' | 'MALE' | 'FEMALE'

  // Getters básicos
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get showFavoritesOnly => _showFavoritesOnly;
  String get genderFilter => _genderFilter;

  bool isFavorite(String id) => _favoriteIds.contains(id);

  // Catálogo filtrado según tab + género
  List<HairstyleItem> get displayed {
    var list = _showFavoritesOnly
        ? _catalog.where((h) => _favoriteIds.contains(h.id)).toList()
        : List<HairstyleItem>.from(_catalog);

    if (_genderFilter != 'ALL') {
      list = list
          .where((h) =>
              h.gender == _genderFilter ||
              h.gender == 'UNISEX' ||
              h.gender == null)
          .toList();
    }
    return list;
  }

  int get favoriteCount => _favoriteIds.length;
  List<HairstyleItem> get catalog => _catalog;

  // ── Carga ──────────────────────────────────────────────────────────────────

  Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        HairstyleService.getAll(),
        HairstyleService.getFavorites(),
      ]);
      _catalog = results[0];
      _favoriteIds = results[1].map((h) => h.id).toSet();
      _loaded = true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Favoritos ──────────────────────────────────────────────────────────────

  Future<void> toggleFavorite(String hairstyleId) async {
    final wasFav = _favoriteIds.contains(hairstyleId);

    // Optimistic
    if (wasFav) {
      _favoriteIds.remove(hairstyleId);
    } else {
      _favoriteIds.add(hairstyleId);
    }
    notifyListeners();

    try {
      if (wasFav) {
        await HairstyleService.removeFavorite(hairstyleId);
      } else {
        await HairstyleService.addFavorite(hairstyleId);
      }
    } catch (_) {
      // Rollback
      if (wasFav) {
        _favoriteIds.add(hairstyleId);
      } else {
        _favoriteIds.remove(hairstyleId);
      }
      notifyListeners();
    }
  }

  // ── Filtros ────────────────────────────────────────────────────────────────

  void setTab(bool favoritesOnly) {
    if (_showFavoritesOnly == favoritesOnly) return;
    _showFavoritesOnly = favoritesOnly;
    notifyListeners();
  }

  void setGenderFilter(String filter) {
    if (_genderFilter == filter) return;
    _genderFilter = filter;
    notifyListeners();
  }
}
