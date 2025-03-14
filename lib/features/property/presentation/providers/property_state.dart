import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/property_dto.dart';

enum SortBy {
  createdAt,
  price,
  views
}

class PropertyState {
  final List<PropertyDto> properties;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final DocumentSnapshot? lastDocument;
  final Map<String, dynamic>? filters;
  final PropertyDto? selectedProperty;
  final SortBy sortBy;
  final RangeValues priceRange;
  final RangeValues areaRange;

  const PropertyState({
    this.properties = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.lastDocument,
    this.filters,
    this.selectedProperty,
    this.sortBy = SortBy.createdAt,
    required this.priceRange,
    required this.areaRange,
  });

  factory PropertyState.initial() => const PropertyState(
    priceRange: RangeValues(0, 1000000),
    areaRange: RangeValues(0, 10),
  );

  PropertyState copyWith({
    List<PropertyDto>? properties,
    bool? isLoading,
    bool? hasMore,
    String? error,
    DocumentSnapshot? lastDocument,
    Map<String, dynamic>? filters,
    PropertyDto? selectedProperty,
    SortBy? sortBy,
    RangeValues? priceRange,
    RangeValues? areaRange,
  }) {
    return PropertyState(
      properties: properties ?? this.properties,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      lastDocument: lastDocument ?? this.lastDocument,
      filters: filters ?? this.filters,
      selectedProperty: selectedProperty ?? this.selectedProperty,
      sortBy: sortBy ?? this.sortBy,
      priceRange: priceRange ?? this.priceRange,
      areaRange: areaRange ?? this.areaRange,
    );
  }
}

enum PropertySort {
  newest,
  priceHighToLow,
  priceLowToHigh,
  mostPopular
}

class PropertyFilters {
  final String? type;
  final RangeValues? priceRange;
  final int? bedrooms;
  final String? location;
  final bool onlyFeatured;

  const PropertyFilters({
    this.type,
    this.priceRange,
    this.bedrooms,
    this.location,
    this.onlyFeatured = false,
  });

  Map<String, dynamic> toJson() {
    return {
      if (type != null) 'type': type,
      if (priceRange != null) ...{
        'minPrice': priceRange!.start,
        'maxPrice': priceRange!.end,
      },
      if (bedrooms != null) 'bedrooms': bedrooms,
      if (location != null) 'location': location,
      if (onlyFeatured) 'featured': true,
    };
  }

  PropertyFilters copyWith({
    String? type,
    RangeValues? priceRange,
    int? bedrooms,
    String? location,
    bool? onlyFeatured,
  }) {
    return PropertyFilters(
      type: type ?? this.type,
      priceRange: priceRange ?? this.priceRange,
      bedrooms: bedrooms ?? this.bedrooms,
      location: location ?? this.location,
      onlyFeatured: onlyFeatured ?? this.onlyFeatured,
    );
  }
}
