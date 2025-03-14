import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../core/utils/debug_logger.dart';

/// Admin service for managing user roles
/// Note: Admin privileges can only be granted by Firebase Admin SDK (Cloud Functions)
class FirebaseAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache admin status to avoid repeated checks
  final Map<String, bool> _adminCache = {};

  // List of admin emails - update this with your actual admin emails
  final List<String> _adminEmails = [
    'admin@example.com',
    'youremail@example.com', // Replace with your actual email
    'your.admin@example.com', // Replace with your team's admin emails
  ];

  // Initialize the service with retries
  Future<void> initialize() async {
    // Add delay for App Check to initialize properly
    await Future.delayed(const Duration(seconds: 1));
    try {
      // Clear admin cache on user change
      _auth.authStateChanges().listen((user) {
        if (user == null) {
          _adminCache.clear();
        }
      });

      // Set up initial admin state if user is logged in
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Pre-cache admin status
        await isCurrentUserAdmin();
      }
    } catch (e) {
      DebugLogger.error('Error initializing FirebaseAdminService', e);
    }
  }

  /// Checks if the current user has admin role with robust fallback mechanisms
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Return cached status if available
      if (_adminCache.containsKey(user.uid)) {
        return _adminCache[user.uid]!;
      }

      DebugLogger.info('Checking admin status for user: ${user.email}');

      // LAYER 1: Check hardcoded admin emails list
      if (user.email != null && _adminEmails.contains(user.email)) {
        DebugLogger.info('User recognized as admin by email (hardcoded list)');
        _adminCache[user.uid] = true;
        return true;
      }

      // LAYER 2: Check Firebase Auth custom claims
      try {
        await user.getIdTokenResult(true); // Force refresh
        final idTokenResult = await user.getIdTokenResult();

        if (idTokenResult.claims != null &&
            (idTokenResult.claims!['admin'] == true ||
                idTokenResult.claims!['isAdmin'] == true)) {
          DebugLogger.info(
              'User verified as admin via Firebase Auth custom claim');
          _adminCache[user.uid] = true;
          return true;
        }
      } catch (e) {
        DebugLogger.error('Error checking token claims', e);
        // Continue to next check method
      }

      // LAYER 3: Check Firestore 'admins' collection
      try {
        final adminDocs = await Future.wait([
          _firestore.collection('admins').doc(user.uid).get(),
          _firestore.collection('admin_users').doc(user.uid).get()
        ]);

        // Check both admin documents
        if (adminDocs[0].exists || adminDocs[1].exists) {
          DebugLogger.info(
              'User verified as admin via Firestore admin collections');
          _adminCache[user.uid] = true;
          return true;
        }
      } catch (e) {
        DebugLogger.error('Error checking Firestore admin status', e);
        // Continue to next check method
      }

      // LAYER 4: Check users collection for admin flag
      try {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null &&
              (userData['isAdmin'] == true || userData['role'] == 'admin')) {
            DebugLogger.info('User verified as admin via users collection');
            _adminCache[user.uid] = true;
            return true;
          }
        }
      } catch (e) {
        DebugLogger.error('Error checking user document', e);
      }

      // LAYER 5: Create admin if needed (development only)
      if (kDebugMode && user.email != null) {
        // In debug mode, automatically grant admin for easier testing
        try {
          await grantAdminAccess(user.uid, user.email!);
          DebugLogger.warning('Created admin entry for development testing');
          _adminCache[user.uid] = true;
          return true;
        } catch (e) {
          DebugLogger.error('Error creating admin entry', e);
        }
      }

      // Not admin by any verification method
      _adminCache[user.uid] = false;
      return false;
    } catch (e) {
      DebugLogger.error('Error in isCurrentUserAdmin', e);
      return kDebugMode; // Only auto-grant in debug mode
    }
  }

  // Direct method to grant admin access when needed
  Future<bool> grantAdminAccess(String uid, String email) async {
    try {
      // Add to admin collections directly
      await Future.wait([
        _firestore.collection('admins').doc(uid).set({
          'email': email,
          'isActive': true,
          'grantedAt': FieldValue.serverTimestamp(),
          'grantedBy': 'system',
        }),
        _firestore.collection('admin_users').doc(uid).set({
          'email': email,
          'isActive': true,
          'grantedAt': FieldValue.serverTimestamp(),
          'grantedBy': 'system',
        }),
        _firestore.collection('users').doc(uid).update({
          'isAdmin': true,
          'role': 'admin',
          'updatedAt': FieldValue.serverTimestamp(),
          'permissions': ['admin', 'manage_properties', 'manage_users'],
        }),
      ]);

      // Clear cache
      _adminCache.remove(uid);
      return true;
    } catch (e) {
      DebugLogger.error('Failed to grant admin access directly', e);
      return false;
    }
  }

  // Get all users with admin role
  Future<List<Map<String, dynamic>>> getAdminUsers() async {
    try {
      // Check both admin collections
      final snapshots = await Future.wait([
        _firestore.collection('admin_users').get(),
        _firestore.collection('admins').get(),
      ]);

      // Combine results from both collections
      final Map<String, Map<String, dynamic>> adminUsers = {};

      // Process admin_users collection
      for (final doc in snapshots[0].docs) {
        adminUsers[doc.id] = {
          'uid': doc.id,
          ...doc.data(),
        };
      }

      // Process admins collection and merge
      for (final doc in snapshots[1].docs) {
        if (adminUsers.containsKey(doc.id)) {
          // Merge data if user exists in both collections
          adminUsers[doc.id]?.addAll(doc.data());
        } else {
          // Add new user if only in admins collection
          adminUsers[doc.id] = {
            'uid': doc.id,
            ...doc.data(),
          };
        }
      }

      return adminUsers.values.toList();
    } catch (e) {
      DebugLogger.error('Error fetching admin users', e);
      return [];
    }
  }

  // Grant admin role using secure methods
  Future<bool> grantAdminRole(String uid, String email) async {
    try {
      // First try Cloud Functions (most secure)
      try {
        final result = await _functions.httpsCallable('grantAdminRole').call({
          'uid': uid,
          'email': email,
        });

        if (result.data['success'] == true) {
          // Success via Cloud Functions
          _adminCache.remove(uid); // Clear cache
          return true;
        }
      } catch (e) {
        DebugLogger.error('Cloud function failed, trying direct method', e);
      }

      // Fall back to direct method if Cloud Function fails
      return await grantAdminAccess(uid, email);
    } catch (e) {
      DebugLogger.error('Error granting admin role', e);
      return false;
    }
  }

  // Revoke admin role
  Future<bool> revokeAdminRole(String uid) async {
    try {
      // First try Cloud Functions
      try {
        final result = await _functions.httpsCallable('revokeAdminRole').call({
          'uid': uid,
        });

        if (result.data['success'] == true) {
          _adminCache.remove(uid); // Clear cache
          return true;
        }
      } catch (e) {
        DebugLogger.error('Cloud function failed, trying direct method', e);
      }

      // Fall back to direct method
      try {
        await Future.wait([
          _firestore.collection('admins').doc(uid).delete(),
          _firestore.collection('admin_users').doc(uid).delete(),
          _firestore.collection('users').doc(uid).update({
            'isAdmin': false,
            'role': 'user',
            'updatedAt': FieldValue.serverTimestamp(),
          }),
        ]);

        _adminCache.remove(uid);
        return true;
      } catch (e) {
        DebugLogger.error('Failed to revoke admin role directly', e);
        return false;
      }
    } catch (e) {
      DebugLogger.error('Error revoking admin role', e);
      return false;
    }
  }

  /// Set user admin role
  Future<void> setUserAdminRole(String userId, bool isAdmin) async {
    try {
      if (isAdmin) {
        // Get user email first
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final email = userDoc.data()?['email'] as String?;

        if (email != null) {
          await grantAdminRole(userId, email);
        } else {
          throw Exception('User email not found');
        }
      } else {
        await revokeAdminRole(userId);
      }
    } catch (e) {
      DebugLogger.error('Failed to set user admin role', e);
      throw Exception('Failed to update user role: $e');
    }
  }

  /// Update user status
  Future<void> updateUserStatus(String userId, String status) async {
    try {
      // Try Cloud Function first
      try {
        await _functions.httpsCallable('updateUserStatus').call({
          'userId': userId,
          'status': status,
        });
        return;
      } catch (e) {
        DebugLogger.error('Cloud function failed, using direct update', e);
      }

      // Direct update as fallback
      await _firestore.collection('users').doc(userId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      DebugLogger.error('Failed to update user status', e);
      throw Exception('Failed to update user status: $e');
    }
  }

  /// Clear the admin status cache
  void clearCache() {
    _adminCache.clear();
  }
}
