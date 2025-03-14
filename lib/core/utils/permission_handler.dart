import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class AppPermissionHandler {
  static Future<bool> requestStoragePermission(BuildContext context) async {
    // Different handling for Android 13+ (API level 33+)
    if (await Permission.photos.request().isGranted ||
        await Permission.storage.request().isGranted) {
      return true;
    }

    return _showPermissionDialog(
      context,
      'Storage Permission Required',
      'We need storage permission to upload and save property images.',
      Permission.storage,
    );
  }

  static Future<bool> requestLocationPermission(BuildContext context) async {
    if (await Permission.location.request().isGranted) {
      return true;
    }
    
    return _showPermissionDialog(
      context, 
      'Location Permission Required',
      'We need location permission to show properties near you and provide accurate location services.',
      Permission.location,
    );
  }

  static Future<bool> requestCameraPermission(BuildContext context) async {
    if (await Permission.camera.request().isGranted) {
      return true;
    }
    
    return _showPermissionDialog(
      context, 
      'Camera Permission Required',
      'We need camera permission to let you take photos of properties.',
      Permission.camera,
    );
  }

  static Future<bool> _showPermissionDialog(
    BuildContext context,
    String title,
    String message,
    Permission permission,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  // Check multiple permissions at once
  static Future<Map<Permission, PermissionStatus>> checkMultiplePermissions(
    List<Permission> permissions,
  ) async {
    return await permissions.request();
  }
}
