import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../utils/debug_logger.dart';
import '../../features/notifications/domain/services/notification_service.dart'
    as domain;

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final domain.NotificationService _domainService =
      domain.NotificationService();

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Get FCM token for this device
    String? token = await _messaging.getToken();
    debugPrint('FCM Token: $token');

    // Initialize domain service
    await _domainService.initialize();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.notification?.title}');
      // The domain service will handle showing local notifications
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle when app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
          'App opened from notification: ${message.notification?.title}');
      // The domain service will handle navigation
    });
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}

// This needs to be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.notification?.title}');
}
