import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/features/property/domain/models/property_model.dart';
import '/features/property/data/property_repository.dart';
import '/core/utils/dev_utils.dart';

class FavoritesProvider extends ChangeNotifier {
  final PropertyRepository _propertyRepository;
  final SharedPreferences _prefs;
  final String _favoritesKey = 'favorite_properties';

  List<PropertyModel> _favorites = [];
  bool _isLoading = false;
  String? _error;

  FavoritesProvider(this._propertyRepository, this._prefs) {
    _loadFavorites();
  }

  // Getters
  List<PropertyModel> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load favorites from SharedPreferences and fetch property details
  Future<void> _loadFavorites() async {
    debugPrint('FavoritesProvider: Loading favorites');
    _isLoading = true;
    notifyListeners();

    try {
      final favoriteIds = _prefs.getStringList(_favoritesKey) ?? [];
      _favorites = [];
      final validIds = <String>[];

      for (final id in favoriteIds) {
        try {
          // Special handling for dev mode properties
          if (DevUtils.isDev &&
              (id.startsWith('dev-') || id.startsWith('mock-'))) {
            try {
              final property = await _propertyRepository.getPropertyById(id);
              if (property != null) {
                _favorites.add(property);
                validIds.add(id);
              }
            } catch (e) {
              debugPrint('FavoritesProvider: Dev mode property not found: $id');
              // Don't add to validIds so it gets cleaned up
            }
          } else {
            // Regular property handling
            final property = await _propertyRepository.getPropertyById(id);
            if (property != null) {
              _favorites.add(property);
              validIds.add(id);
            }
          }
        } catch (e) {
          debugPrint('FavoritesProvider: Error loading property $id - $e');
          // Skip this property but continue processing others
        }
      }

      // Update the stored list to remove any invalid IDs
      if (validIds.length != favoriteIds.length) {
        debugPrint(
            'FavoritesProvider: Cleaning up ${favoriteIds.length - validIds.length} invalid favorite IDs');
        await _prefs.setStringList(_favoritesKey, validIds);
      }

      debugPrint('FavoritesProvider: Loaded ${_favorites.length} favorites');
      _error = null;
    } catch (e) {
      debugPrint('FavoritesProvider: Error loading favorites - $e');
      _error = 'Failed to load favorites';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Toggle a property's favorite status
  Future<void> toggleFavorite(PropertyModel property) async {
    if (property.id == null) return;

    try {
      final List<String> favoriteIds =
          _prefs.getStringList(_favoritesKey) ?? [];
      final bool isCurrentlyFavorite = isFavorite(property.id);

      if (isCurrentlyFavorite) {
        favoriteIds.remove(property.id);
        _favorites.removeWhere((p) => p.id == property.id);
        debugPrint('FavoritesProvider: Removed from favorites');
      } else {
        favoriteIds.add(property.id!);
        _favorites.add(property);
        debugPrint('FavoritesProvider: Added to favorites');
      }

      await _prefs.setStringList(_favoritesKey, favoriteIds);
      notifyListeners();
    } catch (e) {
      debugPrint('FavoritesProvider: Error toggling favorite - $e');
      _error = 'Failed to update favorites';
      notifyListeners();
    }
  }

  // Check if a property is favorited
  bool isFavorite(String? propertyId) {
    if (propertyId == null) return false;
    return _favorites.any((property) => property.id == propertyId);
  }

  // Refresh favorites
  Future<void> refreshFavorites() async {
    await _loadFavorites();
  }
}
