import 'package:flutter/material.dart';
import '../services/favorites_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final FavoritesService _favoritesService = FavoritesService();

  Set<String> _favoritePetIds = {};
  bool _isLoading = false;
  String? _error;

  Set<String> get favoritePetIds => _favoritePetIds;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadFavorites(String userId) async {
    try {
      _setLoading(true);
      _error = null;
      _favoritePetIds = await _favoritesService.getFavoritePetIds(userId);
      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  Future<void> toggleFavorite(String userId, String petId) async {
    if (_favoritePetIds.contains(petId)) {
      await _favoritesService.removeFavorite(userId, petId);
      _favoritePetIds.remove(petId);
    } else {
      await _favoritesService.addFavorite(userId, petId);
      _favoritePetIds.add(petId);
    }
    notifyListeners();
  }

  bool isFavorite(String petId) => _favoritePetIds.contains(petId);

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}


