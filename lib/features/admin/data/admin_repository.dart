import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../domain/models/audit_log.dart';
import '../domain/models/admin_stats.dart';
import '../domain/models/admin_user.dart';
import '../domain/models/property_trend.dart';
import 'dart:convert';
import '../../../../core/utils/debug_logger.dart';

class AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Fetch admin dashboard stats
  Future<AdminStats> fetchDashboardStats() async {
    try {
      // In a real app, this would fetch from Firestore
      // For now, we'll use mock data
      return AdminStats.generateMockData();
    } catch (e) {
      throw Exception('Failed to fetch dashboard stats: $e');
    }
  }

  // Fetch property trends
  Future<List<PropertyTrend>> fetchPropertyTrends({int months = 6}) async {
    try {
      // In a real app, this would fetch from Firestore
      // For now, we'll generate mock data
      final List<PropertyTrend> trends = [];
      final now = DateTime.now();

      for (int i = months - 1; i >= 0; i--) {
        final month = now.month - i;
        final year = now.year + (month <= 0 ? -1 : 0);
        final adjustedMonth = month <= 0 ? month + 12 : month;

        final monthName = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ][adjustedMonth - 1];

        trends.add(PropertyTrend(
          month: '$monthName ${year.toString().substring(2)}',
          count: 50 + (adjustedMonth * 10) + (month % 3 == 0 ? 30 : 0),
          revenue: 5000 + (adjustedMonth * 500) + (month % 2 == 0 ? 1000 : 0),
          viewCount: 500 + (adjustedMonth * 100) + (month % 2 == 0 ? 200 : 0),
        ));
      }

      return trends;
    } catch (e) {
      throw Exception('Failed to fetch property trends: $e');
    }
  }

  // Fetch users for admin
  Future<List<AdminUser>> fetchUsers({String? searchQuery}) async {
    try {
      Query query = _firestore.collection('users');

      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Search by display name or email using array contains
        query = query.where('searchTerms',
            arrayContains: searchQuery.toLowerCase());
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => AdminUser.fromFirestore(doc)).toList();
    } catch (e) {
      DebugLogger.error('Failed to fetch users', e);
      throw Exception('Failed to fetch users: $e');
    }
  }

  // Base method to call Cloud Functions with retry logic
  Future<dynamic> _callCloudFunction(
      String functionName, Map<String, dynamic> data,
      {int maxRetries = 3}) async {
    int retryCount = 0;
    late dynamic lastError;

    while (retryCount < maxRetries) {
      try {
        final result = await _functions.httpsCallable(functionName).call(data);
        return result.data;
      } catch (e) {
        lastError = e;
        DebugLogger.error(
            'Error calling $functionName (attempt ${retryCount + 1}/$maxRetries)',
            e);

        // Check if it's worth retrying
        if (e.toString().contains('permission-denied') ||
            e.toString().contains('unauthenticated')) {
          throw e; // Don't retry auth errors
        }

        if (retryCount < maxRetries - 1) {
          await Future.delayed(Duration(seconds: retryCount + 1));
          retryCount++;
          continue;
        }
        throw e;
      }
    }
    throw lastError;
  }

  // Update user role using Cloud Functions
  Future<void> updateUserRole(String userId, bool isAdmin) async {
    try {
      final result = await _callCloudFunction('setUserAdminRole', {
        'userId': userId,
        'isAdmin': isAdmin,
      });

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Unknown error updating user role');
      }

      // Log this action for audit purposes
      await logAdminAction(
        action: isAdmin ? 'grant_admin_role' : 'revoke_admin_role',
        metadata: {'userId': userId},
      );
    } catch (e) {
      DebugLogger.error('Failed to update user role', e);
      throw Exception('Failed to update user role: $e');
    }
  }

  // Update user status using Cloud Functions
  Future<void> updateUserStatus(String userId, String status) async {
    try {
      final result = await _callCloudFunction('updateUserStatus', {
        'userId': userId,
        'status': status,
      });

      if (result['success'] != true) {
        throw Exception(
            result['error'] ?? 'Unknown error updating user status');
      }

      // Log this action
      await logAdminAction(
        action: 'update_user_status',
        metadata: {'userId': userId, 'status': status},
      );
    } catch (e) {
      DebugLogger.error('Failed to update user status', e);
      throw Exception('Failed to update user status: $e');
    }
  }

  // Bulk update user roles using Cloud Functions
  Future<void> bulkUpdateUserRoles(List<String> userIds, bool isAdmin) async {
    try {
      final result = await _callCloudFunction('bulkUpdateUserRoles', {
        'userIds': userIds,
        'isAdmin': isAdmin,
      });

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Unknown error during bulk update');
      }

      // Log this action
      await logAdminAction(
        action: isAdmin ? 'bulk_grant_admin_role' : 'bulk_revoke_admin_role',
        metadata: {'userIds': userIds},
      );
    } catch (e) {
      DebugLogger.error('Failed to bulk update user roles', e);
      throw Exception('Failed to bulk update user roles: $e');
    }
  }

  // Fetch audit logs
  Future<List<AuditLog>> fetchAuditLogs({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('admin_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      // Use the correct fromMap method with document ID
      return snapshot.docs.map((doc) {
        return AuditLog.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch audit logs: $e');
    }
  }

  // Log admin action
  Future<void> logAdminAction({
    required String action,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final log = {
        'userId': user.uid,
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
        'ipAddress': 'Unknown', // In a real app, get from server or client
        'deviceInfo': {
          'platform': 'Flutter',
          'appVersion': '1.0.0',
          // In a real app, collect more device info
        },
        'metadata': metadata,
      };

      await _firestore.collection('admin_logs').add(log);
    } catch (e) {
      DebugLogger.error('Failed to log admin action: $e');
      throw Exception('Failed to log admin action: $e');
    }
  }

  // Add property creation method
  Future<void> createProperty(Map<String, dynamic> propertyData) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Add owner information
      propertyData['ownerId'] = currentUser.uid;
      propertyData['ownerEmail'] = currentUser.email;
      propertyData['status'] = 'pending';
      propertyData['createdAt'] = FieldValue.serverTimestamp();

      // Create the document
      await _firestore.collection('properties').add(propertyData);

      // Log this action
      await logAdminAction(
        action: 'property_create',
        metadata: {'propertyTitle': propertyData['title']},
      );
    } catch (e) {
      throw Exception('Failed to create property: $e');
    }
  }

  // Fetch flagged properties for moderation
  Future<List<Map<String, dynamic>>> fetchFlaggedProperties() async {
    try {
      final snapshot = await _firestore
          .collection('properties')
          .where('isFlagged', isEqualTo: true)
          .where('moderationStatus', isEqualTo: 'pending')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'title': data['title'] ?? 'Untitled Property',
          'flaggedBy': data['flaggedBy'] ?? 'Unknown',
          'flagReason': data['flagReason'] ?? 'No reason provided',
          'description': data['description'] ?? 'No description',
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch flagged properties: $e');
    }
  }

  // Method to export users to JSON
  Future<String> exportUsersToJSON() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final List<Map<String, dynamic>> jsonData = snapshot.docs.map((doc) {
        final data = doc.data();
        // Convert Timestamp to ISO string format
        if (data['lastActive'] != null) {
          data['lastActive'] =
              (data['lastActive'] as Timestamp).toDate().toIso8601String();
        }
        if (data['createdAt'] != null) {
          data['createdAt'] =
              (data['createdAt'] as Timestamp).toDate().toIso8601String();
        }
        return data;
      }).toList();
      return jsonEncode(jsonData);
    } catch (e) {
      DebugLogger.error('Failed to export users to JSON', e);
      throw Exception('Failed to export users to JSON: $e');
    }
  }

  // Method to export users to CSV
  Future<String> exportUsersToCSV() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final StringBuffer csv = StringBuffer();
      csv.writeln('Email,Name,Role,Last Active,Status,Created At');

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final lastActive = data['lastActive'] as Timestamp?;
        final createdAt = data['createdAt'] as Timestamp?;

        csv.writeln('"${data['email'] ?? ''}","${data['displayName'] ?? ''}",'
            '"${data['isAdmin'] == true ? 'Admin' : 'User'}",'
            '"${lastActive?.toDate().toIso8601String() ?? ''}",'
            '"${data['status'] ?? ''}",'
            '"${createdAt?.toDate().toIso8601String() ?? ''}"');
      }
      return csv.toString();
    } catch (e) {
      DebugLogger.error('Failed to export users to CSV', e);
      throw Exception('Failed to export users to CSV: $e');
    }
  }
}
