import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/dev_utils.dart';

/// Helper class to initialize the Firestore database with required collections and documents
class FirestoreSetup {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Initialize the database with necessary structures
  Future<void> initializeDatabase() async {
    try {
      // Only run this in development mode
      if (!DevUtils.isDev) return;
      
      DevUtils.log('Initializing Firestore database structure');
      
      // Create first admin user (current user if authenticated)
      await _setupAdminUser();
      
      // Create example property data if needed
      await _createExampleProperties();
      
      DevUtils.log('Firestore database initialization complete');
    } catch (e) {
      debugPrint('Error initializing Firestore: $e');
    }
  }
  
  // Set up the current user as admin
  Future<void> _setupAdminUser() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('No user signed in, skipping admin setup');
        return;
      }
      
      // Check if user document exists
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      
      // Create or update user document with admin role
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(currentUser.uid).set({
          'email': currentUser.email,
          'displayName': currentUser.displayName ?? 'Admin User',
          'photoURL': currentUser.photoURL,
          'role': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
          'savedProperties': [],
          'viewedProperties': []
        });
        
        // Add to admin_users collection
        await _firestore.collection('admin_users').doc(currentUser.uid).set({
          'email': currentUser.email,
          'grantedBy': 'system',
          'grantedAt': FieldValue.serverTimestamp(),
        });
        
        DevUtils.log('Created admin user: ${currentUser.email}');
      } else if (userDoc.data()?['role'] != 'admin') {
        // Update to admin if not already
        await _firestore.collection('users').doc(currentUser.uid).update({
          'role': 'admin',
          'lastActive': FieldValue.serverTimestamp(),
        });
        
        // Add to admin_users collection if not already there
        final adminDoc = await _firestore.collection('admin_users').doc(currentUser.uid).get();
        if (!adminDoc.exists) {
          await _firestore.collection('admin_users').doc(currentUser.uid).set({
            'email': currentUser.email,
            'grantedBy': 'system',
            'grantedAt': FieldValue.serverTimestamp(),
          });
        }
        
        DevUtils.log('Updated user to admin: ${currentUser.email}');
      }
    } catch (e) {
      debugPrint('Error setting up admin user: $e');
    }
  }
  
  // Create example properties for development
  Future<void> _createExampleProperties() async {
    try {
      // Check if we already have properties
      final propertiesSnapshot = await _firestore.collection('properties').limit(1).get();
      
      // Skip if we already have properties
      if (propertiesSnapshot.docs.isNotEmpty) {
        DevUtils.log('Example properties already exist, skipping creation');
        return;
      }
      
      // Create example properties
      final examples = _getExampleProperties();
      
      for (final property in examples) {
        await _firestore.collection('properties').add({
          ...property,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdBy': _auth.currentUser?.uid ?? 'system',
          'ownerId': _auth.currentUser?.uid ?? 'system',
          'viewCount': 0,
          'favoriteCount': 0,
        });
      }
      
      DevUtils.log('Created ${examples.length} example properties');
    } catch (e) {
      debugPrint('Error creating example properties: $e');
    }
  }
  
  // Example property data
  List<Map<String, dynamic>> _getExampleProperties() {
    return [
      {
        'title': 'Luxury Villa with Swimming Pool',
        'description': 'Beautiful luxury villa with 4 bedrooms, swimming pool, and garden in a peaceful neighborhood.',
        'price': 12500000,
        'location': const GeoPoint(34.0837, 74.7973), // Srinagar, Kashmir
        'address': '123 Lake View Road',
        'city': 'Srinagar',
        'zipCode': '190001',
        'propertyType': 'villa',
        'listingType': 'sale',
        'bedrooms': 4,
        'bathrooms': 3,
        'area': 3200,
        'images': [
          'https://images.unsplash.com/photo-1613977257363-707ba9348227?ixlib=rb-4.0.3&q=85&fm=jpg&crop=entropy&cs=srgb&w=800',
          'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?ixlib=rb-4.0.3&q=85&fm=jpg&crop=entropy&cs=srgb&w=800',
        ],
        'amenities': ['Swimming Pool', 'Garden', 'Parking', 'Air Conditioning', 'Security'],
        'status': 'active',
        'featured': true,
        'latitude': 34.0837,
        'longitude': 74.7973,
      },
      {
        'title': 'Modern Apartment in City Center',
        'description': 'Spacious 2-bedroom apartment with modern amenities in the heart of the city.',
        'price': 4500000,
        'location': const GeoPoint(34.0900, 74.7900), // Srinagar, Kashmir
        'address': '45 City Center Road',
        'city': 'Srinagar',
        'zipCode': '190008',
        'propertyType': 'apartment',
        'listingType': 'sale',
        'bedrooms': 2,
        'bathrooms': 2,
        'area': 1200,
        'images': [
          'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?ixlib=rb-4.0.3&q=85&fm=jpg&crop=entropy&cs=srgb&w=800',
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?ixlib=rb-4.0.3&q=85&fm=jpg&crop=entropy&cs=srgb&w=800',
        ],
        'amenities': ['Elevator', 'Parking', 'Security', 'Gym'],
        'status': 'active',
        'featured': false,
        'latitude': 34.0900,
        'longitude': 74.7900,
      },
      {
        'title': 'Charming Cottage Near Dal Lake',
        'description': 'Beautiful 3-bedroom cottage with stunning lake views and traditional architecture.',
        'price': 8000000,
        'location': const GeoPoint(34.0910, 74.8500), // Near Dal Lake, Kashmir
        'address': '78 Lake Side Road',
        'city': 'Srinagar',
        'zipCode': '190005',
        'propertyType': 'house',
        'listingType': 'sale',
        'bedrooms': 3,
        'bathrooms': 2,
        'area': 1800,
        'images': [
          'https://images.unsplash.com/photo-1575517111839-3a3843ee7f5d?ixlib=rb-4.0.3&q=85&fm=jpg&crop=entropy&cs=srgb&w=800',
          'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?ixlib=rb-4.0.3&q=85&fm=jpg&crop=entropy&cs=srgb&w=800',
        ],
        'amenities': ['Lake View', 'Garden', 'Fireplace', 'Parking'],
        'status': 'active',
        'featured': true,
        'latitude': 34.0910,
        'longitude': 74.8500,
      },
    ];
  }
}
