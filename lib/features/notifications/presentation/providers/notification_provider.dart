import 'package:flutter/foundation.dart';
import '../../data/notification_repository.dart';
import '../../domain/services/notification_service.dart';
import '../../data/notification_model.dart'; // Updated import path
import '../../../property/domain/models/property_model.dart';
import '../../../../core/utils/dev_utils.dart';
import '../../../../core/utils/formatters.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationRepository _repository;
  final NotificationService _service;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  NotificationProvider(this._repository, this._service);

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void initialize(String userId) {
    _service.initialize();
    _listenToNotifications(userId);
  }

  void _listenToNotifications(String userId) {
    _repository.getUserNotifications(userId).listen(
      (notifications) {
        _notifications = notifications;
        notifyListeners();
      },
      onError: (error) {
        DevUtils.log('Error listening to notifications: $error');
        _error = error.toString();
        notifyListeners();
      },
    );
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

      String title;
      String message;

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
        }
      } else {
        // For other notifications (price change, status change), send only to property owner
        if (property.ownerId == null) {
          throw Exception('Property owner ID is required');
        }

        if (type == NotificationType.priceChange) {
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
      }

      // Show local notification as well
      await _service.showLocalNotification(
        id: property.id.hashCode,
        title: title,
        body: message,
        payload: '/property/${property.id}',
      );
    } catch (e) {
      DevUtils.log('Error creating property notification: $e');
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
      await _service.deleteNotification(notificationId);
      _notifications =
          _notifications.where((n) => n.id != notificationId).toList();
      notifyListeners();
    } catch (e) {
      DevUtils.log('Error deleting notification: $e');
      _error = e.toString();
      notifyListeners();
    }
  }
}
