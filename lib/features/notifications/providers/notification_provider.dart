import 'package:flutter/foundation.dart';
import '../data/notification_model.dart';
import '../domain/services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _service = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _loading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadNotifications(String userId) async {
    try {
      _loading = true;
      notifyListeners();

      _notifications = await _service.getUserNotifications(userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
