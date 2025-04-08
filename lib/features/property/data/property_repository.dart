import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/property_model.dart';
import 'models/property_dto.dart';
import '../../../firebase/services/firestore_service.dart';
import '../../../core/utils/exceptions/app_exception.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/dev_utils.dart';

class PropertyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService? _firestoreService;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  static const String _collection = 'properties';

  PropertyRepository([FirestoreService? firestoreService])
      : _firestoreService = firestoreService;

  // Method using FirestoreService for abstracted queries
  Future<List<PropertyDto>> fetchPropertiesWithService({
    DocumentSnapshot? startAfter,
    Query Function(Query)? queryBuilder,
    int limit = 10,
  }) async {
    if (_firestoreService == null) {
      throw AppException('FirestoreService not initialized');
    }

    try {
      final snapshot = await _firestoreService!.queryCollection(
        _collection,
        queryBuilder: queryBuilder ?? ((query) => query),
        limit: limit,
        startAfter: startAfter,
      );
      return snapshot.docs
          .map((doc) => PropertyDto.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw AppException('Failed to fetch properties: $e');
    }
  }

  // Improved Direct Firestore query method with proper filtering
  Future<List<PropertyModel>> fetchProperties(
      {Map<String, dynamic>? filters}) async {
    try {
      Query query = _firestore.collection('properties');

      // Apply filters if provided
      if (filters != null) {
        // Apply property type filter
        if (filters.containsKey('propertyType') &&
            filters['propertyType'] != null) {
          query =
              query.where('propertyType', isEqualTo: filters['propertyType']);
        }

        // Apply listing type filter (sale/rent)
        if (filters.containsKey('listingType') &&
            filters['listingType'] != null) {
          final listingType = filters['listingType'].toString();
          query = query.where('listingType', isEqualTo: listingType);
        }

        // Apply price range filters
        if (filters.containsKey('minPrice') && filters['minPrice'] != null) {
          query =
              query.where('price', isGreaterThanOrEqualTo: filters['minPrice']);
        }

        if (filters.containsKey('maxPrice') && filters['maxPrice'] != null) {
          query =
              query.where('price', isLessThanOrEqualTo: filters['maxPrice']);
        }

        // Apply sorting
        if (filters.containsKey('sortBy') && filters['sortBy'] != null) {
          final sortDirection =
              filters['sortDirection'] == 'asc' ? false : true;
          query = query.orderBy(filters['sortBy'], descending: sortDirection);
        } else {
          // Default sort by createdAt descending (newest first)
          query = query.orderBy('createdAt', descending: true);
        }

        // Apply limit
        if (filters.containsKey('limit') && filters['limit'] != null) {
          query = query.limit(filters['limit']);
        }
      } else {
        // Default sort by createdAt descending (newest first)
        query = query.orderBy('createdAt', descending: true);
      }

      // Execute the query
      final snapshot = await query.get();

      // Debug logging
      DevUtils.log('Fetched ${snapshot.docs.length} properties from Firestore');

      // Convert to PropertyModel objects
      final properties =
          snapshot.docs.map((doc) => PropertyModel.fromFirestore(doc)).toList();

      // Additional in-memory filtering that's not easily done in Firestore
      if (filters != null) {
        // Filter by bedrooms
        if (filters.containsKey('minBedrooms') &&
            filters['minBedrooms'] != null) {
          properties.removeWhere((p) => p.bedrooms < filters['minBedrooms']);
        }

        if (filters.containsKey('maxBedrooms') &&
            filters['maxBedrooms'] != null) {
          properties.removeWhere((p) => p.bedrooms > filters['maxBedrooms']);
        }

        // Filter by bathrooms
        if (filters.containsKey('minBathrooms') &&
            filters['minBathrooms'] != null) {
          properties.removeWhere((p) => p.bathrooms < filters['minBathrooms']);
        }

        if (filters.containsKey('maxBathrooms') &&
            filters['maxBathrooms'] != null) {
          properties.removeWhere((p) => p.bathrooms > filters['maxBathrooms']);
        }

        // Filter by location (text search)
        if (filters.containsKey('location') &&
            filters['location'] != null &&
            filters['location'].toString().isNotEmpty) {
          final locationQuery = filters['location'].toString().toLowerCase();
          properties.removeWhere((p) =>
              p.location == null ||
              !p.location!.toLowerCase().contains(locationQuery));
        }

        // Filter by amenities - handle both string and list formats
        if (filters.containsKey('amenities') && filters['amenities'] != null) {
          final amenities = filters['amenities'];

          if (amenities is List) {
            // If amenities is a list, filter properties that contain ALL specified amenities
            properties.removeWhere((property) {
              if (property.amenities == null || property.amenities!.isEmpty) {
                return true; // Remove if property has no amenities
              }

              // Check if property has all the requested amenities
              for (final amenity in amenities) {
                if (!property.amenities!.contains(amenity)) {
                  return true; // Remove if any amenity is missing
                }
              }
              return false; // Keep if all amenities are present
            });
          } else if (amenities is String) {
            // If amenities is a single string, filter for that one amenity
            properties.removeWhere((property) =>
                property.amenities == null ||
                !property.amenities!.contains(amenities));
          }
        }
      }

      return properties;
    } catch (e) {
      DevUtils.log('Error fetching properties: $e');
      throw Exception('Failed to fetch properties: $e');
    }
  }

  // Get property by ID with FirestoreService
  Future<PropertyDto> getPropertyByIdWithService(String id) async {
    if (_firestoreService == null) {
      throw AppException('FirestoreService not initialized');
    }

    try {
      final doc = await _firestoreService!.getDocument(_collection, id);
      if (!doc.exists) {
        throw AppException('Property not found');
      }
      return PropertyDto.fromFirestore(doc);
    } catch (e) {
      throw AppException('Failed to get property: $e');
    }
  }

  // Improved Direct Firestore query for property by ID
  Future<PropertyModel?> getPropertyById(String id) async {
    try {
      DevUtils.log('Fetching property by ID: $id');
      final doc = await _firestore.collection('properties').doc(id).get();

      if (!doc.exists) {
        DevUtils.log('Property not found with ID: $id');
        throw Exception('Property not found');
      }

      DevUtils.log('Property found, creating model from Firestore document');
      return PropertyModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('PropertyRepository: Error fetching property by ID - $e');
      rethrow; // Rethrow to handle at higher levels
    }
  }

  Future<String> addProperty(PropertyDto property) async {
    if (_firestoreService == null) {
      throw AppException('FirestoreService not initialized');
    }

    try {
      final docRef = await _firestoreService!.addDocument(
        _collection,
        property.toJson(),
      );
      return docRef.id;
    } catch (e) {
      throw AppException('Failed to add property: $e');
    }
  }

  Future<void> updateProperty(String id, Map<String, dynamic> data) async {
    if (_firestoreService == null) {
      throw AppException('FirestoreService not initialized');
    }

    try {
      if (id.isEmpty) throw AppException('Invalid property ID');
      await _firestoreService!.updateDocument(_collection, id, data);
    } catch (e) {
      throw AppException('Failed to update property: $e');
    }
  }

  Future<void> deleteProperty(String id) async {
    if (_firestoreService == null) {
      throw AppException('FirestoreService not initialized');
    }

    try {
      if (id.isEmpty) throw AppException('Invalid property ID');
      await _firestoreService!.deleteDocument(_collection, id);
    } catch (e) {
      throw AppException('Failed to delete property: $e');
    }
  }

  Stream<List<PropertyDto>> watchProperties({
    Query Function(Query)? queryBuilder,
  }) {
    if (_firestoreService == null) {
      throw AppException('FirestoreService not initialized');
    }

    return _firestoreService!
        .watchCollection(
          _collection,
          queryBuilder: queryBuilder,
        )
        .map((snapshot) => snapshot.docs
            .map((doc) => PropertyDto.fromFirestore(doc))
            .toList());
  }

  Future<List<PropertyModel>> fetchFeaturedProperties() async {
    try {
      final snapshot = await _firestore
          .collection('properties')
          .where('featured', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => PropertyModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('PropertyRepository: Error fetching featured properties - $e');
      return [];
    }
  }

  Future<List<PropertyModel>> searchProperties(String query) async {
    try {
      final lowerQuery = query.toLowerCase();
      final snapshot = await _firestore.collection('properties').get();

      return snapshot.docs
          .map((doc) => PropertyModel.fromFirestore(doc))
          .where((property) {
        final titleMatch = property.title.toLowerCase().contains(lowerQuery);
        final descriptionMatch =
            property.description.toLowerCase().contains(lowerQuery);
        final locationMatch = property.location != null &&
            property.location?.toLowerCase().contains(lowerQuery) == true;
        return titleMatch || descriptionMatch || locationMatch;
      }).toList();
    } catch (e) {
      throw Exception('Failed to search properties: $e');
    }
  }

  // Fix comparing property with type
  Future<List<PropertyModel>> getPropertiesByType(PropertyType type) async {
    try {
      final querySnapshot = await _firestore
          .collection('properties')
          .where('type', isEqualTo: type.toString().split('.').last)
          .get();

      return querySnapshot.docs
          .map((doc) => PropertyModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get properties by type: $e');
    }
  }

  // Fix argument type in filter
  Future<List<PropertyModel>> getFilteredProperties({
    double? minPrice,
    double? maxPrice,
    int? minBedrooms,
    int? maxBedrooms,
    PropertyType? propertyType,
    String? location,
  }) async {
    try {
      Query query = _firestore.collection('properties');

      if (minPrice != null) {
        query = query.where('price', isGreaterThanOrEqualTo: minPrice);
      }

      if (maxPrice != null) {
        query = query.where('price', isLessThanOrEqualTo: maxPrice);
      }

      if (propertyType != null) {
        query = query.where('type',
            isEqualTo: propertyType.toString().split('.').last);
      }

      final querySnapshot = await query.get();

      List<PropertyModel> properties = querySnapshot.docs
          .map((doc) => PropertyModel.fromFirestore(doc))
          .toList();

      // Filter by location if provided (do this in memory since Firestore doesn't support text search well)
      if (location != null && location.isNotEmpty) {
        properties = properties.where((property) {
          final propertyLocation = property.location;
          if (propertyLocation == null) return false;
          return propertyLocation
              .toLowerCase()
              .contains(location.toLowerCase());
        }).toList();
      }

      // Apply bedroom filters in memory
      if (minBedrooms != null) {
        properties = properties
            .where((property) => property.bedrooms >= minBedrooms)
            .toList();
      }

      if (maxBedrooms != null) {
        properties = properties
            .where((property) => property.bedrooms <= maxBedrooms)
            .toList();
      }

      return properties;
    } catch (e) {
      throw Exception('Failed to get filtered properties: $e');
    }
  }

  Future<String> uploadImage(File imageFile) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = _firebaseStorage.ref().child('property_images/$fileName');
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<String> createProperty(PropertyDto property) async {
    try {
      final docRef =
          await _firestore.collection(_collection).add(property.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create property: $e');
    }
  }

  Future<List<String>> uploadPropertyImages(List<File> images) async {
    try {
      final List<String> urls = [];
      for (final image in images) {
        final url = await uploadImage(image);
        urls.add(url);
      }
      return urls;
    } catch (e) {
      throw Exception('Failed to upload property images: $e');
    }
  }
}
