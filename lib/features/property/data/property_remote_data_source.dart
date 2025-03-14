import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/exceptions/app_exception.dart';
import 'models/property_dto.dart';

class PropertyRemoteDataSource {
  final FirebaseFirestore _firestore;
  static const String _collection = 'properties';
  static const int _pageSize = 20;

  PropertyRemoteDataSource([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<PropertyDto>> getProperties({
    DocumentSnapshot? lastDocument,
    Map<String, dynamic>? filters,
  }) async {
    try {
      var query = _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      if (filters != null) {
        query = _applyFilters(query, filters);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => PropertyDto.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw StorageException('Failed to fetch properties: $e');
    }
  }

  Future<PropertyDto> getProperty(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      
      if (!doc.exists) {
        throw StorageException('Property not found');
      }
      
      return PropertyDto.fromFirestore(doc);
    } catch (e) {
      throw StorageException('Failed to fetch property: $e');
    }
  }

  Future<void> uploadProperty(PropertyDto property) async {
    try {
      final batch = _firestore.batch();
      final propertyRef = _firestore.collection(_collection).doc();

      batch.set(propertyRef, {
        ...property.toJson(),
        'id': propertyRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update property stats
      final statsRef = _firestore.collection('stats').doc('properties');
      batch.set(statsRef, {
        'totalCount': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      throw StorageException('Failed to upload property: $e');
    }
  }

  Future<void> updateProperty(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw StorageException('Failed to update property: $e');
    }
  }

  Future<void> deleteProperty(String id) async {
    try {
      final batch = _firestore.batch();
      
      // Mark property as inactive instead of deleting
      batch.update(_firestore.collection(_collection).doc(id), {
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });

      // Update property stats
      batch.set(_firestore.collection('stats').doc('properties'), {
        'totalCount': FieldValue.increment(-1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      throw StorageException('Failed to delete property: $e');
    }
  }

  Stream<List<PropertyDto>> watchProperties({Map<String, dynamic>? filters}) {
    var query = _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(_pageSize);

    if (filters != null) {
      query = _applyFilters(query, filters);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => PropertyDto.fromFirestore(doc)).toList());
  }

  Query<Map<String, dynamic>> _applyFilters(
    Query<Map<String, dynamic>> query,
    Map<String, dynamic> filters,
  ) {
    if (filters['minPrice'] != null) {
      query = query.where('price', isGreaterThanOrEqualTo: filters['minPrice']);
    }
    
    if (filters['maxPrice'] != null) {
      query = query.where('price', isLessThanOrEqualTo: filters['maxPrice']);
    }
    
    if (filters['propertyType'] != null) {
      query = query.where('type', isEqualTo: filters['propertyType']);
    }
    
    if (filters['bedrooms'] != null) {
      query = query.where('bedrooms', isEqualTo: filters['bedrooms']);
    }

    if (filters['location'] != null) {
      query = query.where('location', isEqualTo: filters['location']);
    }

    if (filters['isFeatured'] == true) {
      query = query.where('isFeatured', isEqualTo: true);
    }

    return query;
  }
}

class StorageException implements Exception {
  final String message;
  StorageException(this.message);
  @override
  String toString() => 'StorageException: $message';
}
