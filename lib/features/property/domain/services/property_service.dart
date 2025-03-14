import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property_model.dart';
import '../../../../core/utils/debug_logger.dart';
import '../../../../core/utils/dev_utils.dart';

/// Service class for handling property-related operations
class PropertyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch a property by its ID
  Future<PropertyModel> getPropertyById(String id) async {
    try {
      // First try to get the property from Firestore, even in dev mode
      try {
        final docSnapshot =
            await _firestore.collection('properties').doc(id).get();

        if (docSnapshot.exists) {
          return PropertyModel.fromFirestore(docSnapshot);
        }
      } catch (e) {
        DebugLogger.error('Firestore query failed', e);
      }

      // If property doesn't exist in Firestore and we're in dev mode
      if (DevUtils.isDev && id.startsWith('dev-')) {
        // Try to find it in our mock properties
        final mockProperties = _getMockProperties();
        final mockProperty = mockProperties.firstWhere(
          (p) => p.id == id,
          orElse: () =>
              _getMockProperty(id), // Generate a consistent mock if not found
        );
        return mockProperty;
      }

      // If we get here, the property truly doesn't exist
      throw Exception('Property not found');
    } catch (e) {
      DebugLogger.error('Failed to get property by ID: $id', e);
      throw Exception('Error loading property: ${e.toString()}');
    }
  }

  /// Fetch all properties
  Future<List<PropertyModel>> getAllProperties({
    String? filterType,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      // Always attempt to fetch real data first
      try {
        Query query = _firestore.collection('properties');

        if (filterType != null) {
          query = query.where('listingType', isEqualTo: filterType);
        }

        query = query.orderBy('createdAt', descending: true);

        if (lastDocument != null) {
          query = query.startAfterDocument(lastDocument);
        }

        query = query.limit(limit);

        final querySnapshot = await query.get();

        // If we have results from Firestore, use them
        if (querySnapshot.docs.isNotEmpty) {
          return querySnapshot.docs
              .map((doc) => PropertyModel.fromFirestore(doc))
              .toList();
        }
      } catch (e) {
        DebugLogger.error('Firestore query failed', e);
      }

      // Only fall back to mock data if we're in dev mode and got no Firestore results
      if (DevUtils.isDev) {
        DebugLogger.info(
            '🛠️ DEV: Using mock data as fallback for property listing');
        return _getMockProperties();
      }

      // If not in dev mode or no mock data available, return empty list
      return [];
    } catch (e) {
      DebugLogger.error('Failed to get properties', e);
      throw Exception('Error loading properties: ${e.toString()}');
    }
  }

  /// Get featured properties
  Future<List<PropertyModel>> getFeaturedProperties({int limit = 10}) async {
    try {
      // Always attempt to fetch real data first, even in development mode
      try {
        // Query for featured properties
        final querySnapshot = await _firestore
            .collection('properties')
            .where('featured', isEqualTo: true)
            .where('isApproved', isEqualTo: true)
            .limit(limit)
            .get();

        // If we have results, use them
        if (querySnapshot.docs.isNotEmpty) {
          return querySnapshot.docs
              .map((doc) => PropertyModel.fromFirestore(doc))
              .toList();
        }
      } catch (firestoreError) {
        // Log the Firestore error but continue to fallback in dev mode
        DebugLogger.error('Firestore featured query failed', firestoreError);
      }

      // Only fall back to mock data if there's truly no data in Firestore and we're in dev mode
      if (DevUtils.isDev) {
        DebugLogger.info(
            '🛠️ DEV: Using mock data as fallback for featured properties');
        return _getMockProperties().where((p) => p.featured).toList();
      }

      // If we're not in dev mode and Firestore returned no results, return empty list
      return [];
    } catch (e) {
      DebugLogger.error('Failed to get featured properties', e);
      throw Exception('Error loading featured properties: ${e.toString()}');
    }
  }

  /// Get properties for a specific owner
  Future<List<PropertyModel>> getPropertiesByOwner(String ownerId) async {
    try {
      // Always try to get real data first, even in development mode
      try {
        // Query for properties by owner
        final querySnapshot = await _firestore
            .collection('properties')
            .where('ownerId', isEqualTo: ownerId)
            .get();

        // If we have results, use them
        if (querySnapshot.docs.isNotEmpty) {
          return querySnapshot.docs
              .map((doc) => PropertyModel.fromFirestore(doc))
              .toList();
        }
      } catch (firestoreError) {
        // Log the Firestore error but continue to fallback in dev mode
        DebugLogger.error('Firestore owner query failed', firestoreError);
      }

      // Only fall back to mock data for the dev user ID if there's no real data
      if (DevUtils.isDev &&
          (ownerId == 'dev-user-123' || ownerId.contains('example'))) {
        DebugLogger.info(
            '🛠️ DEV: Using mock data as fallback for owner properties');
        return _getMockProperties().where((p) => p.ownerId == ownerId).toList();
      }

      // If not in dev mode or not a dev user, return empty list when no results
      return [];
    } catch (e) {
      DebugLogger.error('Failed to get properties by owner: $ownerId', e);
      throw Exception('Error loading your properties: ${e.toString()}');
    }
  }

  // Create a mock property for development mode
  PropertyModel _getMockProperty(String id) {
    // Use a consistent seed based on the ID to get the same property for the same ID
    final idHash = id.hashCode;
    final isFeatured = idHash % 3 == 0;
    final isForSale = idHash % 2 == 0;

    return PropertyModel(
      id: id,
      title: 'Mock Property #${idHash.abs() % 1000}',
      description:
          'This is a detailed description of this property. It includes multiple features and highlights of the property.',
      price: 100000 + (idHash.abs() % 900000),
      location: 'Sample Location #${idHash.abs() % 10}',
      bedrooms: 1 + (idHash.abs() % 5),
      bathrooms: 1 + (idHash.abs() % 3),
      area: 800 + (idHash.abs() % 2000),
      images: [
        'https://images.unsplash.com/photo-1568605114967-8130f3a36994?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        'https://images.unsplash.com/photo-1560184897-ae75f418493e?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
      ],
      featured: isFeatured,
      isApproved: true,
      listingType: isForSale ? 'sale' : 'rent',
      amenities: ['Pool', 'Garden', 'Garage', 'Security System'],
      ownerId: 'dev-user-123',
      createdAt: DateTime.now().subtract(Duration(days: idHash.abs() % 30)),
      updatedAt: DateTime.now().subtract(Duration(days: idHash.abs() % 15)),
      type: PropertyType.house,
      status: PropertyStatus.available,
      propertyType: 'House',
    );
  }

  // Create mock properties for development mode - only used as fallback
  List<PropertyModel> _getMockProperties() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    return [
      PropertyModel(
        id: 'mock-$timestamp-1',
        title: 'Luxury Villa with Pool',
        description: 'Beautiful 4-bedroom villa with a private pool and garden',
        price: 750000,
        location: 'Palm Beach, FL',
        bedrooms: 4,
        bathrooms: 3,
        area: 2800,
        images: [
          'https://images.unsplash.com/photo-1613490493576-7fde63acd811?ixlib=rb-4.0.3',
          'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?ixlib=rb-4.0.3',
        ],
        featured: true,
        isApproved: true,
        listingType: 'sale',
        amenities: ['Pool', 'Garden', 'Garage', 'Security System'],
        ownerId: 'dev-user-123',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        type: PropertyType.house,
        status: PropertyStatus.available,
        propertyType: 'House',
      ),
      PropertyModel(
        id: 'dev-$timestamp-2',
        title: 'Modern Downtown Apartment',
        description: 'Sleek 2-bedroom apartment in the heart of downtown',
        price: 2500,
        location: 'Downtown, NY',
        bedrooms: 2,
        bathrooms: 2,
        area: 1200,
        images: [
          'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?ixlib=rb-4.0.3',
        ],
        featured: false,
        isApproved: true,
        listingType: 'rent',
        amenities: ['Gym', 'Doorman', 'Elevator', 'Parking'],
        ownerId: 'dev-user-123',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        type: PropertyType.apartment,
        status: PropertyStatus.available,
        propertyType: 'Apartment',
      ),
      PropertyModel(
        id: 'dev-$timestamp-3',
        title: 'Beachfront Property',
        description: 'Stunning beachfront property with panoramic ocean views',
        price: 1200000,
        location: 'Malibu, CA',
        bedrooms: 5,
        bathrooms: 4,
        area: 3500,
        images: [
          'https://images.unsplash.com/photo-1513584684374-8bab748fbf90?ixlib=rb-4.0.3',
        ],
        featured: true,
        isApproved: false, // Not approved
        listingType: 'sale',
        amenities: ['Private Beach', 'Hot Tub', 'Home Theater', 'Wine Cellar'],
        ownerId: 'dev-user-456',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
        type: PropertyType.house,
        status: PropertyStatus.pending,
        propertyType: 'House',
      ),
      PropertyModel(
        id: 'dev-$timestamp-4',
        title: 'Family Home in Suburbs',
        description: 'Spacious family home with large backyard in quiet suburb',
        price: 450000,
        location: 'Naperville, IL',
        bedrooms: 4,
        bathrooms: 2,
        area: 2200,
        images: [
          'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?ixlib=rb-4.0.3',
        ],
        featured: false,
        isApproved: true,
        listingType: 'sale',
        amenities: ['Backyard', 'Finished Basement', 'Deck', 'Fireplace'],
        ownerId: 'dev-user-123',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 8)),
        type: PropertyType.house,
        status: PropertyStatus.available,
        propertyType: 'House',
      ),
      PropertyModel(
        id: 'dev-$timestamp-5',
        title: 'Cozy Studio Apartment',
        description: 'Perfect starter apartment near university campus',
        price: 1100,
        location: 'Cambridge, MA',
        bedrooms: 0,
        bathrooms: 1,
        area: 500,
        images: [
          'https://images.unsplash.com/photo-1502672023488-70e25813eb80?ixlib=rb-4.0.3',
        ],
        featured: false,
        isApproved: true,
        listingType: 'rent',
        amenities: ['Utilities Included', 'Laundry', 'Wifi'],
        ownerId: 'dev-user-789',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        type: PropertyType.apartment,
        status: PropertyStatus.available,
        propertyType: 'Studio',
      ),
    ];
  }
}
