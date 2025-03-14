import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/core/utils/dev_utils.dart'; // Add this import for DevUtils
import '../../domain/models/property_model.dart';
import '../../data/property_repository.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../notifications/data/notification_model.dart'; // Import for NotificationType

class PropertyProvider with ChangeNotifier {
  final PropertyRepository _repository;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationProvider _notificationProvider;

  bool _isLoading = false;
  List<PropertyModel> _properties = [];
  List<PropertyModel> _featuredProperties = [];
  List<PropertyModel> _recentProperties = [];
  List<PropertyModel> _searchResults = [];
  PropertyModel? _selectedProperty;
  String? _error;
  Map<String, dynamic> _filters = {};

  PropertyProvider(this._repository, this._notificationProvider);

  // Getters
  bool get isLoading => _isLoading;
  List<PropertyModel> get properties => _properties;
  List<PropertyModel> get featuredProperties => _featuredProperties;
  List<PropertyModel> get recentProperties => _recentProperties;
  List<PropertyModel> get searchResults => _searchResults;
  PropertyModel? get selectedProperty => _selectedProperty;
  String? get error => _error;

  // Add searchProperties method that was missing
  Future<void> searchProperties(String query) async {
    _setLoading(true);
    try {
      _searchResults = await _repository.searchProperties(query);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Add applyFilters method that was missing
  void applyFilters(Map<String, dynamic> filters) {
    _filters = filters;
    fetchProperties(filters: _filters);
  }

  // Reset filters
  void resetFilters() {
    _filters = {};
    fetchProperties();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> fetchProperties({Map<String, dynamic>? filters}) async {
    // Only set loading if not already fetching
    if (!_isLoading) {
      _setLoading(true);
    }

    try {
      final properties = await _repository.fetchProperties(filters: filters);
      _properties = properties;

      // Also update recent and featured properties to ensure consistency
      await _updateRecentProperties();
      await _updateFeaturedProperties();

      _error = null;
    } catch (e) {
      _error = e.toString();
      DevUtils.log('Failed to fetch properties: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Helper method to update recent properties
  Future<void> _updateRecentProperties() async {
    try {
      if (DevUtils.isDev && DevUtils.bypassAuth) {
        _recentProperties = _properties;
      } else {
        _recentProperties = List.from(_properties);
        _recentProperties.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (_recentProperties.length > 10) {
          _recentProperties = _recentProperties.sublist(0, 10);
        }
      }
    } catch (e) {
      debugPrint('Error updating recent properties: $e');
    }
  }

  // Helper method to update featured properties
  Future<void> _updateFeaturedProperties() async {
    try {
      _featuredProperties = _properties.where((p) => p.featured).toList();
    } catch (e) {
      debugPrint('Error updating featured properties: $e');
    }
  }

  Future<void> fetchFeaturedProperties() async {
    _setLoading(true);
    try {
      _featuredProperties = await _repository
          .fetchFeaturedProperties(); // Changed from getFeaturedProperties to fetchFeaturedProperties
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Fetch recent properties
  Future<void> fetchRecentProperties() async {
    _setLoading(true);
    try {
      // This is important - we need to also include dev mode properties
      if (DevUtils.isDev && DevUtils.bypassAuth) {
        // When in dev mode, make sure recently added dev properties appear in the list
        _recentProperties = _properties;

        // If no properties exist yet, create a placeholder
        if (_recentProperties.isEmpty && _properties.isEmpty) {
          debugPrint('Creating placeholder properties for dev mode');
          // No need to create placeholders - just log it
        }
      } else {
        // Normal fetch from repository
        _recentProperties = await _repository
            .fetchProperties(filters: {'sortBy': 'createdAt', 'limit': 10});
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching recent properties: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<PropertyModel?> getPropertyById(String id) async {
    _setLoading(true);
    try {
      _selectedProperty = await _repository.getPropertyById(id);
      _error = null;
      return _selectedProperty;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Add fetchPropertyById method that was missing
  Future<void> fetchPropertyById(String id) async {
    _setLoading(true);
    try {
      _selectedProperty = await _repository.getPropertyById(id);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Create new property with logging history
  Future<void> createProperty(Map<String, dynamic> propertyData) async {
    _setLoading(true);
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Add owner information and timestamps
      propertyData['ownerId'] = currentUser.uid;
      propertyData['ownerEmail'] = currentUser.email;
      propertyData['createdAt'] = FieldValue.serverTimestamp();
      propertyData['updatedAt'] = FieldValue.serverTimestamp();

      // Create property document
      final docRef =
          await _firestore.collection('properties').add(propertyData);

      // Log initial creation in history subcollection
      await docRef.collection('history').add({
        'timestamp': FieldValue.serverTimestamp(),
        'changedBy': currentUser.email ?? currentUser.uid,
        'changedFields': ['created'],
        'action': 'create',
      });

      // Create notification after successful property creation
      final property = await getPropertyById(docRef.id);
      if (property != null) {
        await _notificationProvider.createPropertyNotification(
          property: property,
          type: NotificationType.propertyListed,
        );
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Update existing property with logging history
  Future<void> updateProperty(
      String id, Map<String, dynamic> updatedData) async {
    _setLoading(true);
    try {
      // Store original property for comparison
      final originalProperty = await getPropertyById(id);

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Update property in Firestore
      final docRef = _firestore.collection('properties').doc(id);
      await docRef.update({
        ...updatedData,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log update in history
      await docRef.collection('history').add({
        'timestamp': FieldValue.serverTimestamp(),
        'changedBy': currentUser.email ?? currentUser.uid,
        'changedFields': updatedData.keys.toList(),
        'action': 'update',
      });

      // Check for price or status changes and create notifications
      final updatedProperty = await getPropertyById(id);
      if (updatedProperty != null) {
        if (originalProperty != null &&
            updatedData.containsKey('price') &&
            originalProperty.price != updatedData['price']) {
          await _notificationProvider.createPropertyNotification(
            property: updatedProperty,
            type: NotificationType.priceChange,
          );
        }

        if (originalProperty != null &&
            updatedData.containsKey('status') &&
            originalProperty.status != updatedData['status']) {
          await _notificationProvider.createPropertyNotification(
            property: updatedProperty,
            type: NotificationType.statusChange,
          );
        }
      }

      // Update local state
      await fetchProperties();

      _error = null;
    } catch (e) {
      _error = e.toString();
      DevUtils.log('Error updating property: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Delete property with logging history
  Future<void> deleteProperty(String id) async {
    _setLoading(true);
    try {
      // In production mode
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Delete from Firestore first
      final docRef = _firestore.collection('properties').doc(id);
      await docRef.delete();

      // If successful, update local state
      _properties.removeWhere((p) => p.id == id);
      _recentProperties.removeWhere((p) => p.id == id);
      _featuredProperties.removeWhere((p) => p.id == id);

      // Refresh data after deletion
      await fetchProperties();

      // Notify UI of changes
      notifyListeners();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting property: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get property history - returns list of changes
  Future<List<Map<String, dynamic>>> getPropertyHistory(String id) async {
    _setLoading(true);
    try {
      final historySnapshot = await _firestore
          .collection('properties')
          .doc(id)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .get();

      final history = historySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'timestamp': data['timestamp'] as Timestamp,
          'changedBy': data['changedBy'] as String,
          'changedFields': List<String>.from(data['changedFields'] ?? []),
          'action': data['action'] as String,
        };
      }).toList();

      return history;
    } catch (e) {
      _error = e.toString();
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Schedule property for publication
  Future<void> scheduleProperty(String id, DateTime publishDate) async {
    _setLoading(true);
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Update property with publication date
      final docRef = _firestore.collection('properties').doc(id);
      await docRef.update({
        'publishDate': publishDate,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log scheduling in history
      await docRef.collection('history').add({
        'timestamp': FieldValue.serverTimestamp(),
        'changedBy': currentUser.email ?? currentUser.uid,
        'changedFields': ['publishDate'],
        'action': 'schedule',
        'details': {
          'publishDate': publishDate,
        }
      });

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Mark property as sold/rented
  Future<void> changePropertyStatus(String id, PropertyStatus status) async {
    _setLoading(true);
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Update property status
      final docRef = _firestore.collection('properties').doc(id);
      await docRef.update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log status change in history
      await docRef.collection('history').add({
        'timestamp': FieldValue.serverTimestamp(),
        'changedBy': currentUser.email ?? currentUser.uid,
        'changedFields': ['status'],
        'action': 'statusChange',
        'details': {
          'newStatus': status.toString().split('.').last,
        }
      });

      // Create notification after successful status change
      final property = await getPropertyById(id);
      if (property != null) {
        await _notificationProvider.createPropertyNotification(
          property: property,
          type: NotificationType.statusChange,
        );
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Feature/unfeature a property
  Future<void> toggleFeatureProperty(String id, bool isFeatured) async {
    _setLoading(true);
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Update property featured status
      final docRef = _firestore.collection('properties').doc(id);
      await docRef.update({
        'featured': isFeatured,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log feature change in history
      await docRef.collection('history').add({
        'timestamp': FieldValue.serverTimestamp(),
        'changedBy': currentUser.email ?? currentUser.uid,
        'changedFields': ['featured'],
        'action': isFeatured ? 'feature' : 'unfeature',
      });

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Report analytics for property views
  Future<void> recordPropertyView(String id) async {
    try {
      // Increment view count
      final docRef = _firestore.collection('properties').doc(id);
      await docRef.update({
        'viewCount': FieldValue.increment(1),
      });

      // Add to analytics collection
      await _firestore.collection('property_analytics').add({
        'propertyId': id,
        'action': 'view',
        'timestamp': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser?.uid ?? 'anonymous',
        'deviceInfo': {
          'platform': kIsWeb ? 'web' : 'app',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      });
    } catch (e) {
      // Don't set loading or error for analytics - silent failure is okay
      debugPrint(
          'Error recording view: $e'); // Changed from print to debugPrint
    }
  }

  // Compare two properties (useful for showing comparisons)
  Map<String, dynamic> compareProperties(
      PropertyModel prop1, PropertyModel prop2) {
    return {
      'price': {
        'difference': (prop1.price - prop2.price),
        'percentageDiff':
            '${((prop1.price - prop2.price) / prop2.price * 100).toStringAsFixed(1)}%',
      },
      'area': {
        'difference': (prop1.area - prop2.area),
        'percentageDiff':
            '${((prop1.area - prop2.area) / prop2.area * 100).toStringAsFixed(1)}%',
      },
      'bedrooms': {
        'difference': (prop1.bedrooms - prop2.bedrooms),
      },
      'bathrooms': {
        'difference': (prop1.bathrooms - prop2.bathrooms),
      },
      'pricePerSqFt': {
        'prop1': (prop1.price / prop1.area).toStringAsFixed(2),
        'prop2': (prop2.price / prop2.area).toStringAsFixed(2),
        'difference': ((prop1.price / prop1.area) - (prop2.price / prop2.area))
            .toStringAsFixed(2),
        'percentageDiff':
            '${(((prop1.price / prop1.area) - (prop2.price / prop2.area)) / (prop2.price / prop2.area) * 100).toStringAsFixed(1)}%',
      },
    };
  }

  // Change print to debugPrint
  void reportError(String message, dynamic error) {
    debugPrint('$message: $error');
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Add new method for property creation with images - revised implementation
  Future<void> createPropertyWithImages(
      PropertyModel property, List<File> images) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First upload images and get URLs
      final List<String> imageUrls = await uploadMultipleImages(images);

      // Copy the property with the correct image URLs
      final updatedProperty = property.copyWith(images: imageUrls);

      // Add the property data to Firestore
      await addNewProperty(updatedProperty.toMap());

      // Update local list
      final newProperty = property.copyWith(images: imageUrls);
      _properties = [newProperty, ..._properties];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating property: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // *** FIX: Add method for uploading multiple images since repository doesn't have it ***
  Future<List<String>> uploadMultipleImages(List<File> images) async {
    final List<String> urls = [];

    try {
      for (final image in images) {
        final url = await _repository.uploadImage(image);
        urls.add(url);
      }
      return urls;
    } catch (e) {
      debugPrint('Error uploading images: $e');
      rethrow;
    }
  }

  // Add new method for adding property
  Future<void> addNewProperty(Map<String, dynamic> propertyData) async {
    _setLoading(true);
    try {
      String documentId = '';

      // Check if in dev mode first
      if (DevUtils.isDev) {
        DevUtils.log('Using dev mode for property creation');

        // Generate a consistent ID for the property
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        documentId = 'dev-$timestamp';

        propertyData['id'] = documentId;
        propertyData['ownerId'] = DevUtils.devUserId;
        propertyData['ownerEmail'] = DevUtils.devUserEmail;
        propertyData['createdAt'] = DateTime.now();
        propertyData['updatedAt'] = DateTime.now();
        propertyData['isDev'] = true;

        try {
          await _firestore
              .collection('properties')
              .doc(documentId)
              .set(propertyData);
          DevUtils.log(
              'Successfully saved dev property to Firestore with ID: $documentId');

          // Create property model using a fake DocumentSnapshot
          final PropertyModel newProperty = PropertyModel.fromFirestore(
            FakeDocumentSnapshot(id: documentId, data: propertyData),
          );

          _properties = [newProperty, ..._properties];

          // Also update recent and featured properties
          await _updateRecentProperties();
          await _updateFeaturedProperties();

          notifyListeners();
        } catch (e) {
          DevUtils.log('Error in dev mode property creation: $e');
          // In dev mode, we'll still create the property in memory if Firestore fails
          final PropertyModel newProperty = PropertyModel.fromFirestore(
            FakeDocumentSnapshot(id: documentId, data: propertyData),
          );
          _properties = [newProperty, ..._properties];

          // Also update recent and featured properties
          await _updateRecentProperties();
          await _updateFeaturedProperties();

          notifyListeners();
        }
      } else {
        // Production mode code
        final currentUser = _auth.currentUser;
        if (currentUser == null) {
          throw Exception('User not authenticated');
        }

        propertyData['ownerId'] = currentUser.uid;
        propertyData['ownerEmail'] = currentUser.email;
        propertyData['createdAt'] = FieldValue.serverTimestamp();
        propertyData['updatedAt'] = FieldValue.serverTimestamp();

        final docRef =
            await _firestore.collection('properties').add(propertyData);
        documentId = docRef.id;
        await docRef.update({'id': documentId});

        await docRef.collection('history').add({
          'timestamp': FieldValue.serverTimestamp(),
          'changedBy': currentUser.email ?? currentUser.uid,
          'changedFields': ['created'],
          'action': 'create',
        });

        // Send notification to all users about new property
        await _notificationProvider.createPropertyNotification(
            property: PropertyModel(
              id: documentId,
              title: propertyData['title'] as String,
              description: propertyData['description'] as String,
              price: (propertyData['price'] as num).toDouble(),
              ownerId: currentUser.uid,
              bedrooms: propertyData['bedrooms'] as int,
              bathrooms: propertyData['bathrooms'] as int,
              area: propertyData['area'] as double,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              type: _stringToPropertyType(propertyData['type'] as String?),
              status:
                  _stringToPropertyStatus(propertyData['status'] as String?),
              propertyType: propertyData['propertyType'] as String? ?? 'House',
              listingType: propertyData['listingType'] as String? ?? 'sale',
            ),
            type: NotificationType.propertyListed,
            sendToAllUsers: true);

        // After successfully adding property, refresh all property lists
        await fetchProperties();
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      DevUtils.log('Error adding property: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods to convert strings to enums
  PropertyType _stringToPropertyType(String? type) {
    switch (type?.toLowerCase()) {
      case 'house':
        return PropertyType.house;
      case 'apartment':
        return PropertyType.apartment;
      case 'condo':
        return PropertyType.condo;
      case 'land':
        return PropertyType.land;
      case 'commercial':
        return PropertyType.commercial;
      default:
        return PropertyType.house;
    }
  }

  PropertyStatus _stringToPropertyStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'available':
        return PropertyStatus.available;
      case 'sold':
        return PropertyStatus.sold;
      case 'rented':
        return PropertyStatus.rented;
      case 'pending':
        return PropertyStatus.pending;
      case 'unavailable':
        return PropertyStatus.unavailable;
      default:
        return PropertyStatus.available;
    }
  }
}

// Helper class to create fake DocumentSnapshots
class FakeDocumentSnapshot implements DocumentSnapshot {
  @override
  final String id;
  final Map<String, dynamic> _data;

  FakeDocumentSnapshot({required this.id, required Map<String, dynamic> data})
      : _data = data;

  @override
  Map<String, dynamic> data() => _data;

  @override
  bool get exists => true;

  @override
  dynamic get(Object field) => _data[field];

  @override
  DocumentReference get reference =>
      FirebaseFirestore.instance.doc('properties/$id');

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  dynamic operator [](Object field) => _data[field];
}
