import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/services/user_service.dart';

class PeopleProvider extends ChangeNotifier {
  List<UserSuggestion> _suggestions = [];
  List<UserSuggestion> _searchResults = [];
  bool _isLoadingSuggestions = false;
  bool _isSearching = false;
  String? _error;
  String _query = '';
  Timer? _debounce;
  DateTime? _lastFetch;

  // Estado de follow en progreso (evita doble tap)
  final Map<String, bool> _followLoading = {};

  // ── Getters ──────────────────────────────────────────────────────────────────

  List<UserSuggestion> get suggestions => _suggestions;
  List<UserSuggestion> get searchResults => _searchResults;
  bool get isLoadingSuggestions => _isLoadingSuggestions;
  bool get isSearching => _isSearching;
  String? get error => _error;
  String get query => _query;
  bool get hasQuery => _query.trim().isNotEmpty;

  bool isFollowLoading(String userId) => _followLoading[userId] == true;

  // ── Sugerencias ───────────────────────────────────────────────────────────────

  Future<void> loadSuggestions({bool force = false}) async {
    if (_isLoadingSuggestions) return;
    if (!force && _suggestions.isNotEmpty && _lastFetch != null) {
      if (DateTime.now().difference(_lastFetch!).inMinutes < 5) return;
    }

    _isLoadingSuggestions = true;
    _error = null;
    notifyListeners();

    try {
      _suggestions = await UserService.getSuggestions();
      _lastFetch = DateTime.now();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingSuggestions = false;
      notifyListeners();
    }
  }

  // ── Búsqueda debounced ────────────────────────────────────────────────────────

  void onSearchChanged(String q) {
    _query = q;
    _debounce?.cancel();

    if (q.trim().isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    _debounce = Timer(const Duration(milliseconds: 450), () => _runSearch(q));
  }

  Future<void> _runSearch(String q) async {
    try {
      final results = await UserService.searchUsers(q);
      if (_query == q) {
        _searchResults = results;
      }
    } catch (_) {
      if (_query == q) _searchResults = [];
    } finally {
      if (_query == q) {
        _isSearching = false;
        notifyListeners();
      }
    }
  }

  void clearSearch() {
    _debounce?.cancel();
    _query = '';
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }

  // ── Follow / Unfollow optimista ───────────────────────────────────────────────

  Future<void> toggleFollow(UserSuggestion user) async {
    if (_followLoading[user.id] == true) return;

    _followLoading[user.id] = true;
    final wasFollowing = user.isFollowing;
    user.isFollowing = !wasFollowing;
    notifyListeners();

    try {
      if (wasFollowing) {
        await UserService.unfollow(user.id);
      } else {
        await UserService.follow(user.id);
      }
    } catch (_) {
      // Rollback
      user.isFollowing = wasFollowing;
    } finally {
      _followLoading[user.id] = false;
      notifyListeners();
    }
  }

  // Actualizar estado de seguimiento en la lista (desde perfil público)
  void syncFollowState(String userId, bool isFollowing) {
    for (final u in _suggestions) {
      if (u.id == userId) u.isFollowing = isFollowing;
    }
    for (final u in _searchResults) {
      if (u.id == userId) u.isFollowing = isFollowing;
    }
    notifyListeners();
  }

  // ── Limpieza ──────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void clear() {
    _debounce?.cancel();
    _suggestions = [];
    _searchResults = [];
    _isLoadingSuggestions = false;
    _isSearching = false;
    _error = null;
    _query = '';
    _lastFetch = null;
    _followLoading.clear();
    notifyListeners();
  }
}
