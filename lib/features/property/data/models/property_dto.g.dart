// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PropertyDto _$PropertyDtoFromJson(Map<String, dynamic> json) => PropertyDto(
      id: json['id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      location: json['location'] as String,
      coordinates: const GeoPointConverter()
          .fromJson(json['coordinates'] as Map<String, dynamic>),
      address: json['address'] as String,
      images:
          (json['images'] as List<dynamic>).map((e) => e as String).toList(),
      type: json['type'] as String,
      ownerId: json['ownerId'] as String,
      bedrooms: (json['bedrooms'] as num?)?.toInt() ?? 0,
      bathrooms: (json['bathrooms'] as num?)?.toInt() ?? 0,
      area: (json['area'] as num?)?.toDouble() ?? 0,
      isFeatured: json['isFeatured'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      views: (json['views'] as num?)?.toInt(),
      reference: const DocumentReferenceConverter()
          .fromJson(json['reference'] as String?),
    );

Map<String, dynamic> _$PropertyDtoToJson(PropertyDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'price': instance.price,
      'location': instance.location,
      'coordinates': const GeoPointConverter().toJson(instance.coordinates),
      'address': instance.address,
      'images': instance.images,
      'type': instance.type,
      'ownerId': instance.ownerId,
      'bedrooms': instance.bedrooms,
      'bathrooms': instance.bathrooms,
      'area': instance.area,
      'isFeatured': instance.isFeatured,
      'createdAt': instance.createdAt?.toIso8601String(),
      'views': instance.views,
      'reference':
          const DocumentReferenceConverter().toJson(instance.reference),
    };
