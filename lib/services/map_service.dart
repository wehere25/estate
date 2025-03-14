
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../core/utils/dev_utils.dart';

class MapService {
  // Convert Firestore GeoPoint to LatLng for Flutter Map
  static LatLng geoPointToLatLng(GeoPoint geoPoint) {
    return LatLng(geoPoint.latitude, geoPoint.longitude);
  }
  
  // Convert LatLng to Firestore GeoPoint
  static GeoPoint latLngToGeoPoint(LatLng latLng) {
    return GeoPoint(latLng.latitude, latLng.longitude);
  }
  
  // Get current user location
  static Future<LatLng?> getCurrentLocation() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission permanently denied');
        return null;
      }
      
      // Use mock location in dev mode
      if (DevUtils.isDev && DevUtils.bypassAuth) {
        DevUtils.log('Using mock location in dev mode');
        return const LatLng(34.0837, 74.7973); // Kashmir coordinates
      }
      
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }
  
  // Create a marker for a property
  static Marker createPropertyMarker({
    required String id,
    required LatLng position,
    required String title,
    required double price,
    VoidCallback? onTap,
  }) {
    return Marker(
      width: 80.0,
      height: 80.0,
      point: position,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                '₹${(price / 100000).round()} L',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 2),
            const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 30,
              shadows: [
                Shadow(
                  color: Colors.black45,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Calculate distance between two points
  static double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }
  
  // Get properties near a location (within radius in km)
  static Future<List<Map<String, dynamic>>> getNearbyProperties(
    FirebaseFirestore firestore,
    LatLng center,
    double radiusKm, {
    int limit = 20,
  }) async {
    try {
      // Convert radius from km to meters
      final radiusMeters = radiusKm * 1000;
      
      // Get all active properties
      // Note: This is a simple implementation. For production, you should use
      // Firestore geoqueries or a cloud function with GeoFireX
      final snapshot = await firestore
          .collection('properties')
          .where('status', isEqualTo: 'active')
          .get();
      
      // Filter properties by distance
      final nearbyProperties = snapshot.docs
          .map((doc) {
            final data = doc.data();
            final geoPoint = data['location'] as GeoPoint?;
            
            if (geoPoint == null) return null;
            
            final propertyLatLng = LatLng(geoPoint.latitude, geoPoint.longitude);
            final distance = calculateDistance(center, propertyLatLng);
            
            // Include property if within radius
            if (distance <= radiusMeters) {
              return {
                'id': doc.id,
                ...data,
                'distanceMeters': distance,
              };
            }
            return null;
          })
          .where((item) => item != null)
          .cast<Map<String, dynamic>>()
          .toList();
      
      // Sort by distance
      nearbyProperties.sort((a, b) => 
          (a['distanceMeters'] as double).compareTo(b['distanceMeters'] as double)
      );
      
      // Limit the number of results
      if (nearbyProperties.length > limit) {
        return nearbyProperties.sublist(0, limit);
      }
      
      return nearbyProperties;
    } catch (e) {
      debugPrint('Error getting nearby properties: $e');
      return [];
    }
  }
  
  // Get formatted address from coordinates using reverse geocoding
  static Future<String?> getAddressFromCoordinates(LatLng coordinates) async {
    try {
      // Use mock address in dev mode
      if (DevUtils.isDev && DevUtils.bypassAuth) {
        DevUtils.log('Using mock address in dev mode');
        return '123 Test Street, Srinagar, Kashmir';
      }
      
      // For production, use a geocoding service like Google Maps Geocoding API
      // This requires setting up a separate service or using a package like geocoding
      
      // For now, return a placeholder value
      return 'Address lookup not implemented';
    } catch (e) {
      debugPrint('Error getting address: $e');
      return null;
    }
  }
}
