import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../data/notification_model.dart'; // Updated import path
import '../../../../core/utils/debug_logger.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String _notificationsCollection = 'notifications';
  static const String _userNotificationsSubCollection = 'user_notifications';
  static const String _fcmTokensCollection = 'fcm_tokens';
  static const globalNotificationsCollection = 'global_notifications';

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

      // Save FCM token to Firestore for targeted messages
      await _saveFCMToken();
    } catch (e) {
      DebugLogger.error('Error initializing notification service: $e');
    }

    // Listen for changes in authentication state
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        // User signed in, save FCM token
        _saveFCMToken();
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
      if (user == null) return;

      final token = await _messaging.getToken();
      if (token == null) return;

      await _firestore.collection(_fcmTokensCollection).doc(user.uid).set({
        'token': token,
        'lastUpdated': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.toString().split('.').last,
        'userId': user.uid,
        'email': user.email,
      }, SetOptions(merge: true));

      DebugLogger.info('FCM token saved successfully');
    } catch (e) {
      DebugLogger.error('Error saving FCM token: $e');
    }
  }

  // Get current user's notifications from Firestore
  Future<List<NotificationModel>> getUserNotifications(String userId,
      {bool unreadOnly = false}) async {
    try {
      Query query = _firestore
          .collection(_notificationsCollection)
          .doc(userId)
          .collection(_userNotificationsSubCollection)
          .orderBy('createdAt', descending: true);

      if (unreadOnly) {
        query = query.where('isRead', isEqualTo: false);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      DebugLogger.error('Error getting user notifications: $e');
      return [];
    }
  }

  // Get the count of unread notifications
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_notificationsCollection)
          .doc(userId)
          .collection(_userNotificationsSubCollection)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      DebugLogger.error('Error getting unread notification count: $e');
      return 0;
    }
  }

  // Mark a notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection(_notificationsCollection)
          .doc(user.uid)
          .collection(_userNotificationsSubCollection)
          .doc(notificationId)
          .update({'isRead': true});

      return true;
    } catch (e) {
      DebugLogger.error('Error marking notification as read: $e');
      return false;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllNotificationsAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final batch = _firestore.batch();

      // Get all unread notifications
      final snapshot = await _firestore
          .collection(_notificationsCollection)
          .doc(user.uid)
          .collection(_userNotificationsSubCollection)
          .where('isRead', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return true;

      // Mark each as read in a batch
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      return true;
    } catch (e) {
      DebugLogger.error('Error marking all notifications as read: $e');
      return false;
    }
  }

  // Delete a notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection(_notificationsCollection)
          .doc(user.uid)
          .collection(_userNotificationsSubCollection)
          .doc(notificationId)
          .delete();

      return true;
    } catch (e) {
      DebugLogger.error('Error deleting notification: $e');
      return false;
    }
  }

  // Send a notification to a specific user
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

      // Save to user's notifications subcollection
      await _firestore
          .collection(_notificationsCollection)
          .doc(userId)
          .collection(_userNotificationsSubCollection)
          .add(notification.toMap());

      return true;
    } catch (e) {
      DebugLogger.error('Error sending notification to user: $e');
      return false;
    }
  }

  // Send notification to all users (admin only)
  Future<bool> sendNotificationToAllUsers({
    required String title,
    required String message,
    required NotificationType type,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Create the notification data
      final notificationData = {
        'title': title,
        'message': message,
        'type': type.toString(),
        'actionUrl': actionUrl,
        'metadata': metadata,
        'timestamp': FieldValue.serverTimestamp(),
        'isGlobal': true,
      };

      // Add to global notifications collection
      final globalNotificationRef = await _firestore
          .collection(globalNotificationsCollection)
          .add(notificationData);

      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();

      // Create a batch for efficient writes
      var batch = _firestore.batch();
      int operationCount = 0;

      // Fan out the notification to all users
      for (var userDoc in usersSnapshot.docs) {
        final notificationRef = _firestore
            .collection(_userNotificationsSubCollection)
            .doc(userDoc.id)
            .collection('notifications')
            .doc(globalNotificationRef.id);

        batch.set(notificationRef, {
          ...notificationData,
          'read': false,
          'userId': userDoc.id,
        });

        operationCount++;

        // Firebase batches are limited to 500 operations
        if (operationCount >= 400) {
          // Using 400 to be safe
          await batch.commit();
          batch = _firestore.batch();
          operationCount = 0;
        }
      }

      // Commit any remaining operations
      if (operationCount > 0) {
        await batch.commit();
      }

      return true;
    } catch (e) {
      DebugLogger.error('Error sending notification to all users: $e');
      return false;
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
        'imageUrl': imageUrl,
        'price': price,
        'address': propertyAddress,
      };

      // Call the send to all users method
      return await sendNotificationToAllUsers(
        title: 'New Property Listed',
        message: 'Check out the new property: $propertyTitle',
        type: NotificationType.propertyListed, // Corrected constant
        actionUrl: '/property/$propertyId',
        metadata: metadata,
      );
    } catch (e) {
      DebugLogger.error('Error sending new property notification: $e');
      return false;
    }
  }

  // For testing: Create a sample notification for the current user
  Future<bool> createSampleNotification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final notification = NotificationModel(
        id: 'sample-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Sample Notification',
        message: 'This is a sample notification to test the system.',
        type: NotificationType.system,
        userId: user.uid,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _saveNotificationToFirestore(notification, user.uid);

      // Add to stream
      _notificationController.add(notification);

      return true;
    } catch (e) {
      DebugLogger.error('Error creating sample notification: $e');
      return false;
    }
  }

  // Save notification to Firestore
  Future<void> _saveNotificationToFirestore(
      NotificationModel notification, String userId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(userId)
          .collection(_userNotificationsSubCollection)
          .add(notification.toMap());
    } catch (e) {
      DebugLogger.error('Error saving notification to Firestore: $e');
    }
  }

  // Dispose resources
  void dispose() {
    _notificationController.close();
  }

  // Add helper method to convert string to NotificationType
  NotificationType _stringToNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'propertylisted':
      case 'newproperty':
        return NotificationType.propertyListed;
      case 'pricechange':
        return NotificationType.priceChange;
      case 'statuschange':
        return NotificationType.statusChange;
      case 'chat':
        return NotificationType.chat;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.other;
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
      // Here you would integrate with flutter_local_notifications
      // For now, we'll just log it
      DebugLogger.info('Local notification: $title - $body');
    } catch (e) {
      DebugLogger.error('Error showing local notification: $e');
    }
  }
}
