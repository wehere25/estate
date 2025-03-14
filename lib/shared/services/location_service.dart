import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import '/core/utils/permission_handler.dart';
import '../../core/utils/exceptions/app_exception.dart';

class LocationService {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Location settings
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100, // Update every 100 meters
  );

  Future<bool> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        'Location services are disabled. Please enable location services.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException(
          'Location permissions are denied. Please grant location permissions.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Location permissions are permanently denied. Please enable in settings.',
      );
    }

    return true;
  }

  Future<GeoPoint?> getCurrentLocation() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return null;
    }

    // Check for location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }
    
    // Handle permanently denied permission
    if (permission == LocationPermission.deniedForever) {
      // Show dialog to open app settings
      return null;
    }

    try {
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      return GeoPoint(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return _formatAddress(place);
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
    }
    return null;
  }

  Future<List<Location>> getCoordinatesFromAddress(String address) async {
    try {
      return await locationFromAddress(address);
    } catch (e) {
      throw LocationException('Failed to get coordinates: $e');
    }
  }

  Future<Position?> getLastKnownLocation() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      return null;
    }
  }

  Stream<Position> getLocationUpdates({
    int distanceFilter = 100,
    bool highAccuracy = false,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: highAccuracy 
            ? LocationAccuracy.best 
            : LocationAccuracy.medium,
        distanceFilter: distanceFilter,
      ),
    ).handleError((error) {
      throw LocationException('Error getting location updates: $error');
    });
  }

  Future<double> getDistanceBetween({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) async {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  String _formatAddress(Placemark place) {
    List<String> addressParts = [
      place.street ?? '',
      place.subLocality ?? '',
      place.locality ?? '',
      place.postalCode ?? '',
      place.administrativeArea ?? '',
      place.country ?? ''
    ];
    
    // Filter out empty parts
    addressParts = addressParts.where((part) => part.isNotEmpty).toList();
    
    return addressParts.join(', ');
  }

  // Get nearby properties
  Future<List<QueryDocumentSnapshot>> getNearbyProperties({
    required double latitude,
    required double longitude,
    double radiusInKm = 10.0,
  }) async {
    try {
      // Convert km to degrees (rough approximation)
      const double oneKmInDegrees = 1 / 111.32;
      final double radiusInDegrees = radiusInKm * oneKmInDegrees;
      
      final geoBounds = _calculateGeoBounds(
        latitude, 
        longitude,
        radiusInDegrees
      );
      
      // Query Firestore for properties within the bounds
      final snapshot = await FirebaseFirestore.instance
          .collection('properties')
          .where('coordinates.latitude', isGreaterThan: geoBounds['minLat'])
          .where('coordinates.latitude', isLessThan: geoBounds['maxLat'])
          .get();
      
      // Further filter by longitude (Firestore can only query on one field inequality)
      return snapshot.docs.where((doc) {
        final GeoPoint coords = doc.data()['coordinates'] as GeoPoint;
        return coords.longitude >= geoBounds['minLng']! && 
               coords.longitude <= geoBounds['maxLng']!;
      }).toList();
    } catch (e) {
      debugPrint('Error getting nearby properties: $e');
      return [];
    }
  }
  
  Map<String, double> _calculateGeoBounds(
    double latitude, 
    double longitude, 
    double radiusInDegrees
  ) {
    return {
      'minLat': latitude - radiusInDegrees,
      'maxLat': latitude + radiusInDegrees,
      'minLng': longitude - radiusInDegrees,
      'maxLng': longitude + radiusInDegrees,
    };
  }
}

class LocationException implements Exception {
  final String message;
  LocationException(this.message);
  
  @override
  String toString() => 'LocationException: $message';
}

extension LocationExtensions on Position {
  Future<String> getAddress() async {
    final address = await LocationService().getAddressFromCoordinates(
      latitude,
      longitude, 
    );
    return address ?? 'Unknown location';
  }

  double getDistanceTo(Position other) {
    return Geolocator.distanceBetween(
      latitude,
      longitude,
      other.latitude,
      other.longitude,
    );
  }
}
