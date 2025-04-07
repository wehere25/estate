import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'debug_logger.dart';
import '../../features/notifications/domain/models/notification_model.dart';
import '../../features/notifications/domain/models/notification_type.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = true;
      DebugLogger.info('Local notifications initialized successfully');
    } catch (e) {
      DebugLogger.error('Error initializing local notifications: $e');
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap here
    DebugLogger.info('Notification tapped: ${response.payload}');
    // Navigation would happen here, but that should be handled by the app's routing system
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationType type = NotificationType.system,
  }) async {
    if (!_initialized) await initialize();

    try {
      const androidDetails = AndroidNotificationDetails(
        'default_channel',
        'Default Channel',
        channelDescription: 'Default notifications channel',
        importance: Importance.max,
        priority: Priority.high,
        enableLights: true,
        enableVibration: true,
      );

      const iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await _notifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      DebugLogger.info('Notification displayed: $title');
    } catch (e) {
      DebugLogger.error('Error showing notification: $e');
    }
  }
}
