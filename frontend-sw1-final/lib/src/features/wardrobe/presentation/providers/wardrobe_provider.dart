import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/closet_service.dart';
import '../../data/models/closet_response_model.dart';
import '../../data/models/garment_model.dart';

class WardrobeProvider extends ChangeNotifier {
  ClosetResponse? _closetData;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastFetch;

  // Getters
  ClosetResponse? get closetData => _closetData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _closetData != null;
  List<Garment> get garments => _closetData?.garments ?? [];

  /// Carga el closet del usuario
  /// Si [force] es true, ignora el caché y hace la petición
  Future<void> loadCloset({bool force = false}) async {
    // Si ya está cargando, no hacer nada
    if (_isLoading) return;

    // Si hay datos recientes (menos de 5 minutos) y no es forzado, usar caché
    if (!force && _closetData != null && _lastFetch != null) {
      final diff = DateTime.now().difference(_lastFetch!);
      if (diff.inMinutes < 5) {
        return;
      }
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await AuthService.getCachedUser();
      if (user == null) {
        _errorMessage = 'No se pudo obtener el usuario';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final closetData = await ClosetService.getClosetByUserId(user.id);
      _closetData = closetData;
      _lastFetch = DateTime.now();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cargar el armario';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crea un nuevo closet con prendas
  Future<bool> createCloset({
    required String name,
    String? description,
    required List<File> imageFiles,
    required List<String> pathLocals,
  }) async {
    try {
      await ClosetService.createClosetWithGarments(
        closetName: name,
        closetDescription: description,
        imageFiles: imageFiles,
        pathLocals: pathLocals,
      );
      await loadCloset(force: true);
      return true;
    } catch (e) {
      _errorMessage = 'Error al crear el armario: $e';
      notifyListeners();
      return false;
    }
  }

  /// Actualiza el closet
  Future<bool> updateCloset({
    required String closetId,
    required String name,
    String? description,
  }) async {
    try {
      await ClosetService.updateCloset(
        closetId: closetId,
        name: name,
        description: description ?? '',
      );
      await loadCloset(force: true);
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar: $e';
      notifyListeners();
      return false;
    }
  }

  /// Elimina el closet
  Future<bool> deleteCloset() async {
    if (_closetData == null) return false;

    try {
      await ClosetService.deleteCloset(_closetData!.closet.id);
      _closetData = null;
      _lastFetch = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar: $e';
      notifyListeners();
      return false;
    }
  }

  /// Agrega una prenda
  Future<bool> addGarment({
    required File imageFile,
    required String pathLocal,
    String? name,
  }) async {
    if (_closetData == null) return false;

    try {
      await ClosetService.addGarment(
        closetId: _closetData!.closet.id,
        imageFile: imageFile,
        pathLocal: pathLocal,
        name: name,
      );
      await loadCloset(force: true);
      return true;
    } catch (e) {
      _errorMessage = 'Error al agregar prenda: $e';
      notifyListeners();
      return false;
    }
  }

  /// Elimina una prenda
  Future<bool> deleteGarment(String garmentId) async {
    try {
      await ClosetService.deleteGarment(garmentId);
      await loadCloset(force: true);
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar prenda: $e';
      notifyListeners();
      return false;
    }
  }

  /// Actualiza el nombre de una prenda
  Future<bool> updateGarment(String garmentId, {required String name}) async {
    try {
      await ClosetService.updateGarment(garmentId, name: name);
      await loadCloset(force: true);
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar prenda: $e';
      notifyListeners();
      return false;
    }
  }

  /// Limpia el estado (útil para logout)
  void clear() {
    _closetData = null;
    _lastFetch = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
