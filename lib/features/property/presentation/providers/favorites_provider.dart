import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/property_model.dart';
import 'dart:convert';

class FavoritesProvider extends ChangeNotifier {
  List<PropertyModel> _favorites = [];
  bool _isLoading = false;
  bool _initialized = false;

  // Getters
  List<PropertyModel> get favorites => _favorites;
  bool get isLoading => _isLoading;
  bool get isInitialized => _initialized;

  // Constructor
  FavoritesProvider() {
    init();
  }

  // Initialize favorites from SharedPreferences
  Future<void> init() async {
    if (_initialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getStringList('user_favorites') ?? [];

      _favorites = favoritesJson.map((json) {
        final Map<String, dynamic> propertyMap = jsonDecode(json);
        // Create PropertyModel from JSON
        return PropertyModel(
          id: propertyMap['id'],
          title: propertyMap['title'] ?? '',
          price: (propertyMap['price'] ?? 0).toDouble(),
          location: propertyMap['location'],
          description: propertyMap['description'] ?? '',
          bedrooms: propertyMap['bedrooms'] ?? 0,
          bathrooms: propertyMap['bathrooms'] ?? 0,
          area: (propertyMap['area'] ?? 0).toDouble(),
          images: propertyMap['images'] != null
              ? List<String>.from(propertyMap['images'])
              : null,
          latitude: propertyMap['latitude']?.toDouble(),
          longitude: propertyMap['longitude']?.toDouble(),
          createdAt: DateTime.parse(
              propertyMap['createdAt'] ?? DateTime.now().toIso8601String()),
          updatedAt: DateTime.parse(
              propertyMap['updatedAt'] ?? DateTime.now().toIso8601String()),
          type: PropertyType.values.firstWhere(
            (e) =>
                e.toString().split('.').last.toLowerCase() ==
                (propertyMap['type'] ?? 'house').toLowerCase(),
            orElse: () => PropertyType.house,
          ),
          status: PropertyStatus.values.firstWhere(
            (e) =>
                e.toString().split('.').last.toLowerCase() ==
                (propertyMap['status'] ?? 'available').toLowerCase(),
            orElse: () => PropertyStatus.available,
          ),
          propertyType: propertyMap['propertyType'] ?? 'House',
          listingType: propertyMap['listingType'] ?? 'Sale',
          featured: propertyMap['featured'] ?? false,
          amenities: propertyMap['amenities'] != null
              ? List<String>.from(propertyMap['amenities'])
              : null,
        );
      }).toList();

      _initialized = true;
    } catch (e) {
      print('Error loading favorites: $e');
      // Initialize with empty list on error
      _favorites = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save favorites to SharedPreferences
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = _favorites.map((property) {
        // Convert PropertyModel to JSON, but simplify to avoid circular references
        Map<String, dynamic> simpleMap = {
          'id': property.id,
          'title': property.title,
          'price': property.price,
          'location': property.location,
          'description': property.description,
          'bedrooms': property.bedrooms,
          'bathrooms': property.bathrooms,
          'area': property.area,
          'images': property.images,
          'latitude': property.latitude,
          'longitude': property.longitude,
          'createdAt': property.createdAt.toIso8601String(),
          'updatedAt': property.updatedAt.toIso8601String(),
          'type': property.type.toString().split('.').last,
          'status': property.status.toString().split('.').last,
          'propertyType': property.propertyType,
          'listingType': property.listingType,
          'featured': property.featured,
          'amenities': property.amenities,
        };

        return jsonEncode(simpleMap);
      }).toList();

      await prefs.setStringList('user_favorites', favoritesJson);
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  // Add a property to favorites
  Future<void> addToFavorites(PropertyModel property) async {
    if (!_initialized) await init();

    // Check if already in favorites
    if (!isFavorite(property.id)) {
      _favorites.add(property);
      await _saveFavorites();
      notifyListeners();
    }
  }

  // Remove a property from favorites
  Future<void> removeFromFavorites(String propertyId) async {
    if (!_initialized) await init();

    _favorites.removeWhere((property) => property.id == propertyId);
    await _saveFavorites();
    notifyListeners();
  }

  // Check if a property is in favorites
  bool isFavorite(String? propertyId) {
    if (propertyId == null) return false;
    return _favorites.any((property) => property.id == propertyId);
  }

  // Clear all favorites
  Future<void> clearFavorites() async {
    _favorites = [];
    await _saveFavorites();
    notifyListeners();
  }
}
