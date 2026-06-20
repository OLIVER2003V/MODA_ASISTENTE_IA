import 'dart:io';

import 'package:flutter/foundation.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/user_attribute_service.dart';
import '../../../../core/services/user_service.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/models/user_attribute_model.dart';

class ProfileProvider extends ChangeNotifier {
  User? _user;
  UserAttribute? _userAttributes;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _saveError;
  DateTime? _lastFetch;

  // Getters
  User? get user => _user;
  UserAttribute? get userAttributes => _userAttributes;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get saveError => _saveError;
  bool get hasData => _user != null;

  /// Carga el perfil del usuario
  /// Si [force] es true, ignora el caché y hace la petición
  Future<void> loadProfile({bool force = false}) async {
    // Si ya está cargando, no hacer nada
    if (_isLoading) return;

    // Si hay datos recientes (menos de 5 minutos) y no es forzado, usar caché
    if (!force && _user != null && _lastFetch != null) {
      final diff = DateTime.now().difference(_lastFetch!);
      if (diff.inMinutes < 5) {
        return;
      }
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Primero intentar cargar desde cache local (rápido)
      if (!force && _user == null) {
        final cachedUser = await AuthService.getCachedUser();
        if (cachedUser != null) {
          _user = cachedUser;
          _isLoading = false;
          notifyListeners();
          // Actualizar desde servidor en segundo plano
          _refreshInBackground();
          return;
        }
      }

      // Obtener del servidor
      final user = await AuthService.getProfile(forceRefresh: true);

      // Cargar atributos del usuario
      UserAttribute? attributes;
      try {
        attributes = await UserAttributeService.getUserAttributes(user.id);
      } catch (e) {
        // Ignorar errores al cargar atributos
      }

      _user = user;
      _userAttributes = attributes;
      _lastFetch = DateTime.now();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;

      // Si hay error, intentar obtener desde cache
      if (!force && _user == null) {
        final cachedUser = await AuthService.getCachedUser();
        if (cachedUser != null) {
          _user = cachedUser;
          notifyListeners();
          return;
        }
      }

      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Actualiza el perfil en segundo plano
  Future<void> _refreshInBackground() async {
    try {
      final user = await AuthService.getProfile(forceRefresh: true);
      UserAttribute? attributes;
      try {
        attributes = await UserAttributeService.getUserAttributes(user.id);
      } catch (e) {
        // Ignorar errores
      }
      _user = user;
      _userAttributes = attributes;
      _lastFetch = DateTime.now();
      notifyListeners();
    } catch (e) {
      // Ignorar errores en actualización en segundo plano
    }
  }

  // ── Editar perfil ──────────────────────────────────────────────────────────

  Future<bool> updateName(String name) async {
    _isSaving = true;
    _saveError = null;
    notifyListeners();
    try {
      final data = await UserService.updateName(name);
      _user = _user?.copyWith(name: data['name'] as String? ?? name);
      await StorageService.saveUser(_user!);
      return true;
    } catch (e) {
      _saveError = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> uploadPhoto(File file) async {
    _isSaving = true;
    _saveError = null;
    notifyListeners();
    try {
      final data = await UserService.uploadProfilePhoto(file);
      _user = _user?.copyWith(
        profilePhoto: data['profilePhoto'] as String?,
        clearAvatar: true,
      );
      await StorageService.saveUser(_user!);
      return true;
    } catch (e) {
      _saveError = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deletePhoto() async {
    _isSaving = true;
    _saveError = null;
    notifyListeners();
    try {
      await UserService.deleteProfilePhoto();
      _user = _user?.copyWith(clearPhoto: true);
      await StorageService.saveUser(_user!);
      return true;
    } catch (e) {
      _saveError = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> setAvatar(String style) async {
    _isSaving = true;
    _saveError = null;
    notifyListeners();
    try {
      final data = await UserService.setAvatar(style);
      _user = _user?.copyWith(
        avatarStyle: data['avatarStyle'] as String? ?? style,
        clearPhoto: true,
      );
      await StorageService.saveUser(_user!);
      return true;
    } catch (e) {
      _saveError = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateAttributes(Map<String, dynamic> data) async {
    final id = _userAttributes?.id;
    if (id == null) return false;
    _isSaving = true;
    _saveError = null;
    notifyListeners();
    try {
      final updated = await UserAttributeService.updateAttributes(id, data);
      _userAttributes = updated;
      return true;
    } catch (e) {
      _saveError = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Cierra sesión y limpia el estado
  Future<void> logout() async {
    await AuthService.logout();
    clear();
  }

  /// Limpia el estado (útil para logout)
  void clear() {
    _user = null;
    _userAttributes = null;
    _lastFetch = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
