import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _isLoadingCount = false;
  String? _error;
  Timer? _pollTimer;
  DateTime? _lastFetch;

  // ── Getters ──────────────────────────────────────────────────────────────────

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _notifications.isNotEmpty;
  bool get hasUnread => _unreadCount > 0;

  // ── Init / Dispose ────────────────────────────────────────────────────────────

  NotificationProvider() {
    _startPolling();
  }

  void _startPolling() {
    _refreshCount(); // cargar de inmediato
    _pollTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _refreshCount(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ── Conteo no leídos ──────────────────────────────────────────────────────────

  Future<void> _refreshCount() async {
    if (_isLoadingCount) return;
    _isLoadingCount = true;
    try {
      final count = await NotificationService.getUnreadCount();
      if (_unreadCount != count) {
        _unreadCount = count;
        notifyListeners();
      }
    } catch (_) {
    } finally {
      _isLoadingCount = false;
    }
  }

  Future<void> refreshCount() => _refreshCount();

  // ── Cargar notificaciones ─────────────────────────────────────────────────────

  Future<void> loadNotifications({bool force = false}) async {
    if (_isLoading) return;
    if (!force && _notifications.isNotEmpty && _lastFetch != null) {
      if (DateTime.now().difference(_lastFetch!).inMinutes < 1) return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await NotificationService.getNotifications();
      _unreadCount = _notifications.where((n) => !n.read).length;
      _lastFetch = DateTime.now();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Marcar como leído ─────────────────────────────────────────────────────────

  Future<void> markRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    final wasUnread = !_notifications[idx].read;

    // Optimistic
    _notifications[idx].read = true;
    if (wasUnread && _unreadCount > 0) _unreadCount--;
    notifyListeners();

    try {
      await NotificationService.markRead(id);
    } catch (_) {
      // Rollback
      _notifications[idx].read = false;
      if (wasUnread) _unreadCount++;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    final hadUnread = _unreadCount > 0;
    // Optimistic
    for (final n in _notifications) {
      n.read = true;
    }
    _unreadCount = 0;
    notifyListeners();

    try {
      await NotificationService.markAllRead();
    } catch (_) {
      // Rollback (simple: reload from server)
      if (hadUnread) await loadNotifications(force: true);
    }
  }

  // ── Agregar notificación local (desde FCM foreground) ──────────────────────────

  void addLocal(AppNotification notification) {
    _notifications = [notification, ..._notifications];
    _unreadCount++;
    notifyListeners();
  }

  void clear() {
    _pollTimer?.cancel();
    _notifications = [];
    _unreadCount = 0;
    _isLoading = false;
    _error = null;
    _lastFetch = null;
    notifyListeners();
  }
}
