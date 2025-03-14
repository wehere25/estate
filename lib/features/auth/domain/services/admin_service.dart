import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminService {
  // Private constructor to prevent instantiation
  AdminService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _adminPrefKey = 'is_admin_user';
  static bool? _cachedAdminStatus;

  /// Check if a user has admin privileges (synchronous method with persistence)
  static bool isUserAdmin(User? user) {
    if (user == null || user.email == null) return false;

    // First check our in-memory cache
    if (_cachedAdminStatus != null) {
      return _cachedAdminStatus!;
    }

    // Then check if user email is in our debug admin list (for development)
    if (kDebugMode && _debugAdminEmails.contains(user.email!.toLowerCase())) {
      // Schedule async save operation but return immediately
      _saveAdminStatus(true);
      return true;
    }

    // Trigger async check to update cache in background
    _checkAndUpdateAdminStatus(user);

    // For immediate response, return false by default
    // The async check will update the cache for future calls
    return false;
  }

  /// Checks admin status in Firestore and updates local cache (async method)
  static Future<bool> checkFirestoreAdmin(String uid) async {
    try {
      // Check admin collection first
      final adminDoc = await _firestore.collection('admins').doc(uid).get();
      if (adminDoc.exists) {
        _saveAdminStatus(true);
        return true;
      }

      // Check user document role
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final isAdmin =
          userDoc.data()?['role']?.toString().toLowerCase() == 'admin';

      // Save the result for future reference
      _saveAdminStatus(isAdmin);
      return isAdmin;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  // Private method to update cache
  static Future<void> _saveAdminStatus(bool isAdmin) async {
    _cachedAdminStatus = isAdmin;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_adminPrefKey, isAdmin);
    } catch (e) {
      debugPrint('Error saving admin status: $e');
    }
  }

  // Check and update admin status in background
  static void _checkAndUpdateAdminStatus(User user) {
    checkFirestoreAdmin(user.uid).then((bool result) {
      // This updates both memory cache and shared preferences
      _saveAdminStatus(result);
    });
  }

  // Clear admin status on logout
  static Future<void> clearAdminStatus() async {
    _cachedAdminStatus = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_adminPrefKey);
    } catch (e) {
      debugPrint('Error clearing admin status: $e');
    }
  }

  // List of debug mode admin emails
  static const List<String> _debugAdminEmails = [
    'trashbin2605@gmail.com',
    // Add other admin emails as needed
  ];
}
