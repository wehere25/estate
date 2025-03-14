import 'package:cloud_firestore/cloud_firestore.dart';

enum PropertyType { house, apartment, condo, townhouse, land, commercial }

enum PropertyStatus { available, pending, sold, rented }

class PropertyOwner {
  final String uid;
  final String? name;
  final String? email;
  final String? photoUrl;

  PropertyOwner({
    required this.uid,
    this.name,
    this.email,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
    };
  }

  factory PropertyOwner.fromMap(Map<String, dynamic> map) {
    return PropertyOwner(
      uid: map['uid'] ?? '',
      name: map['name'],
      email: map['email'],
      photoUrl: map['photoUrl'],
    );
  }
}

class PropertyModel {
  final String? id;
  final String title;
  final double price;
  final String? location;
  final String description;
  final int bedrooms;
  final int bathrooms;
  final double area;
  final List<String>? images;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PropertyType type;
  final PropertyStatus status;
  final String propertyType;
  final String listingType;
  final PropertyOwner? owner;
  final String? ownerId;
  final bool featured;
  final List<String>? amenities; // Added amenities field
  final bool isApproved; // Changed from getter to property
  final DateTime? lastReviewedAt; // Track when admin last reviewed it
  final String? reviewedBy; // Track which admin reviewed it
  final String? adminNotes; // Field for admin notes/comments
  final Map<String, dynamic>? moderationData; // Store moderation history/data

  PropertyModel({
    this.id,
    required this.title,
    required this.price,
    this.location,
    required this.description,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    this.images,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
    required this.type,
    required this.status,
    required this.propertyType,
    required this.listingType,
    this.owner,
    this.ownerId,
    this.featured = false,
    this.amenities,
    this.isApproved = true, // Default to true
    this.lastReviewedAt,
    this.reviewedBy,
    this.adminNotes,
    this.moderationData,
  });

  // Updated to support direct conversion from Firestore document
  factory PropertyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PropertyModel(
      id: doc.id,
      title: data['title'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      location: data['location'],
      description: data['description'] ?? '',
      bedrooms: data['bedrooms'] ?? 0,
      bathrooms: data['bathrooms'] ?? 0,
      area: (data['area'] ?? 0).toDouble(),
      images: (data['images'] as List?)?.map((e) => e as String).toList(),
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: _parsePropertyType(data['type'] ?? 'house'),
      status: _parsePropertyStatus(data['status'] ?? 'available'),
      propertyType: data['propertyType'] ?? 'House',
      listingType: data['listingType'] ?? 'Sale',
      ownerId: data['ownerId'],
      owner:
          data['owner'] != null ? PropertyOwner.fromMap(data['owner']) : null,
      featured: data['featured'] ?? false,
      amenities: (data['amenities'] as List?)
          ?.map((e) => e as String)
          .toList(), // Parse amenities
      isApproved: data['isApproved'] ?? true,
      lastReviewedAt: (data['lastReviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: data['reviewedBy'],
      adminNotes: data['adminNotes'],
      moderationData: data['moderationData'] as Map<String, dynamic>?,
    );
  }

  // Helper method to parse property type string to enum
  static PropertyType _parsePropertyType(String typeStr) {
    try {
      return PropertyType.values.firstWhere(
        (e) =>
            e.toString() == 'PropertyType.$typeStr' ||
            e.toString().split('.').last.toLowerCase() == typeStr.toLowerCase(),
        orElse: () => PropertyType.house,
      );
    } catch (_) {
      return PropertyType.house;
    }
  }

  // Helper method to parse property status string to enum
  static PropertyStatus _parsePropertyStatus(String statusStr) {
    try {
      return PropertyStatus.values.firstWhere(
        (e) =>
            e.toString() == 'PropertyStatus.$statusStr' ||
            e.toString().split('.').last.toLowerCase() ==
                statusStr.toLowerCase(),
        orElse: () => PropertyStatus.available,
      );
    } catch (_) {
      return PropertyStatus.available;
    }
  }

  // Convert a PropertyModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    final map = {
      'title': title,
      'price': price,
      'location': location,
      'description': description,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'images': images,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'propertyType': propertyType,
      'listingType': listingType,
      'ownerId': ownerId,
      'owner': owner?.toMap(),
      'featured': featured,
      'amenities': amenities, // Add amenities to map
      'isApproved': isApproved, // Add isApproved to map
    };

    // Only add admin fields if they are set
    if (lastReviewedAt != null) {
      map['lastReviewedAt'] = Timestamp.fromDate(lastReviewedAt!);
    }
    if (reviewedBy != null) {
      map['reviewedBy'] = reviewedBy;
    }
    if (adminNotes != null) {
      map['adminNotes'] = adminNotes;
    }
    if (moderationData != null) {
      map['moderationData'] = moderationData;
    }

    return map;
  }

  // Create a copy of the PropertyModel with modified fields
  PropertyModel copyWith({
    String? id,
    String? title,
    double? price,
    String? location,
    String? description,
    int? bedrooms,
    int? bathrooms,
    double? area,
    List<String>? images,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
    PropertyType? type,
    PropertyStatus? status,
    String? propertyType,
    String? listingType,
    PropertyOwner? owner,
    String? ownerId,
    bool? featured,
    List<String>? amenities,
    bool? isApproved,
    DateTime? lastReviewedAt,
    String? reviewedBy,
    String? adminNotes,
    Map<String, dynamic>? moderationData,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      location: location ?? this.location,
      description: description ?? this.description,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      area: area ?? this.area,
      images: images ?? this.images,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      type: type ?? this.type,
      status: status ?? this.status,
      propertyType: propertyType ?? this.propertyType,
      listingType: listingType ?? this.listingType,
      owner: owner ?? this.owner,
      ownerId: ownerId ?? this.ownerId,
      featured: featured ?? this.featured,
      amenities: amenities ?? this.amenities,
      isApproved: isApproved ?? this.isApproved,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      adminNotes: adminNotes ?? this.adminNotes,
      moderationData: moderationData ?? this.moderationData,
    );
  }

  // Helper method to check if property was reviewed recently
  bool wasReviewedRecently() {
    if (lastReviewedAt == null) return false;
    final difference = DateTime.now().difference(lastReviewedAt!);
    return difference.inDays <
        7; // Considered recent if reviewed in last 7 days
  }

  // Helper method to check if property needs admin attention
  bool needsAdminAttention() {
    return !isApproved || lastReviewedAt == null;
  }
}
