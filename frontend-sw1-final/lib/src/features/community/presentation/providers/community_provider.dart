import 'package:flutter/foundation.dart';
import '../../../../core/services/post_service.dart';
import '../../../../core/services/storage_service.dart';

enum FeedMode { global, following, tag }

class CommunityProvider extends ChangeNotifier {
  List<Post> _posts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _currentUserId;

  FeedMode _feedMode = FeedMode.global;
  String? _activeTag;

  // postId → reactionType ('LIKE','LOVE','FIRE','WOW')
  final Map<String, String> _myReactions = {};
  final Map<String, bool> _loadingReactions = {};

  int _currentPage = 1;
  bool _hasMore = true;
  DateTime? _lastFetch;

  // ── Filtros cliente ───────────────────────────────────────────────────────
  String? _typeFilter;   // null=todos | 'OUTFIT' | 'PHOTO' | 'TIP'
  String _timeFilter = 'ALL'; // 'ALL' | 'TODAY' | 'WEEK' | 'MONTH'

  // ── Getters ──────────────────────────────────────────────────────────────

  List<Post> get posts => _applyFilters(_posts);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  String? get currentUserId => _currentUserId;
  bool get hasData => _posts.isNotEmpty;
  bool get hasUser => _currentUserId != null;
  bool get hasMore => _hasMore;
  FeedMode get feedMode => _feedMode;
  String? get activeTag => _activeTag;
  String? get typeFilter => _typeFilter;
  String get timeFilter => _timeFilter;

  List<Post> _applyFilters(List<Post> src) {
    var result = src;
    if (_typeFilter != null) {
      result = result.where((p) => p.postType == _typeFilter).toList();
    }
    if (_timeFilter != 'ALL') {
      final now = DateTime.now();
      final cutoff = switch (_timeFilter) {
        'TODAY' => now.subtract(const Duration(hours: 24)),
        'WEEK'  => now.subtract(const Duration(days: 7)),
        'MONTH' => now.subtract(const Duration(days: 30)),
        _       => DateTime(2000),
      };
      result = result.where((p) => p.createdAt.isAfter(cutoff)).toList();
    }
    return result;
  }

  void setTypeFilter(String? type) {
    if (_typeFilter == type) {
      _typeFilter = null; // toggle off
    } else {
      _typeFilter = type;
    }
    notifyListeners();
  }

  void setTimeFilter(String time) {
    _timeFilter = _timeFilter == time ? 'ALL' : time;
    notifyListeners();
  }

  String? myReactionFor(String postId) => _myReactions[postId];
  bool hasReacted(String postId) => _myReactions.containsKey(postId);
  bool isLoadingReaction(String postId) => _loadingReactions[postId] == true;

  Post? getPost(String postId) {
    try {
      return _posts.firstWhere((p) => p.id == postId);
    } catch (_) {
      return null;
    }
  }

  // ── Cargar feed ───────────────────────────────────────────────────────────

  Future<void> loadPosts({bool force = false}) async {
    if (_isLoading) return;

    if (!force && _posts.isNotEmpty && _lastFetch != null) {
      final diff = DateTime.now().difference(_lastFetch!);
      if (diff.inMinutes < 2) return;
    }

    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    notifyListeners();

    try {
      final user = await StorageService.getUser();
      _currentUserId = user?.id;

      final posts = await _fetchPage(1);

      if (_currentUserId != null) {
        _myReactions
          ..clear()
          ..addAll(await PostService.getMyReactions());
      }

      _posts = posts;
      _lastFetch = DateTime.now();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final next = _currentPage + 1;
      final more = await _fetchPage(next);
      if (more.isEmpty) {
        _hasMore = false;
      } else {
        _posts = [..._posts, ...more];
        _currentPage = next;
      }
    } catch (_) {
      // silencioso: ya tiene datos previos
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<List<Post>> _fetchPage(int page) async {
    switch (_feedMode) {
      case FeedMode.following:
        return PostService.getFollowingFeed(page: page);
      case FeedMode.tag:
        return PostService.getPostsByTag(_activeTag ?? '', page: page);
      case FeedMode.global:
        return PostService.getPosts(page: page);
    }
  }

  Future<void> setFeedMode(FeedMode mode, {String? tag}) async {
    if (_feedMode == mode && _activeTag == tag) return;
    _feedMode = mode;
    _activeTag = tag;
    _hasMore = true;
    _lastFetch = null;
    await loadPosts(force: true);
  }

  // ── Reacciones ────────────────────────────────────────────────────────────

  Future<bool> react(String postId, String reactionType) async {
    if (_currentUserId == null) return false;
    if (_loadingReactions[postId] == true) return false;

    _loadingReactions[postId] = true;
    notifyListeners();

    final prevReaction = _myReactions[postId];
    final wasReacted = prevReaction != null;

    // Optimistic update
    if (wasReacted && prevReaction == reactionType) {
      // Quitar la reacción existente
      _myReactions.remove(postId);
      _adjustCount(postId, -1);
    } else {
      // Poner nueva reacción (sin cambiar el count si ya había una)
      if (!wasReacted) _adjustCount(postId, 1);
      _myReactions[postId] = reactionType;
    }
    notifyListeners();

    try {
      if (wasReacted && prevReaction == reactionType) {
        await PostService.removeReaction(postId);
      } else {
        await PostService.reactToPost(postId, reactionType: reactionType);
      }
      _loadingReactions[postId] = false;
      notifyListeners();
      return true;
    } catch (_) {
      // Rollback optimistic update
      if (wasReacted && prevReaction == reactionType) {
        // Toggling off failed → restore reaction and add count back
        _myReactions[postId] = prevReaction;
        _adjustCount(postId, 1);
      } else if (wasReacted) {
        // Type-change failed → restore old reaction type (count stays same)
        _myReactions[postId] = prevReaction;
      } else {
        // New reaction failed → remove and subtract count
        _myReactions.remove(postId);
        _adjustCount(postId, -1);
      }
      _loadingReactions[postId] = false;
      notifyListeners();
      return false;
    }
  }

  void _adjustCount(String postId, int delta) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final p = _posts[idx];
    _posts[idx] = p.copyWith(reactionCount: (p.reactionCount + delta).clamp(0, 99999));
  }

  // ── Posts locales ─────────────────────────────────────────────────────────

  void addPostToFeed(Post post) {
    _posts = [post, ..._posts];
    notifyListeners();
  }

  void removePostFromFeed(String postId) {
    _posts = _posts.where((p) => p.id != postId).toList();
    _myReactions.remove(postId);
    notifyListeners();
  }

  void incrementCommentCount(String postId) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final p = _posts[idx];
    _posts[idx] = p.copyWith(commentCount: p.commentCount + 1);
    notifyListeners();
  }

  void decrementCommentCount(String postId) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final p = _posts[idx];
    _posts[idx] = p.copyWith(commentCount: (p.commentCount - 1).clamp(0, 99999));
    notifyListeners();
  }

  // ── Limpieza ──────────────────────────────────────────────────────────────

  void clear() {
    _posts = [];
    _currentUserId = null;
    _myReactions.clear();
    _loadingReactions.clear();
    _lastFetch = null;
    _errorMessage = null;
    _isLoading = false;
    _feedMode = FeedMode.global;
    _activeTag = null;
    _hasMore = true;
    _currentPage = 1;
    notifyListeners();
  }
}
