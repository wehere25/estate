import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../features/auth/domain/models/user_model.dart';
import '../../../features/auth/domain/models/user_role.dart';
import '../../../core/utils/debug_logger.dart';

/// Utility class for admin-related operations and permission management
class AdminUtils {
  // Private constructor to prevent instantiation
  AdminUtils._();

  /// Constants
  static const String _adminCollection = 'admins';
  static const String _usersCollection = 'users';
  static const String _settingsCollection = 'settings';

  /// Check if the current user has admin privileges
  static Future<bool> isCurrentUserAdmin() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      // First check claims from Firebase Auth
      final idTokenResult = await currentUser.getIdTokenResult();
      if (idTokenResult.claims?['admin'] == true) {
        return true;
      }

      // Then check user document in Firestore
      final userDocRef = FirebaseFirestore.instance
          .collection(_usersCollection)
          .doc(currentUser.uid);

      final userDoc = await userDocRef.get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          // Check for admin role in user document
          final roleStr = userData['role']?.toString().toLowerCase();
          if (roleStr == 'admin') return true;
        }
      }

      // Finally check dedicated admin collection
      final adminDocRef = FirebaseFirestore.instance
          .collection(_adminCollection)
          .doc(currentUser.uid);

      final adminDoc = await adminDocRef.get();
      return adminDoc.exists;
    } catch (e) {
      DebugLogger.error('Error checking admin status', e);
      return false;
    }
  }

  /// Get admin dashboard data
  static Future<Map<String, dynamic>> getAdminDashboardData() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not signed in');
      }

      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin && !kDebugMode) {
        throw Exception('Not authorized to access admin dashboard');
      }

      // Get counts for dashboard
      final usersCount = await FirebaseFirestore.instance
          .collection(_usersCollection)
          .count()
          .get()
          .then((value) => value.count);

      final propertiesCount = await FirebaseFirestore.instance
          .collection('properties')
          .count()
          .get()
          .then((value) => value.count);

      final pendingApprovalCount = await FirebaseFirestore.instance
          .collection('properties')
          .where('isApproved', isEqualTo: false)
          .count()
          .get()
          .then((value) => value.count);

      // Get admin settings
      final settingsDoc = await FirebaseFirestore.instance
          .collection(_settingsCollection)
          .doc('adminSettings')
          .get();

      final adminSettings = settingsDoc.exists ? settingsDoc.data() : {};

      return {
        'usersCount': usersCount,
        'propertiesCount': propertiesCount,
        'pendingApprovalCount': pendingApprovalCount,
        'settings': adminSettings ?? {},
        'isAdmin': isAdmin,
        'lastUpdated': DateTime.now(),
      };
    } catch (e) {
      DebugLogger.error('Error fetching admin dashboard data', e);
      rethrow;
    }
  }

  /// Run extensive diagnostics for admin access issues
  /// If [attemptFix] is true, will try to fix common issues automatically
  static Future<Map<String, dynamic>> enhancedAdminDebugger({
    bool attemptFix = false,
  }) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not signed in');
      }

      // Results accumulator
      final Map<String, dynamic> results = {
        'uid': currentUser.uid,
        'email': currentUser.email,
        'displayName': currentUser.displayName,
        'isDebugMode': kDebugMode,
        'isAdmin': false,
        'recommendations': <String>[],
        'appliedFixes': <String>[],
      };

      // Check Auth claims
      final idTokenResult =
          await currentUser.getIdTokenResult(true); // Force refresh
      results['hasAdminClaim'] = idTokenResult.claims?['admin'] == true;

      // Check user document
      final userDocRef = FirebaseFirestore.instance
          .collection(_usersCollection)
          .doc(currentUser.uid);

      DocumentSnapshot userDoc;
      try {
        userDoc = await userDocRef.get();
        results['userDocExists'] = userDoc.exists;

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>?;
          final roleStr = userData?['role']?.toString().toLowerCase();
          results['isAdminInUserDoc'] = roleStr == 'admin';
          results['userDocData'] = userData;
        }
      } catch (e) {
        results['userDocError'] = e.toString();
        results['recommendations']
            .add('User document read failed. Check Firestore rules.');
      }

      // Check admin collection document
      final adminDocRef = FirebaseFirestore.instance
          .collection(_adminCollection)
          .doc(currentUser.uid);

      try {
        final adminDoc = await adminDocRef.get();
        results['adminDocExists'] = adminDoc.exists;

        if (adminDoc.exists) {
          results['adminDocData'] = adminDoc.data();
        }
      } catch (e) {
        results['adminDocError'] = e.toString();
        results['recommendations']
            .add('Admin document read failed. Check Firestore rules.');
      }

      // Try to read the admin collection to verify permissions
      try {
        await FirebaseFirestore.instance
            .collection(_adminCollection)
            .limit(1)
            .get();
        results['canReadAdminCollection'] = true;
      } catch (e) {
        results['canReadAdminCollection'] = false;
        results['adminCollectionError'] = e.toString();
        results['recommendations'].add(
            'Cannot read admin collection. Firestore rules may be too restrictive.');
      }

      // Summary determination of admin status
      results['isAdmin'] = results['hasAdminClaim'] == true ||
          results['isAdminInUserDoc'] == true ||
          results['adminDocExists'] == true;

      // Add recommendations based on diagnostics
      if (!results['isAdmin']) {
        results['recommendations'].add('User does not have admin privileges.');

        if (!kDebugMode) {
          results['recommendations']
              .add('Ask an existing admin to grant you admin access.');
        } else {
          results['recommendations']
              .add('In debug mode, you can use "Force Add As Admin" feature.');
        }
      }

      if (results['adminDocExists'] != true) {
        results['recommendations']
            .add('No admin document exists for this user.');
      }

      if (results['isAdminInUserDoc'] != true &&
          results['userDocExists'] == true) {
        results['recommendations']
            .add('User document exists but role is not set to admin.');
      }

      // Attempt fixes if requested
      if (attemptFix && kDebugMode) {
        // Only attempt fixes in debug mode
        DebugLogger.warning(
            'Attempting to fix admin access issues in debug mode');

        // Fix 1: Create admin document if missing
        if (results['adminDocExists'] != true) {
          try {
            await adminDocRef.set({
              'uid': currentUser.uid,
              'email': currentUser.email,
              'grantedAt': FieldValue.serverTimestamp(),
              'grantedByDebugMode': true,
            });
            results['appliedFixes'].add('Created admin document in Firestore');
            results['adminDocExists'] = true;
          } catch (e) {
            DebugLogger.error('Failed to create admin document', e);
            results['recommendations']
                .add('Failed to create admin document: ${e.toString()}');
          }
        }

        // Fix 2: Update user document if role is not admin
        if (results['userDocExists'] == true &&
            results['isAdminInUserDoc'] != true) {
          try {
            await userDocRef.update({'role': 'admin'});
            results['appliedFixes'].add('Updated user document role to admin');
            results['isAdminInUserDoc'] = true;
          } catch (e) {
            DebugLogger.error('Failed to update user document', e);
            results['recommendations']
                .add('Failed to update user role: ${e.toString()}');
          }
        }

        // After fixes, re-evaluate admin status
        results['isAdmin'] = results['hasAdminClaim'] == true ||
            results['isAdminInUserDoc'] == true ||
            results['adminDocExists'] == true;
      }

      return results;
    } catch (e) {
      DebugLogger.error('Error in admin debugger', e);
      return {
        'error': e.toString(),
        'recommendations': [
          'An unexpected error occurred during diagnostics.',
          'Check app permissions and Firebase configuration.',
        ],
      };
    }
  }

  /// Force add the current user as an admin (ONLY FOR DEBUG MODE)
  static Future<bool> forceAddCurrentUserAsAdmin() async {
    // Safety check - only allow in debug mode
    if (!kDebugMode) {
      DebugLogger.error('Attempted to force add admin outside debug mode');
      return false;
    }

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not signed in');
      }

      // Update or create the admin document
      await FirebaseFirestore.instance
          .collection(_adminCollection)
          .doc(currentUser.uid)
          .set({
        'uid': currentUser.uid,
        'email': currentUser.email,
        'displayName': currentUser.displayName,
        'grantedAt': FieldValue.serverTimestamp(),
        'grantedBy': 'debug_mode',
        'isDebugModeGrant': true,
      }, SetOptions(merge: true));

      // Update the user document
      await FirebaseFirestore.instance
          .collection(_usersCollection)
          .doc(currentUser.uid)
          .update({
        'role': 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': 'debug_mode',
      });

      DebugLogger.warning(
          'User ${currentUser.email} forcibly added as admin in debug mode');

      return true;
    } catch (e) {
      DebugLogger.error('Error force adding admin user', e);
      return false;
    }
  }

  /// Revoke admin permissions for a user
  static Future<bool> revokeAdminPermission(String userId) async {
    try {
      // Security check - only admins can revoke admin permissions
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin && !kDebugMode) {
        throw Exception('Not authorized to revoke admin permissions');
      }

      // Remove from admin collection
      await FirebaseFirestore.instance
          .collection(_adminCollection)
          .doc(userId)
          .delete();

      // Update user document if it exists
      try {
        await FirebaseFirestore.instance
            .collection(_usersCollection)
            .doc(userId)
            .update({
          'role': 'user',
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? 'system',
        });
      } catch (e) {
        // Non-critical error if user document doesn't exist or can't be updated
        DebugLogger.warning(
            'Could not update user document when revoking admin: $e');
      }

      return true;
    } catch (e) {
      DebugLogger.error('Error revoking admin permissions', e);
      return false;
    }
  }

  /// Grant admin permissions to a user
  static Future<bool> grantAdminPermission(String userId,
      {String? email}) async {
    try {
      // Security check - only admins can grant admin permissions
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin && !kDebugMode) {
        throw Exception('Not authorized to grant admin permissions');
      }

      // Add to admin collection
      await FirebaseFirestore.instance
          .collection(_adminCollection)
          .doc(userId)
          .set({
        'uid': userId,
        'email': email,
        'grantedAt': FieldValue.serverTimestamp(),
        'grantedBy': FirebaseAuth.instance.currentUser?.uid ?? 'system',
      }, SetOptions(merge: true));

      // Update user document if it exists
      try {
        await FirebaseFirestore.instance
            .collection(_usersCollection)
            .doc(userId)
            .update({
          'role': 'admin',
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? 'system',
        });
      } catch (e) {
        // Non-critical error if user document doesn't exist or can't be updated
        DebugLogger.warning(
            'Could not update user document when granting admin: $e');
      }

      return true;
    } catch (e) {
      DebugLogger.error('Error granting admin permissions', e);
      return false;
    }
  }

  /// Get list of all admin users
  static Future<List<Map<String, dynamic>>> getAdminUsers() async {
    try {
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin && !kDebugMode) {
        throw Exception('Not authorized to view admin users');
      }

      final adminsSnapshot =
          await FirebaseFirestore.instance.collection(_adminCollection).get();

      return adminsSnapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();
    } catch (e) {
      DebugLogger.error('Error fetching admin users', e);
      return [];
    }
  }

  /// Diagnose specific admin permission issues by component
  /// Returns detailed diagnostics about specific permission components
  static Future<Map<String, dynamic>>
      diagnoseAdminPermissionComponents() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not signed in');
      }

      Map<String, dynamic> diagnostics = {
        'components': {},
        'overallStatus': 'checking',
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Check Firebase Auth Custom Claims
      try {
        final idTokenResult =
            await currentUser.getIdTokenResult(true); // Force refresh
        diagnostics['components']['firebaseAuthClaims'] = {
          'status':
              idTokenResult.claims?['admin'] == true ? 'healthy' : 'missing',
          'details': {
            'hasAdminClaim': idTokenResult.claims?['admin'] == true,
            'claims': idTokenResult.claims,
            'authTime': idTokenResult.authTime?.toIso8601String(),
            'expirationTime': idTokenResult.expirationTime?.toIso8601String(),
          }
        };
      } catch (e) {
        diagnostics['components']['firebaseAuthClaims'] = {
          'status': 'error',
          'error': e.toString(),
        };
      }

      // Check User Document
      try {
        final userDocRef = FirebaseFirestore.instance
            .collection(_usersCollection)
            .doc(currentUser.uid);

        final userDoc = await userDocRef.get();
        final Map<String, dynamic> userDetails = {
          'exists': userDoc.exists,
          'path': userDocRef.path,
        };

        if (userDoc.exists) {
          final userData = userDoc.data();
          final String? role = userData?['role']?.toString();
          userDetails['data'] = userData;
          userDetails['role'] = role;
          userDetails['isAdmin'] = role?.toLowerCase() == 'admin';

          diagnostics['components']['userDocument'] = {
            'status': role?.toLowerCase() == 'admin' ? 'healthy' : 'incorrect',
            'details': userDetails
          };
        } else {
          diagnostics['components']
              ['userDocument'] = {'status': 'missing', 'details': userDetails};
        }
      } catch (e) {
        diagnostics['components']['userDocument'] = {
          'status': 'error',
          'error': e.toString(),
        };
      }

      // Check Admin Collection Entry
      try {
        final adminDocRef = FirebaseFirestore.instance
            .collection(_adminCollection)
            .doc(currentUser.uid);

        final adminDoc = await adminDocRef.get();
        final Map<String, dynamic> adminDetails = {
          'exists': adminDoc.exists,
          'path': adminDocRef.path,
        };

        if (adminDoc.exists) {
          adminDetails['data'] = adminDoc.data();
          adminDetails['grantedAt'] = adminDoc.data()?['grantedAt'];
          adminDetails['grantedBy'] = adminDoc.data()?['grantedBy'];

          diagnostics['components']['adminDocument'] = {
            'status': 'healthy',
            'details': adminDetails
          };
        } else {
          diagnostics['components']['adminDocument'] = {
            'status': 'missing',
            'details': adminDetails
          };
        }
      } catch (e) {
        diagnostics['components']['adminDocument'] = {
          'status': 'error',
          'error': e.toString(),
        };
      }

      // Check Firestore Rules
      try {
        bool canReadAdminCollection = false;
        bool canWriteAdminCollection = false;

        // Test read permission
        try {
          await FirebaseFirestore.instance
              .collection(_adminCollection)
              .limit(1)
              .get();
          canReadAdminCollection = true;
        } catch (e) {
          canReadAdminCollection = false;
        }

        // Only test write if we should be an admin
        final isAdminInAnyWay = diagnostics['components']['firebaseAuthClaims']
                    ?['details']?['hasAdminClaim'] ==
                true ||
            diagnostics['components']['userDocument']?['details']?['isAdmin'] ==
                true ||
            diagnostics['components']['adminDocument']?['status'] == 'healthy';

        if (isAdminInAnyWay) {
          try {
            // Create a temporary document to test write permission
            final tempDocRef = FirebaseFirestore.instance
                .collection(_adminCollection)
                .doc('__test_write_${DateTime.now().millisecondsSinceEpoch}');

            await tempDocRef.set({
              'test': true,
              'temporary': true,
              'timestamp': FieldValue.serverTimestamp(),
            });
            await tempDocRef.delete();
            canWriteAdminCollection = true;
          } catch (e) {
            canWriteAdminCollection = false;
          }
        }

        diagnostics['components']['firestoreRules'] = {
          'status': canReadAdminCollection
              ? (canWriteAdminCollection ? 'healthy' : 'partial')
              : 'restricted',
          'details': {
            'canRead': canReadAdminCollection,
            'canWrite': canWriteAdminCollection,
          }
        };
      } catch (e) {
        diagnostics['components']['firestoreRules'] = {
          'status': 'error',
          'error': e.toString(),
        };
      }

      // Determine overall status
      int healthyComponents = 0;
      int totalComponents = 0;

      diagnostics['components'].forEach((key, value) {
        totalComponents++;
        if (value['status'] == 'healthy') {
          healthyComponents++;
        }
      });

      if (healthyComponents == totalComponents) {
        diagnostics['overallStatus'] = 'healthy';
      } else if (healthyComponents > 0) {
        diagnostics['overallStatus'] = 'partial';
      } else {
        diagnostics['overallStatus'] = 'unhealthy';
      }

      return diagnostics;
    } catch (e) {
      DebugLogger.error('Error diagnosing admin permission components', e);
      return {
        'overallStatus': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Fix specific admin permission component issues
  /// Returns success status and details of changes made
  static Future<Map<String, dynamic>> fixAdminPermissionComponents({
    required List<String> componentsToFix,
  }) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not signed in');
      }

      // Safety check - only work in debug mode or for confirmed admins
      final bool isAdmin = await isCurrentUserAdmin();
      if (!isAdmin && !kDebugMode) {
        throw Exception('Not authorized to fix admin permissions');
      }

      Map<String, dynamic> results = {
        'fixedComponents': <String>[],
        'failedComponents': <Map<String, dynamic>>[],
        'overallSuccess': false,
      };

      // Fix User Document
      if (componentsToFix.contains('userDocument')) {
        try {
          final userDocRef = FirebaseFirestore.instance
              .collection(_usersCollection)
              .doc(currentUser.uid);

          final userDoc = await userDocRef.get();

          if (userDoc.exists) {
            await userDocRef.update({
              'role': 'admin',
              'updatedAt': FieldValue.serverTimestamp(),
              'updatedBy': 'admin_debugger',
            });
          } else {
            await userDocRef.set({
              'uid': currentUser.uid,
              'email': currentUser.email,
              'role': 'admin',
              'displayName': currentUser.displayName,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'createdBy': 'admin_debugger',
            });
          }

          results['fixedComponents'].add('userDocument');
        } catch (e) {
          results['failedComponents'].add({
            'component': 'userDocument',
            'error': e.toString(),
          });
        }
      }

      // Fix Admin Document
      if (componentsToFix.contains('adminDocument')) {
        try {
          final adminDocRef = FirebaseFirestore.instance
              .collection(_adminCollection)
              .doc(currentUser.uid);

          await adminDocRef.set({
            'uid': currentUser.uid,
            'email': currentUser.email,
            'displayName': currentUser.displayName,
            'grantedAt': FieldValue.serverTimestamp(),
            'grantedBy': 'admin_debugger',
          }, SetOptions(merge: true));

          results['fixedComponents'].add('adminDocument');
        } catch (e) {
          results['failedComponents'].add({
            'component': 'adminDocument',
            'error': e.toString(),
          });
        }
      }

      // Fix Firebase Auth Claims
      // Note: This typically requires a Firebase Function or admin SDK
      if (componentsToFix.contains('firebaseAuthClaims')) {
        if (kDebugMode) {
          // In debug mode, we can simulate this fix by adding other components
          // and noting that a backend action is needed for claims
          results['fixedComponents'].add('firebaseAuthClaims');
          results['notes'] = 'Firebase Auth claims require backend action. '
              'The client app cannot directly update custom claims. '
              'In production, use a Firebase Cloud Function for this.';
        } else {
          results['failedComponents'].add({
            'component': 'firebaseAuthClaims',
            'error':
                'Cannot update Firebase Auth claims from client app. Requires admin SDK or Cloud Function.',
          });
        }
      }

      // Determine overall success
      results['overallSuccess'] = results['fixedComponents'].length > 0 &&
          results['failedComponents'].isEmpty;

      // Force token refresh to pick up any backend changes
      try {
        await FirebaseAuth.instance.currentUser?.getIdToken(true);
      } catch (e) {
        // Non-critical error
        DebugLogger.warning('Failed to refresh auth token after admin fix: $e');
      }

      return results;
    } catch (e) {
      DebugLogger.error('Error fixing admin permission components', e);
      return {
        'overallSuccess': false,
        'error': e.toString(),
      };
    }
  }

  /// Verify Firestore security rules for admin operations
  static Future<Map<String, dynamic>> verifyFirestoreRules() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not signed in');
      }

      final Map<String, dynamic> results = {
        'collections': {},
        'timestamp': DateTime.now().toIso8601String(),
      };

      // List of collections to check permissions on
      final collectionsToCheck = [
        _adminCollection,
        _usersCollection,
        'properties',
        _settingsCollection,
      ];

      // Check read/write permissions for each collection
      for (final collection in collectionsToCheck) {
        results['collections'][collection] =
            await _checkCollectionPermissions(collection);
      }

      return results;
    } catch (e) {
      DebugLogger.error('Error verifying Firestore rules', e);
      return {
        'error': e.toString(),
      };
    }
  }

  /// Private helper to check permissions on a collection
  static Future<Map<String, dynamic>> _checkCollectionPermissions(
      String collectionPath) async {
    final Map<String, dynamic> permissionResults = {
      'read': false,
      'write': false,
      'delete': false,
      'readError': null,
      'writeError': null,
      'deleteError': null,
    };

    try {
      // Check read permission
      try {
        await FirebaseFirestore.instance
            .collection(collectionPath)
            .limit(1)
            .get();
        permissionResults['read'] = true;
      } catch (e) {
        permissionResults['read'] = false;
        permissionResults['readError'] = e.toString();
      }

      // Check write permission with a temporary document
      final String tempDocId =
          '_permission_test_${DateTime.now().millisecondsSinceEpoch}';
      try {
        final tempDocRef = FirebaseFirestore.instance
            .collection(collectionPath)
            .doc(tempDocId);

        await tempDocRef.set({
          'test': true,
          'temporary': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
        permissionResults['write'] = true;

        // If write succeeded, also check delete
        try {
          await tempDocRef.delete();
          permissionResults['delete'] = true;
        } catch (e) {
          permissionResults['delete'] = false;
          permissionResults['deleteError'] = e.toString();
        }
      } catch (e) {
        permissionResults['write'] = false;
        permissionResults['writeError'] = e.toString();
      }
    } catch (e) {
      // Handle any unexpected errors
      return {
        'error': e.toString(),
      };
    }

    return permissionResults;
  }

  /// Function to check if an email exists in the system and get its user ID
  /// Useful for admin operations like granting permissions by email
  static Future<Map<String, dynamic>> findUserByEmail(String email) async {
    try {
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin && !kDebugMode) {
        throw Exception('Not authorized to look up users');
      }

      // Search user collection for matching email
      final querySnapshot = await FirebaseFirestore.instance
          .collection(_usersCollection)
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        return {
          'exists': true,
          'userId': querySnapshot.docs.first.id,
          'userData': userData,
          'isAdmin': userData['role']?.toString().toLowerCase() == 'admin',
        };
      }

      // If not found in users, check admins collection as fallback
      final adminQuerySnapshot = await FirebaseFirestore.instance
          .collection(_adminCollection)
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (adminQuerySnapshot.docs.isNotEmpty) {
        return {
          'exists': true,
          'userId': adminQuerySnapshot.docs.first.id,
          'isAdmin': true,
          'userData': adminQuerySnapshot.docs.first.data(),
        };
      }

      return {
        'exists': false,
      };
    } catch (e) {
      DebugLogger.error('Error finding user by email', e);
      return {
        'exists': false,
        'error': e.toString(),
      };
    }
  }

  /// Export admin diagnostic data for debugging purposes
  static Future<Map<String, dynamic>> exportDiagnosticData() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not signed in');
      }

      // Security check
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin && !kDebugMode) {
        throw Exception('Not authorized to export admin diagnostic data');
      }

      // Collect comprehensive diagnostic data
      final Map<String, dynamic> diagnosticData = {
        'timestamp': DateTime.now().toIso8601String(),
        'user': {
          'uid': currentUser.uid,
          'email': currentUser.email,
          'displayName': currentUser.displayName,
          'emailVerified': currentUser.emailVerified,
          'isAnonymous': currentUser.isAnonymous,
          'metadata': {
            'creationTime':
                currentUser.metadata.creationTime?.toIso8601String(),
            'lastSignInTime':
                currentUser.metadata.lastSignInTime?.toIso8601String(),
          },
        },
        'environment': {
          'isDebugMode': kDebugMode,
        },
        'adminStatus': {
          'isAdmin': isAdmin,
        },
      };

      // Add detailed permission diagnostics
      diagnosticData['permissionComponents'] =
          await diagnoseAdminPermissionComponents();

      // Add Firestore rules verification
      diagnosticData['firestoreRules'] = await verifyFirestoreRules();

      return diagnosticData;
    } catch (e) {
      DebugLogger.error('Error exporting diagnostic data', e);
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
