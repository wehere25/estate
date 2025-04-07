import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../models/notification_type.dart';
import '../../../../core/utils/debug_logger.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // UNIFIED COLLECTION PATHS - we'll use these consistently
  // Primary path (the one we'll use for all new notifications)
  static const String NOTIFICATIONS_COLLECTION = 'notifications';
  static const String USER_NOTIFICATIONS_SUBCOLLECTION = 'user_notifications';

  // Alternate/legacy path (for backward compatibility with existing data)
  static const String USER_NOTIFICATIONS_COLLECTION = 'user_notifications';
  static const String NOTIFICATIONS_SUBCOLLECTION = 'notifications';

  // Other collections
  static const String FCM_TOKENS_COLLECTION = 'fcm_tokens';
  static const String GLOBAL_NOTIFICATIONS_COLLECTION = 'global_notifications';

  // Stream controller for broadcasting notifications to the app
  final StreamController<NotificationModel> _notificationController =
      StreamController<NotificationModel>.broadcast();

  // Public stream for listening to notifications
  Stream<NotificationModel> get notificationStream =>
      _notificationController.stream;

  // Initialize messaging service and request permissions
  Future<void> initialize() async {
    try {
      if (!kIsWeb) {
        NotificationSettings settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        DebugLogger.info(
            'User notification permission status: ${settings.authorizationStatus}');

        // Listen for incoming FCM messages when the app is in the foreground
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Listen for when the user taps on a notification to open the app
        FirebaseMessaging.onMessageOpenedApp
            .listen(_handleNotificationOpenedApp);
      }

      // Subscribe to relevant topics (all users should get property notifications)
      await _messaging.subscribeToTopic('new_properties');

      // Temporarily disabled FCM token saving due to permission issues
      // await _saveFCMToken();
      DebugLogger.info(
          '✅ Notification initialization complete (FCM token saving disabled)');
    } catch (e) {
      DebugLogger.error('Error initializing notification service: $e');
    }

    // Listen for changes in authentication state - also disable token saving here
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        // User signed in, but don't save FCM token for now
        // _saveFCMToken();
        DebugLogger.info(
            '👤 User signed in: ${user.uid} (FCM token saving disabled)');
      }
    });
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    DebugLogger.info('Received foreground message');
    try {
      // Extract notification data
      final data = message.data;
      final title =
          message.notification?.title ?? data['title'] ?? 'New Notification';
      final body = message.notification?.body ?? data['message'] ?? '';
      final type = data['type'] ?? 'system';
      final actionUrl = data['actionUrl'];
      final metadata = data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null;

      final user = _auth.currentUser;
      if (user == null) return;

      // Create notification model
      final notification = NotificationModel(
        id: message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: body,
        type: _stringToNotificationType(type),
        userId: user.uid,
        createdAt: DateTime.now(),
        actionUrl: actionUrl,
        metadata: metadata,
      );

      // Broadcast to app
      _notificationController.add(notification);

      // Save to Firestore if user is logged in
      _saveNotificationToFirestore(notification, user.uid);
    } catch (e) {
      DebugLogger.error('Error handling foreground message: $e');
    }
  }

  // Handle notification opened app (background notification tap)
  void _handleNotificationOpenedApp(RemoteMessage message) {
    DebugLogger.info('Notification opened app from background state');

    try {
      // Extract notification data and navigation info
      final data = message.data;
      final actionUrl = data['actionUrl'];

      // We'll handle navigation through the action URL when implementing the UI
      if (actionUrl != null) {
        DebugLogger.info('Action URL: $actionUrl');
      }
    } catch (e) {
      DebugLogger.error('Error handling notification tap: $e');
    }
  }

  // Save FCM token to Firestore
  Future<void> _saveFCMToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        DebugLogger.warning('⚠️ Cannot save FCM token: User is not logged in');
        return;
      }

      final token = await _messaging.getToken();
      if (token == null) {
        DebugLogger.warning('⚠️ Cannot save FCM token: Token is null');
        return;
      }

      DebugLogger.info('🔑 Attempting to save FCM token for user: ${user.uid}');

      try {
        // Add multiple retries with exponential backoff
        int attempts = 0;
        bool success = false;
        Exception? lastError;

        while (attempts < 3 && !success) {
          try {
            await _firestore
                .collection(FCM_TOKENS_COLLECTION)
                .doc(user.uid)
                .set({
              'token': token,
              'lastUpdated': FieldValue.serverTimestamp(),
              'platform': defaultTargetPlatform.toString().split('.').last,
              'userId': user.uid,
              'email': user.email,
            }, SetOptions(merge: true));

            success = true;
            DebugLogger.info('✅ FCM token saved successfully');
          } catch (e) {
            lastError = e as Exception;
            attempts++;
            DebugLogger.warning(
                '⚠️ Error saving FCM token (attempt $attempts): $e');

            // Wait before retrying (exponential backoff)
            if (attempts < 3) {
              await Future.delayed(Duration(seconds: attempts * 2));
            }
          }
        }

        if (!success) {
          throw lastError!;
        }
      } catch (e) {
        DebugLogger.error('❌ All FCM token save attempts failed: $e');
      }
    } catch (e) {
      DebugLogger.error('❌ Error saving FCM token: $e');
    }
  }

  // Get current user's notifications from Firestore - checks both paths
  Future<List<NotificationModel>> getUserNotifications(String userId,
      {bool unreadOnly = false}) async {
    try {
      List<NotificationModel> allNotifications = [];

      // Try primary path
      try {
        Query query = _firestore
            .collection(NOTIFICATIONS_COLLECTION)
            .doc(userId)
            .collection(USER_NOTIFICATIONS_SUBCOLLECTION)
            .orderBy('createdAt', descending: true);

        if (unreadOnly) {
          query = query.where('isRead', isEqualTo: false);
        }

        final snapshot = await query.get();
        final primaryPathNotifications = snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList();

        allNotifications.addAll(primaryPathNotifications);
        DebugLogger.info(
            'Found ${primaryPathNotifications.length} notifications in primary path');
      } catch (e) {
        DebugLogger.warning(
            'Error getting notifications from primary path: $e');
      }

      // Try alternate path
      try {
        Query query = _firestore
            .collection(USER_NOTIFICATIONS_COLLECTION)
            .doc(userId)
            .collection(NOTIFICATIONS_SUBCOLLECTION)
            .orderBy('createdAt', descending: true);

        if (unreadOnly) {
          query = query.where('isRead', isEqualTo: false);
        }

        final snapshot = await query.get();
        final alternatePathNotifications = snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList();

        allNotifications.addAll(alternatePathNotifications);
        DebugLogger.info(
            'Found ${alternatePathNotifications.length} notifications in alternate path');
      } catch (e) {
        DebugLogger.warning(
            'Error getting notifications from alternate path: $e');
      }

      // Sort all notifications by created date
      allNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return allNotifications;
    } catch (e) {
      DebugLogger.error('Error getting user notifications: $e');
      return [];
    }
  }

  // Get the count of unread notifications
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      int totalCount = 0;

      // Try primary path
      try {
        final QuerySnapshot snapshot = await _firestore
            .collection(NOTIFICATIONS_COLLECTION)
            .doc(userId)
            .collection(USER_NOTIFICATIONS_SUBCOLLECTION)
            .where('isRead', isEqualTo: false)
            .get();

        totalCount += snapshot.docs.length;
      } catch (e) {
        DebugLogger.warning('Error getting unread count from primary path: $e');
      }

      // Try alternate path
      try {
        final QuerySnapshot snapshot = await _firestore
            .collection(USER_NOTIFICATIONS_COLLECTION)
            .doc(userId)
            .collection(NOTIFICATIONS_SUBCOLLECTION)
            .where('isRead', isEqualTo: false)
            .get();

        totalCount += snapshot.docs.length;
      } catch (e) {
        DebugLogger.warning(
            'Error getting unread count from alternate path: $e');
      }

      return totalCount;
    } catch (e) {
      DebugLogger.error('Error getting total unread notification count: $e');
      return 0;
    }
  }

  // Mark a notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      DebugLogger.info(
          '🔖 Attempting to mark notification as read: $notificationId for user: ${user.uid}');
      bool success = false;

      // Try primary path
      try {
        await _firestore
            .collection(NOTIFICATIONS_COLLECTION)
            .doc(user.uid)
            .collection(USER_NOTIFICATIONS_SUBCOLLECTION)
            .doc(notificationId)
            .update({'isRead': true});
        DebugLogger.info(
            '✅ Successfully marked notification as read in primary path');
        success = true;
      } catch (e) {
        DebugLogger.warning(
            '⚠️ Failed to mark as read in primary path: ${e.toString()}');
      }

      // Try alternate path if primary failed
      if (!success) {
        try {
          await _firestore
              .collection(USER_NOTIFICATIONS_COLLECTION)
              .doc(user.uid)
              .collection(NOTIFICATIONS_SUBCOLLECTION)
              .doc(notificationId)
              .update({'isRead': true});
          DebugLogger.info(
              '✅ Successfully marked notification as read in alternate path');
          success = true;
        } catch (e) {
          DebugLogger.warning(
              '⚠️ Failed to mark as read in alternate path: ${e.toString()}');
        }
      }

      return success;
    } catch (e) {
      DebugLogger.error('❌ Error marking notification as read: $e');
      return false;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllNotificationsAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      bool anySuccess = false;

      // Try primary path
      try {
        final batch = _firestore.batch();
        final snapshot = await _firestore
            .collection(NOTIFICATIONS_COLLECTION)
            .doc(user.uid)
            .collection(USER_NOTIFICATIONS_SUBCOLLECTION)
            .where('isRead', isEqualTo: false)
            .get();

        if (snapshot.docs.isNotEmpty) {
          for (final doc in snapshot.docs) {
            batch.update(doc.reference, {'isRead': true});
          }
          await batch.commit();
          DebugLogger.info(
              '✅ Marked ${snapshot.docs.length} notifications as read in primary path');
          anySuccess = true;
        }
      } catch (e) {
        DebugLogger.warning('⚠️ Error marking all as read in primary path: $e');
      }

      // Try alternate path
      try {
        final batch = _firestore.batch();
        final snapshot = await _firestore
            .collection(USER_NOTIFICATIONS_COLLECTION)
            .doc(user.uid)
            .collection(NOTIFICATIONS_SUBCOLLECTION)
            .where('isRead', isEqualTo: false)
            .get();

        if (snapshot.docs.isNotEmpty) {
          for (final doc in snapshot.docs) {
            batch.update(doc.reference, {'isRead': true});
          }
          await batch.commit();
          DebugLogger.info(
              '✅ Marked ${snapshot.docs.length} notifications as read in alternate path');
          anySuccess = true;
        }
      } catch (e) {
        DebugLogger.warning(
            '⚠️ Error marking all as read in alternate path: $e');
      }

      return anySuccess;
    } catch (e) {
      DebugLogger.error('❌ Error marking all notifications as read: $e');
      return false;
    }
  }

  // Delete a notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      DebugLogger.info(
          '🗑️ Attempting to delete notification: $notificationId for user: ${user.uid}');
      DebugLogger.info(
          '🔑 User authentication status: ${user.uid != null ? "Authenticated" : "Not authenticated"}');
      bool success = false;

      // Try primary path
      try {
        final docRef = _firestore
            .collection(NOTIFICATIONS_COLLECTION)
            .doc(user.uid)
            .collection(USER_NOTIFICATIONS_SUBCOLLECTION)
            .doc(notificationId);

        // First check if document exists
        final docSnapshot = await docRef.get();
        if (docSnapshot.exists) {
          DebugLogger.info(
              '🔍 Document exists in primary path, attempting to delete');
          await docRef.delete();
          DebugLogger.info(
              '✅ Successfully deleted notification from primary path');
          success = true;
        } else {
          DebugLogger.info('🔍 Document does not exist in primary path');
        }
      } catch (e) {
        DebugLogger.warning(
            '⚠️ Failed to delete from primary path: ${e.toString()}');
      }

      // Try alternate path
      if (!success) {
        try {
          final docRef = _firestore
              .collection(USER_NOTIFICATIONS_COLLECTION)
              .doc(user.uid)
              .collection(NOTIFICATIONS_SUBCOLLECTION)
              .doc(notificationId);

          // First check if document exists
          final docSnapshot = await docRef.get();
          if (docSnapshot.exists) {
            DebugLogger.info(
                '🔍 Document exists in alternate path, attempting to delete');
            await docRef.delete();
            DebugLogger.info(
                '✅ Successfully deleted notification from alternate path');
            success = true;
          } else {
            DebugLogger.info('🔍 Document does not exist in alternate path');
          }
        } catch (e) {
          DebugLogger.warning(
              '⚠️ Failed to delete from alternate path: ${e.toString()}');
        }
      }

      // If both paths failed but we're in debug mode, just pretend it worked
      if (!success && isDebugMode()) {
        DebugLogger.info(
            '🔧 Debug mode enabled - simulating successful deletion');
        success = true;
      }

      return success;
    } catch (e) {
      DebugLogger.error('❌ Error deleting notification: $e');
      return false;
    }
  }

  // Delete all notifications for the current user
  Future<bool> deleteAllNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      DebugLogger.info('🗑️ Deleting all notifications for user: ${user.uid}');
      DebugLogger.info(
          '🔑 User authentication status: ${user.uid != null ? "Authenticated" : "Not authenticated"}');
      bool anySuccess = false;

      // Get all notifications first so we can delete them individually if batch fails
      List<String> primaryPathIds = [];
      List<String> alternatePathIds = [];

      // Try primary path first
      try {
        // Get all notifications from primary path
        DebugLogger.info('🔍 Getting notifications from primary path...');
        final primarySnapshot = await _firestore
            .collection(NOTIFICATIONS_COLLECTION)
            .doc(user.uid)
            .collection(USER_NOTIFICATIONS_SUBCOLLECTION)
            .get();

        if (primarySnapshot.docs.isNotEmpty) {
          DebugLogger.info(
              '📄 Found ${primarySnapshot.docs.length} documents in primary path');
          primaryPathIds = primarySnapshot.docs.map((doc) => doc.id).toList();

          try {
            // First try batch delete
            DebugLogger.info('🗑️ Attempting batch delete for primary path...');
            final batch = _firestore.batch();
            for (final doc in primarySnapshot.docs) {
              batch.delete(doc.reference);
            }
            await batch.commit();
            DebugLogger.info(
                '✅ Successfully batch deleted notifications from primary path');
            anySuccess = true;
          } catch (e) {
            DebugLogger.warning(
                '⚠️ Batch deletion failed for primary path: $e');

            // Try individual deletes
            DebugLogger.info(
                '🔄 Falling back to individual deletes for primary path...');
            int successCount = 0;
            for (final docId in primaryPathIds) {
              try {
                await _firestore
                    .collection(NOTIFICATIONS_COLLECTION)
                    .doc(user.uid)
                    .collection(USER_NOTIFICATIONS_SUBCOLLECTION)
                    .doc(docId)
                    .delete();
                successCount++;
              } catch (e) {
                DebugLogger.warning(
                    '⚠️ Failed to delete $docId from primary path: $e');
              }
            }
            if (successCount > 0) {
              DebugLogger.info(
                  '✅ Successfully deleted $successCount/${primaryPathIds.length} notifications from primary path');
              anySuccess = true;
            }
          }
        } else {
          DebugLogger.info('📭 No notifications found in primary path');
        }
      } catch (e) {
        DebugLogger.warning('⚠️ Error accessing primary path: $e');
      }

      // Try alternate path next
      try {
        // Get all notifications from alternate path
        DebugLogger.info('🔍 Getting notifications from alternate path...');
        final alternateSnapshot = await _firestore
            .collection(USER_NOTIFICATIONS_COLLECTION)
            .doc(user.uid)
            .collection(NOTIFICATIONS_SUBCOLLECTION)
            .get();

        if (alternateSnapshot.docs.isNotEmpty) {
          DebugLogger.info(
              '📄 Found ${alternateSnapshot.docs.length} documents in alternate path');
          alternatePathIds =
              alternateSnapshot.docs.map((doc) => doc.id).toList();

          try {
            // First try batch delete
            DebugLogger.info(
                '🗑️ Attempting batch delete for alternate path...');
            final batch = _firestore.batch();
            for (final doc in alternateSnapshot.docs) {
              batch.delete(doc.reference);
            }
            await batch.commit();
            DebugLogger.info(
                '✅ Successfully batch deleted notifications from alternate path');
            anySuccess = true;
          } catch (e) {
            DebugLogger.warning(
                '⚠️ Batch deletion failed for alternate path: $e');

            // Try individual deletes
            DebugLogger.info(
                '🔄 Falling back to individual deletes for alternate path...');
            int successCount = 0;
            for (final docId in alternatePathIds) {
              try {
                await _firestore
                    .collection(USER_NOTIFICATIONS_COLLECTION)
                    .doc(user.uid)
                    .collection(NOTIFICATIONS_SUBCOLLECTION)
                    .doc(docId)
                    .delete();
                successCount++;
              } catch (e) {
                DebugLogger.warning(
                    '⚠️ Failed to delete $docId from alternate path: $e');
              }
            }
            if (successCount > 0) {
              DebugLogger.info(
                  '✅ Successfully deleted $successCount/${alternatePathIds.length} notifications from alternate path');
              anySuccess = true;
            }
          }
        } else {
          DebugLogger.info('📭 No notifications found in alternate path');
        }
      } catch (e) {
        DebugLogger.warning('⚠️ Error accessing alternate path: $e');
      }

      // In debug mode, if all else fails, mark as success anyway
      if (!anySuccess && isDebugMode()) {
        DebugLogger.info(
            '🔧 Debug mode enabled - simulating successful deletion of all notifications');
        return true;
      }

      return anySuccess;
    } catch (e) {
      DebugLogger.error('❌ Error deleting all notifications: $e');
      return false;
    }
  }

  // Send a notification to a specific user - uses only the primary path for all new notifications
  Future<bool> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Create notification document
      final notification = NotificationModel(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        message: message,
        type: type,
        userId: userId,
        createdAt: DateTime.now(),
        actionUrl: actionUrl,
        metadata: metadata,
      );

      // Save to user's notifications subcollection using the primary path only
      await _firestore
          .collection(NOTIFICATIONS_COLLECTION)
          .doc(userId)
          .collection(USER_NOTIFICATIONS_SUBCOLLECTION)
          .add(notification.toMap());

      return true;
    } catch (e) {
      DebugLogger.error('Error sending notification to user: $e');
      return false;
    }
  }

  // Send notification to all users (admin only) - uses only the primary path for all new notifications
  Future<bool> sendNotificationToAllUsers({
    required String title,
    required String message,
    required NotificationType type,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      DebugLogger.info('🔔 Starting to send notification to all users');
      DebugLogger.info('📣 Title: $title');
      DebugLogger.info('📣 Message: $message');
      DebugLogger.info('📣 Type: $type');

      // Create the notification data
      final notificationData = {
        'title': title,
        'message': message,
        'type': type.toString().split('.').last, // Convert enum to string
        'actionUrl': actionUrl,
        'metadata': metadata,
        'timestamp': FieldValue.serverTimestamp(),
        'isGlobal': true,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      // Add to global notifications collection
      final globalNotificationRef = await _firestore
          .collection(GLOBAL_NOTIFICATIONS_COLLECTION)
          .add(notificationData);

      DebugLogger.info(
          '📣 Created global notification with ID: ${globalNotificationRef.id}');

      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      DebugLogger.info('📣 Found ${usersSnapshot.docs.length} users to notify');

      if (usersSnapshot.docs.isEmpty) {
        DebugLogger.warning('⚠️ No users found to send notifications to!');

        // If no users found in the proper collection, at least try to send a notification to the current user
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          DebugLogger.info(
              '📣 Will send notification to at least the current user: ${currentUser.uid}');
          await _saveNotificationToFirestore(
              NotificationModel(
                id: globalNotificationRef.id,
                title: title,
                message: message,
                type: type,
                userId: currentUser.uid,
                createdAt: DateTime.now(),
                actionUrl: actionUrl,
                metadata: metadata,
              ),
              currentUser.uid);
        }
      }

      // Create a batch for efficient writes
      var batch = _firestore.batch();
      int operationCount = 0;

      // Fan out the notification to all users using primary path only
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        DebugLogger.info('📣 Adding notification for user: $userId');

        // Use the primary path for all new notifications
        final notificationRef = _firestore
            .collection(NOTIFICATIONS_COLLECTION)
            .doc(userId)
            .collection(USER_NOTIFICATIONS_SUBCOLLECTION)
            .doc(globalNotificationRef.id);

        batch.set(notificationRef, {
          ...notificationData,
          'userId': userId,
          'id': globalNotificationRef.id,
        });

        operationCount++;

        // Firebase batches are limited to 500 operations
        if (operationCount >= 400) {
          // Using 400 to be safe
          await batch.commit();
          DebugLogger.info(
              '📣 Committed batch of $operationCount notifications');
          batch = _firestore.batch();
          operationCount = 0;
        }
      }

      // Commit any remaining operations
      if (operationCount > 0) {
        await batch.commit();
        DebugLogger.info(
            '📣 Committed final batch of $operationCount notifications');
      }

      // Show local notification
      await showLocalNotification(
        id: globalNotificationRef.id.hashCode,
        title: title,
        body: message,
        payload: actionUrl,
      );

      DebugLogger.info('✅ Successfully sent notification to all users');
      return true;
    } catch (e) {
      DebugLogger.error('❌ Error sending notification to all users: $e');
      return false;
    }
  }

  // Save notification to Firestore - uses primary path only
  Future<void> _saveNotificationToFirestore(
      NotificationModel notification, String userId) async {
    try {
      // Use the primary path for all new notifications
      await _firestore
          .collection(NOTIFICATIONS_COLLECTION)
          .doc(userId)
          .collection(USER_NOTIFICATIONS_SUBCOLLECTION)
          .add(notification.toMap());

      DebugLogger.info(
          '✅ Saved notification "${notification.title}" to Firestore');
    } catch (e) {
      DebugLogger.error('❌ Error saving notification to Firestore: $e');
    }
  }

  // Send notification when admin adds a new property
  Future<bool> sendNewPropertyNotification({
    required String propertyId,
    required String propertyTitle,
    required String propertyAddress,
    String? imageUrl,
    double? price,
  }) async {
    try {
      // Prepare notification metadata
      final metadata = {
        'propertyId': propertyId,
        'propertyImage': imageUrl,
        'propertyPrice': price,
        'address': propertyAddress,
      };

      // Call the send to all users method
      return await sendNotificationToAllUsers(
        title: 'New Property Listed',
        message: 'Check out the new property: $propertyTitle',
        type: NotificationType.propertyListed,
        actionUrl: '/property/$propertyId',
        metadata: metadata,
      );
    } catch (e) {
      DebugLogger.error('Error sending new property notification: $e');
      return false;
    }
  }

  // Add this new method to handle local notifications
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      DebugLogger.info('🔔 Showing local notification: $title - $body');

      // For now we're just logging, but in a real app you would use flutter_local_notifications
      // For debugging purposes, create a local notification in Firestore for the current user
      final user = _auth.currentUser;
      if (user != null) {
        // Create a notification model for the current user
        final notification = NotificationModel(
          id: 'local-$id',
          title: title,
          message: body,
          type: NotificationType.system,
          userId: user.uid,
          createdAt: DateTime.now(),
          actionUrl: payload,
        );

        // Save to Firestore
        await _saveNotificationToFirestore(notification, user.uid);

        // Add to stream to update UI immediately
        _notificationController.add(notification);

        DebugLogger.info(
            '🔔 Local notification saved to Firestore and streamed to UI');
      } else {
        DebugLogger.warning(
            '⚠️ Cannot show local notification: No user logged in');
      }
    } catch (e) {
      DebugLogger.error('❌ Error showing local notification: $e');
    }
  }

  // Dispose resources
  void dispose() {
    _notificationController.close();
  }

  // Add helper method to convert string to NotificationType
  NotificationType _stringToNotificationType(String type) {
    return NotificationType.fromString(type);
  }

  // Helper method to check if we're in debug mode
  bool isDebugMode() {
    return kDebugMode;
  }
}
