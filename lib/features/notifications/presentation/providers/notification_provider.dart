import 'package:flutter/foundation.dart';
import '../../domain/services/notification_service.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/models/notification_type.dart';
import '../../../property/domain/models/property_model.dart';
import '../../../../core/utils/dev_utils.dart';
import '../../../../core/utils/formatters.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _service;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;

  // Keep track of recently sent notification IDs to prevent duplicates
  final Set<String> _recentlySentNotificationIds = {};

  // Local memory cache of deleted notification IDs to prevent reappearing after refresh
  final Set<String> _deletedNotificationIds = {};

  NotificationProvider(this._service);

  List<NotificationModel> get notifications => _notifications
      .where((n) => !_deletedNotificationIds.contains(n.id))
      .toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void initialize(String userId) {
    _currentUserId = userId;
    DevUtils.log('🔑 NotificationProvider initializing for user: $userId');
    _service.initialize();
    _listenToNotifications(userId);
    refreshNotifications();
  }

  void _listenToNotifications(String userId) {
    // Listen to the service's notification stream for real-time updates
    _service.notificationStream.listen(
      (notification) {
        // Add newly received notification to the list if it's not already there
        if (!_notifications.any((n) => n.id == notification.id)) {
          _notifications = [notification, ..._notifications];
          notifyListeners();
        }
      },
      onError: (error) {
        DevUtils.log('Error listening to notifications: $error');
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  void _markAsDeleted(String notificationId) {
    _deletedNotificationIds.add(notificationId);
  }

  void _markAllAsDeleted() {
    for (final notification in _notifications) {
      _deletedNotificationIds.add(notification.id);
    }
  }

  // Generate a unique notification ID based on property and type
  String _generateNotificationId(
      PropertyModel property, NotificationType type) {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/
        1000; // In seconds for deduplication window
    return '${property.id}_${type.toString()}_$timestamp';
  }

  // Check if a notification was recently sent (within 30 seconds)
  bool _wasRecentlySent(String notificationId) {
    if (_recentlySentNotificationIds.contains(notificationId)) {
      DevUtils.log('🔄 Skipping duplicate notification: $notificationId');
      return true;
    }

    // Add to recent notifications and schedule cleanup
    _recentlySentNotificationIds.add(notificationId);
    Future.delayed(const Duration(minutes: 1), () {
      _recentlySentNotificationIds.remove(notificationId);
    });

    return false;
  }

  Future<void> createPropertyNotification({
    required PropertyModel property,
    required NotificationType type,
    bool sendToAllUsers = false,
  }) async {
    try {
      // Add debugging information
      DevUtils.log('🔔 Creating property notification:');
      DevUtils.log('📬 Property ID: ${property.id}');
      DevUtils.log('📬 Title: ${property.title}');
      DevUtils.log('📬 Type: $type');
      DevUtils.log('📬 Send to all users: $sendToAllUsers');

      // Generate a notification ID
      final notificationId = _generateNotificationId(property, type);

      // Skip if this notification was recently sent (prevents duplicates)
      if (_wasRecentlySent(notificationId)) {
        DevUtils.log('⚠️ Duplicate notification detected and skipped');
        return;
      }

      String title;
      String message;

      // Prepare notification content based on type
      if (type == NotificationType.propertyListed) {
        title = 'New Property Listed';
        message =
            '${property.title} has been listed for ${Formatters.formatPrice(property.price)}';

        if (sendToAllUsers) {
          // For new properties, send to all users
          DevUtils.log(
              '📬 Sending notification to ALL USERS for property: ${property.title}');

          await _service.sendNotificationToAllUsers(
            title: title,
            message: message,
            type: type,
            actionUrl: '/property/${property.id}',
            metadata: {
              'propertyId': property.id,
              'propertyTitle': property.title,
              'propertyPrice': property.price,
              'propertyImage': property.images?.isNotEmpty == true
                  ? property.images!.first
                  : null,
            },
          );

          DevUtils.log('📬 Successfully sent notification to all users');

          // Show local notification as well
          await _service.showLocalNotification(
            id: property.id.hashCode,
            title: title,
            body: message,
            payload: '/property/${property.id}',
          );

          return; // Return early to avoid additional notifications
        }
      } else if (type == NotificationType.priceChange) {
        title = 'Price Updated';
        message =
            'Price for ${property.title} has been updated to ${Formatters.formatPrice(property.price)}';
      } else if (type == NotificationType.statusChange) {
        title = 'Status Changed';
        message =
            '${property.title} status has been updated to ${property.status}';
      } else {
        title = 'Property Update';
        message = 'There has been an update to ${property.title}';
      }

      // For non-global notifications, send only to property owner
      if (property.ownerId != null) {
        await _service.sendNotificationToUser(
          userId: property.ownerId!,
          title: title,
          message: message,
          type: type,
          actionUrl: '/property/${property.id}',
          metadata: {
            'propertyId': property.id,
            'propertyTitle': property.title,
            'propertyPrice': property.price,
            'propertyImage': property.images?.isNotEmpty == true
                ? property.images!.first
                : null,
          },
        );

        // Show local notification as well
        await _service.showLocalNotification(
          id: property.id.hashCode,
          title: title,
          body: message,
          payload: '/property/${property.id}',
        );
      } else {
        DevUtils.log(
            '⚠️ Cannot send notification: Property owner ID is missing');
      }
    } catch (e) {
      DevUtils.log('❌ Error creating property notification: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _service.markNotificationAsRead(notificationId);
      _notifications = _notifications.map((notification) {
        if (notification.id == notificationId) {
          return notification.copyWith(isRead: true);
        }
        return notification;
      }).toList();
      notifyListeners();
    } catch (e) {
      DevUtils.log('Error marking notification as read: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _service.markAllNotificationsAsRead();
      _notifications = _notifications.map((notification) {
        return notification.copyWith(isRead: true);
      }).toList();
      notifyListeners();
    } catch (e) {
      DevUtils.log('Error marking all notifications as read: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      DevUtils.log('🗑️ Attempting to delete notification: $notificationId');

      // Mark as deleted and update local state first
      _markAsDeleted(notificationId);
      notifyListeners();

      // Then attempt to delete from the backend
      final success = await _service.deleteNotification(notificationId);

      if (success) {
        DevUtils.log('✅ Successfully deleted notification: $notificationId');
      } else {
        DevUtils.log(
            '⚠️ Backend reported failure to delete notification: $notificationId, but UI is updated');
      }
    } catch (e) {
      DevUtils.log('❌ Error deleting notification: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteAllNotifications(String userId) async {
    try {
      DevUtils.log('🧹 Deleting all notifications for user: $userId');

      // Mark all current notifications as deleted
      _markAllAsDeleted();

      // Clear local notifications list and update UI
      _notifications = [];
      notifyListeners();

      // Then perform the actual deletion in the service
      final success = await _service.deleteAllNotifications();

      if (success) {
        DevUtils.log('✅ Successfully deleted all notifications');
      } else {
        DevUtils.log(
            '⚠️ Backend reported failure to delete all notifications, but UI is updated');
      }
    } catch (e) {
      DevUtils.log('❌ Error deleting all notifications: $e');
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  // Refresh notifications from both paths
  Future<void> refreshNotifications() async {
    if (_currentUserId == null) {
      DevUtils.log('❌ Cannot refresh notifications: No user ID set');
      return;
    }

    try {
      DevUtils.log('🔄 Refreshing notifications for user: $_currentUserId');
      _isLoading = true;
      notifyListeners();

      final updatedNotifications =
          await _service.getUserNotifications(_currentUserId!);
      DevUtils.log('📬 Retrieved ${updatedNotifications.length} notifications');

      // Filter out notifications that should be deleted
      final filteredNotifications = updatedNotifications
          .where((n) => !_deletedNotificationIds.contains(n.id))
          .toList();

      if (filteredNotifications.length < updatedNotifications.length) {
        DevUtils.log(
            '🧹 Filtered out ${updatedNotifications.length - filteredNotifications.length} deleted notifications');
      }

      _notifications = filteredNotifications;
      _error = null;
    } catch (e) {
      DevUtils.log('❌ Error refreshing notifications: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
