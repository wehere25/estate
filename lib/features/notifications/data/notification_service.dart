import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../domain/models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static const notificationsCollection = 'notifications';
  static const userNotificationsCollection = 'user_notifications';
  static const globalNotificationsCollection = 'global_notifications';

  // Initialize messaging and request permissions
  Future<void> initialize() async {
    try {
      // Request permission for notifications
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Subscribe to new properties topic
        await _messaging.subscribeToTopic('new_properties');
      }
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  // Send notification to all users when new property is added
  Future<void> sendNewPropertyNotification(
      String title, String description, String propertyId) async {
    try {
      // Create the notification data
      final notificationData = {
        'title': 'New Property Listed: $title',
        'message': description,
        'type': 'newProperty',
        'propertyId': propertyId,
        'timestamp': FieldValue.serverTimestamp(),
        'isGlobal': true,
        'read': false,
      };

      // First, add to global notifications
      final globalNotifRef = await _firestore
          .collection(globalNotificationsCollection)
          .add(notificationData);

      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();

      // Create batches for efficient writes (Firestore has a 500 operation limit per batch)
      var batch = _firestore.batch();
      var operationCount = 0;

      // Add notification to each user's collection
      for (var userDoc in usersSnapshot.docs) {
        final userNotifRef = _firestore
            .collection(userNotificationsCollection)
            .doc(userDoc.id)
            .collection('notifications')
            .doc(globalNotifRef.id);

        batch.set(userNotifRef, {
          ...notificationData,
          'userId': userDoc.id,
        });

        operationCount++;

        // Commit batch when reaching close to limit
        if (operationCount >= 400) {
          await batch.commit();
          batch = _firestore.batch();
          operationCount = 0;
        }
      }

      // Commit any remaining operations
      if (operationCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      print('Error sending global notification: $e');
      rethrow;
    }
  }

  // Fetch notifications for a user
  Future<List<NotificationModel>> getUserNotifications(
      {bool unreadOnly = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      Query query = _firestore
          .collection(userNotificationsCollection)
          .doc(user.uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true);

      if (unreadOnly) {
        query = query.where('read', isEqualTo: false);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final snapshot = await _firestore
          .collection(userNotificationsCollection)
          .doc(user.uid)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection(userNotificationsCollection)
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      rethrow;
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection(userNotificationsCollection)
          .doc(user.uid)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection(userNotificationsCollection)
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection(userNotificationsCollection)
          .doc(user.uid)
          .collection('notifications')
          .get();

      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }
}
