import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  propertyListed,
  priceChange,
  statusChange,
  chat,
  system,
  other
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final String userId;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;
  final String? actionUrl;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.userId,
    required this.createdAt,
    this.isRead = false,
    this.readAt,
    this.actionUrl,
    this.metadata,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: _stringToNotificationType(data['type'] ?? ''),
      userId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      readAt: data['readAt'] != null
          ? (data['readAt'] as Timestamp).toDate()
          : null,
      actionUrl: data['actionUrl'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'actionUrl': actionUrl,
      'metadata': metadata,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    String? userId,
    DateTime? createdAt,
    bool? isRead,
    DateTime? readAt,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      actionUrl: actionUrl ?? this.actionUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  static NotificationType _stringToNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'propertylisted':
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

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, message: $message, type: $type, isRead: $isRead)';
  }
}
