import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/utils/dev_utils.dart';
import 'notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collection = 'notifications';
  static const String _userNotificationsSubCollection = 'user_notifications';

  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    try {
      return _firestore
          .collection(_collection)
          .doc(userId)
          .collection(_userNotificationsSubCollection)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      DevUtils.log('Error getting user notifications: $e');
      return Stream.value([]);
    }
  }

  Future<void> addNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(notification.userId)
          .collection(_userNotificationsSubCollection)
          .add(notification.toMap());
    } catch (e) {
      DevUtils.log('Error adding notification: $e');
      rethrow;
    }
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(userId)
          .collection(_userNotificationsSubCollection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      DevUtils.log('Error marking notification as read: $e');
      rethrow;
    }
  }

  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(userId)
          .collection(_userNotificationsSubCollection)
          .doc(notificationId)
          .delete();
    } catch (e) {
      DevUtils.log('Error deleting notification: $e');
      rethrow;
    }
  }

  Future<void> deleteAllUserNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection(_collection)
          .doc(userId)
          .collection(_userNotificationsSubCollection)
          .get();

      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      DevUtils.log('Error deleting all user notifications: $e');
      rethrow;
    }
  }

  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .doc(userId)
          .collection(_userNotificationsSubCollection)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      DevUtils.log('Error getting unread count: $e');
      return 0;
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection(_collection)
          .doc(userId)
          .collection(_userNotificationsSubCollection)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      DevUtils.log('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  Future<String> createNotification(NotificationModel notification) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .doc(notification.userId)
          .collection(_userNotificationsSubCollection)
          .add(notification.toMap());

      return docRef.id;
    } catch (e) {
      DevUtils.log('Error creating notification: $e');
      rethrow;
    }
  }
}
