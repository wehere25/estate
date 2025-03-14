import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AuditLog {
  final String id;
  final String userId;
  final String action;
  final DateTime timestamp;
  final String ipAddress;
  final Map<String, dynamic> deviceInfo;

  AuditLog({
    this.id = '',
    required this.userId,
    required this.action,
    required this.timestamp,
    required this.ipAddress,
    required this.deviceInfo,
  });
  
  // Factory constructor to create from Firestore data
  factory AuditLog.fromMap(Map<String, dynamic> map, String docId) {
    return AuditLog(
      id: docId,
      userId: map['userId'] ?? '',
      action: map['action'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      ipAddress: map['ipAddress'] ?? '',
      deviceInfo: Map<String, dynamic>.from(map['deviceInfo'] ?? {}),
    );
  }
  
  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'action': action,
      'timestamp': Timestamp.fromDate(timestamp),
      'ipAddress': ipAddress,
      'deviceInfo': deviceInfo,
    };
  }
  
  // For displaying formatted timestamp
  String get formattedTimestamp {
    return DateFormat('MMM d, yyyy HH:mm').format(timestamp);
  }
  
  // For displaying readable action name
  String get readableAction {
    switch (action) {
      case 'login':
        return 'User Login';
      case '2fa_verification':
        return '2FA Verification';
      case 'property_create':
        return 'Property Created';
      case 'property_update':
        return 'Property Updated';
      case 'property_delete':
        return 'Property Deleted';
      case 'user_update':
        return 'User Profile Updated';
      case 'admin_login':
        return 'Admin Login';
      default:
        return action.replaceAll('_', ' ').capitalize();
    }
  }

  // Convert AuditLog list to Map list
  static List<Map<String, dynamic>> listToMapList(List<AuditLog> logs) {
    return logs.map((log) => log.toMap()).toList();
  }

  // Convert this instance to a Map with id included
  Map<String, dynamic> toMapWithId() {
    final map = toMap();
    map['id'] = id;
    // Ensure timestamp is in the format expected by AuditLogList widget
    if (map['timestamp'] is DateTime) {
      map['timestamp'] = Timestamp.fromDate(map['timestamp'] as DateTime);
    }
    return map;
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
