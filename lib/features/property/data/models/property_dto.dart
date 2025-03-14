import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'property_dto.g.dart';

class GeoPointConverter implements JsonConverter<GeoPoint, Map<String, dynamic>> {
  const GeoPointConverter();

  @override
  GeoPoint fromJson(Map<String, dynamic> json) {
    return GeoPoint(json['latitude'] as double, json['longitude'] as double);
  }

  @override
  Map<String, dynamic> toJson(GeoPoint point) {
    return {'latitude': point.latitude, 'longitude': point.longitude};
  }
}

class DocumentReferenceConverter implements JsonConverter<DocumentReference?, String?> {
  const DocumentReferenceConverter();

  @override
  DocumentReference? fromJson(String? json) {
    return json != null ? FirebaseFirestore.instance.doc(json) : null;
  }

  @override
  String? toJson(DocumentReference? reference) => reference?.path;
}

@JsonSerializable(explicitToJson: true)
class PropertyDto {
  final String? id;
  final String title;
  final String description;
  final double price;
  final String location;
  @GeoPointConverter()
  final GeoPoint coordinates;
  final String address;
  final List<String> images;
  final String type;
  final String ownerId;
  final int bedrooms;
  final int bathrooms;
  final double area;
  final bool isFeatured;
  final DateTime? createdAt;
  final int? views;
  @DocumentReferenceConverter()
  final DocumentReference? reference;

  PropertyDto({
    this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.location,
    required this.coordinates,
    required this.address,
    required this.images,
    required this.type,
    required this.ownerId,
    this.bedrooms = 0,
    this.bathrooms = 0,
    this.area = 0,
    this.isFeatured = false,
    this.createdAt,
    this.views,
    this.reference,
  });

  factory PropertyDto.fromJson(Map<String, dynamic> json) =>
      _$PropertyDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyDtoToJson(this);

  factory PropertyDto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Document data was null');
    
    return PropertyDto.fromJson({
      'id': doc.id,
      'reference': doc.reference,
      ...data,
    });
  }

  PropertyDto copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? location,
    GeoPoint? coordinates,
    String? address,
    List<String>? images,
    String? type,
    String? ownerId,
    int? bedrooms,
    int? bathrooms,
    double? area,
    bool? isFeatured,
    DateTime? createdAt,
    int? views,
    DocumentReference? reference,
  }) {
    return PropertyDto(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      location: location ?? this.location,
      coordinates: coordinates ?? this.coordinates,
      address: address ?? this.address,
      images: images ?? this.images,
      type: type ?? this.type,
      ownerId: ownerId ?? this.ownerId,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      area: area ?? this.area,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      views: views ?? this.views,
      reference: reference ?? this.reference,
    );
  }
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  @override
  String toString() => 'ValidationException: $message';
}
