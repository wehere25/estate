
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/utils/dev_utils.dart';

/// Service class for interacting with Firestore database
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // User Collection Methods
  
  // Get current user data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }
  
  // Create or update user
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      await _firestore.collection('users').doc(user.uid).set(
        userData,
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Error saving user data: $e');
      rethrow;
    }
  }
  
  // Add property to user's saved properties
  Future<void> savePropertyToFavorites(String propertyId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      // Add to favorites collection first (for better querying)
      await _firestore.collection('favorites').add({
        'userId': user.uid,
        'propertyId': propertyId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Also add to user's saved properties array
      await _firestore.collection('users').doc(user.uid).update({
        'savedProperties': FieldValue.arrayUnion([propertyId]),
      });
      
      // Increment the property's favorite count
      await _firestore.collection('properties').doc(propertyId).update({
        'favoriteCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error saving property to favorites: $e');
      rethrow;
    }
  }
  
  // Remove property from user's saved properties
  Future<void> removePropertyFromFavorites(String propertyId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      // Remove from favorites collection
      final QuerySnapshot favSnapshot = await _firestore
        .collection('favorites')
        .where('userId', isEqualTo: user.uid)
        .where('propertyId', isEqualTo: propertyId)
        .get();
      
      for (final doc in favSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Also remove from user's saved properties array
      await _firestore.collection('users').doc(user.uid).update({
        'savedProperties': FieldValue.arrayRemove([propertyId]),
      });
      
      // Decrement the property's favorite count
      await _firestore.collection('properties').doc(propertyId).update({
        'favoriteCount': FieldValue.increment(-1),
      });
    } catch (e) {
      debugPrint('Error removing property from favorites: $e');
      rethrow;
    }
  }
  
  // Track property view
  Future<void> trackPropertyView(String propertyId) async {
    try {
      final user = _auth.currentUser;
      final userId = user?.uid ?? 'anonymous';
      
      // Add view to analytics
      await _firestore.collection('property_analytics').add({
        'propertyId': propertyId,
        'action': 'view',
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'deviceInfo': {
          'platform': kIsWeb ? 'web' : 'app',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      });
      
      // Increment the property's view count
      await _firestore.collection('properties').doc(propertyId).update({
        'viewCount': FieldValue.increment(1),
      });
      
      // If user is logged in, add to their viewed properties
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'viewedProperties': FieldValue.arrayUnion([propertyId]),
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Silently fail for analytics
      debugPrint('Error tracking property view: $e');
    }
  }
  
  // Property Collection Methods
  
  // Get property by ID
  Future<Map<String, dynamic>?> getPropertyById(String propertyId) async {
    try {
      final doc = await _firestore.collection('properties').doc(propertyId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() ?? {},
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error getting property: $e');
      return null;
    }
  }
  
  // Get featured properties
  Future<List<Map<String, dynamic>>> getFeaturedProperties({int limit = 10}) async {
    try {
      final snapshot = await _firestore
        .collection('properties')
        .where('featured', isEqualTo: true)
        .where('status', isEqualTo: 'active')
        .limit(limit)
        .get();
        
      return snapshot.docs.map<Map<String, dynamic>>((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      debugPrint('Error getting featured properties: $e');
      return [];
    }
  }
  
  // Get recent properties
  Future<List<Map<String, dynamic>>> getRecentProperties({int limit = 10}) async {
    try {
      final snapshot = await _firestore
        .collection('properties')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
        
      return snapshot.docs.map<Map<String, dynamic>>((doc) => {
        'id': doc.id,
        ...(doc.data() as Map<String, dynamic>),
      }).toList();
    } catch (e) {
      debugPrint('Error getting recent properties: $e');
      return [];
    }
  }
  
  // Search properties
  Future<List<Map<String, dynamic>>> searchProperties(String query, {Map<String, dynamic>? filters}) async {
    try {
      // Start with a base query
      Query propertiesQuery = _firestore
        .collection('properties')
        .where('status', isEqualTo: 'active');
      
      // Apply filters if provided
      if (filters != null) {
        if (filters['minPrice'] != null) {
          propertiesQuery = propertiesQuery.where('price', isGreaterThanOrEqualTo: filters['minPrice']);
        }
        if (filters['maxPrice'] != null) {
          propertiesQuery = propertiesQuery.where('price', isLessThanOrEqualTo: filters['maxPrice']);
        }
        if (filters['propertyType'] != null && filters['propertyType'] != 'Any') {
          propertiesQuery = propertiesQuery.where('propertyType', isEqualTo: filters['propertyType'].toString().toLowerCase());
        }
        if (filters['bedrooms'] != null && filters['bedrooms'] > 0) {
          propertiesQuery = propertiesQuery.where('bedrooms', isGreaterThanOrEqualTo: filters['bedrooms']);
        }
        if (filters['bathrooms'] != null && filters['bathrooms'] > 0) {
          propertiesQuery = propertiesQuery.where('bathrooms', isGreaterThanOrEqualTo: filters['bathrooms']);
        }
        if (filters['listingType'] != null) {
          propertiesQuery = propertiesQuery.where('listingType', isEqualTo: filters['listingType'].toString().toLowerCase());
        }
      }
      
      // Get results
      final snapshot = await propertiesQuery.get();
      
      // Filter by title or description containing query (client-side)
      if (query.isEmpty) {
        return snapshot.docs.map<Map<String, dynamic>>((doc) => {
          'id': doc.id,
          ...(doc.data() as Map<String, dynamic>),
        }).toList();
      }
      
      final results = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final title = (data['title'] as String).toLowerCase();
        final description = (data['description'] as String).toLowerCase();
        final address = (data['address'] as String?)?.toLowerCase() ?? '';
        final city = (data['city'] as String?)?.toLowerCase() ?? '';
        
        final searchLower = query.toLowerCase();
        
        return title.contains(searchLower) || 
               description.contains(searchLower) || 
               address.contains(searchLower) ||
               city.contains(searchLower);
      }).map<Map<String, dynamic>>((doc) => {
        'id': doc.id,
        ...(doc.data() as Map<String, dynamic>),
      }).toList();
      
      return results;
    } catch (e) {
      debugPrint('Error searching properties: $e');
      return [];
    }
  }
  
  // Upload images and return URLs
  Future<List<String>> uploadPropertyImages(List<File> images, String ownerId) async {
    if (DevUtils.isDev && DevUtils.bypassAuth) {
      // In dev mode, return mock image URLs
      DevUtils.log('Using mock file upload for property images');
      return images.map((image) => 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=800').toList();
    }
    
    List<String> imageUrls = [];
    try {
      for (final file in images) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
        final Reference storageRef = _storage.ref().child('properties/$ownerId/$fileName');
        
        // Upload file
        final UploadTask uploadTask = storageRef.putFile(file);
        final TaskSnapshot snapshot = await uploadTask;
        
        // Get download URL
        final String url = await snapshot.ref.getDownloadURL();
        imageUrls.add(url);
      }
      return imageUrls;
    } catch (e) {
      debugPrint('Error uploading images: $e');
      rethrow;
    }
  }
  
  // Create a new property
  Future<String?> createProperty(Map<String, dynamic> propertyData, List<File>? images) async {
    try {
      final user = _auth.currentUser;
      String ownerId = user?.uid ?? 'anonymous';
      
      // Handle dev mode
      if (DevUtils.isDev && DevUtils.bypassAuth) {
        ownerId = DevUtils.devUserId;
        DevUtils.log('Using dev mode for property creation');
      } else if (user == null) {
        return null;
      }
      
      // Upload images if provided
      if (images != null && images.isNotEmpty) {
        final imageUrls = await uploadPropertyImages(images, ownerId);
        propertyData['images'] = imageUrls;
      }
      
      // Add timestamps and user data
      propertyData['createdAt'] = FieldValue.serverTimestamp();
      propertyData['updatedAt'] = FieldValue.serverTimestamp();
      propertyData['createdBy'] = ownerId;
      propertyData['ownerId'] = ownerId;
      propertyData['viewCount'] = 0;
      propertyData['favoriteCount'] = 0;
      
      // Create the property
      final docRef = await _firestore.collection('properties').add(propertyData);
      
      // Add initial history record
      await docRef.collection('history').add({
        'timestamp': FieldValue.serverTimestamp(),
        'changedBy': ownerId,
        'changedFields': ['created'],
        'action': 'create',
      });
      
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating property: $e');
      return null;
    }
  }
  
  // Update a property
  Future<bool> updateProperty(String propertyId, Map<String, dynamic> propertyData, List<File>? newImages) async {
    try {
      final user = _auth.currentUser;
      String ownerId = user?.uid ?? 'anonymous';
      
      // Handle dev mode
      if (DevUtils.isDev && DevUtils.bypassAuth) {
        ownerId = DevUtils.devUserId;
        DevUtils.log('Using dev mode for property update');
      } else if (user == null) {
        return false;
      }
      
      // Upload new images if provided
      if (newImages != null && newImages.isNotEmpty) {
        final newImageUrls = await uploadPropertyImages(newImages, ownerId);
        
        // Get existing images
        final propertyDoc = await _firestore.collection('properties').doc(propertyId).get();
        List<String> existingImages = List<String>.from(propertyDoc.data()?['images'] ?? []);
        
        // Combine existing and new images
        propertyData['images'] = [...existingImages, ...newImageUrls];
      }
      
      // Add timestamp
      propertyData['updatedAt'] = FieldValue.serverTimestamp();
      
      // Update the property
      await _firestore.collection('properties').doc(propertyId).update(propertyData);
      
      // Add history record
      await _firestore.collection('properties').doc(propertyId).collection('history').add({
        'timestamp': FieldValue.serverTimestamp(),
        'changedBy': ownerId,
        'changedFields': propertyData.keys.toList(),
        'action': 'update',
      });
      
      return true;
    } catch (e) {
      debugPrint('Error updating property: $e');
      return false;
    }
  }
  
  // Delete a property
  Future<bool> deleteProperty(String propertyId) async {
    try {
      final user = _auth.currentUser;
      if (user == null && !(DevUtils.isDev && DevUtils.bypassAuth)) {
        return false;
      }
      
      String ownerId = user?.uid ?? DevUtils.devUserId;
      
      // Delete the property
      await _firestore.collection('properties').doc(propertyId).delete();
      
      // Note: This doesn't delete subcollections or storage files
      // In a production app, you would use Cloud Functions to clean up these resources
      
      return true;
    } catch (e) {
      debugPrint('Error deleting property: $e');
      return false;
    }
  }
  
  // Create an inquiry
  Future<bool> createInquiry(Map<String, dynamic> inquiryData) async {
    try {
      final user = _auth.currentUser;
      
      // Allow anonymous inquiries but track user if logged in
      inquiryData['userId'] = user?.uid ?? 'anonymous';
      inquiryData['createdAt'] = FieldValue.serverTimestamp();
      inquiryData['updatedAt'] = FieldValue.serverTimestamp();
      inquiryData['status'] = 'new';
      
      // Create the inquiry
      await _firestore.collection('inquiries').add(inquiryData);
      
      return true;
    } catch (e) {
      debugPrint('Error creating inquiry: $e');
      return false;
    }
  }
  
  // Get user favorites
  Future<List<Map<String, dynamic>>> getUserFavorites() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];
      
      // Get favorites from the dedicated collection
      final snapshot = await _firestore
        .collection('favorites')
        .where('userId', isEqualTo: user.uid)
        .get();
      
      // Get propertyIds from favorites
      final propertyIds = snapshot.docs.map((doc) => doc.data()['propertyId'] as String).toList();
      
      // If no favorites, return empty list
      if (propertyIds.isEmpty) return [];
      
      // Get property details for each favorite
      List<Map<String, dynamic>> favorites = [];
      
      // Use batched gets for better performance
      for (int i = 0; i < propertyIds.length; i += 10) {
        final batch = propertyIds.sublist(i, i + 10 > propertyIds.length ? propertyIds.length : i + 10);
        final propertyRefs = batch.map((id) => _firestore.collection('properties').doc(id)).toList();
        final propertySnapshots = await Future.wait(propertyRefs.map((ref) => ref.get()));
        
        for (final doc in propertySnapshots) {
          if (doc.exists) {
            favorites.add({
              'id': doc.id,
              ...doc.data() ?? {},
            });
          }
        }
      }
      
      return favorites;
    } catch (e) {
      debugPrint('Error getting user favorites: $e');
      return [];
    }
  }
  
  // Get inquiries for a property
  Future<List<Map<String, dynamic>>> getPropertyInquiries(String propertyId) async {
    try {
      final user = _auth.currentUser;
      if (user == null && !(DevUtils.isDev && DevUtils.bypassAuth)) return [];
      
      final snapshot = await _firestore
        .collection('inquiries')
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('createdAt', descending: true)
        .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting property inquiries: $e');
      return [];
    }
  }
  
  // Get user's properties
  Future<List<Map<String, dynamic>>> getUserProperties() async {
    try {
      final user = _auth.currentUser;
      String ownerId;
      
      if (user != null) {
        ownerId = user.uid;
      } else if (DevUtils.isDev && DevUtils.bypassAuth) {
        ownerId = DevUtils.devUserId;
        DevUtils.log('Using dev user ID for getUserProperties');
      } else {
        return [];
      }
      
      final snapshot = await _firestore
        .collection('properties')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting user properties: $e');
      return [];
    }
  }
}
