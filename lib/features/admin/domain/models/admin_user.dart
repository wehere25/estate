import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Model class for user data in admin dashboard
class AdminUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final bool isAdmin;
  final String status; // Add status field
  final Timestamp? lastActive;
  final Timestamp? createdAt;

  const AdminUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.isAdmin,
    this.status = 'active', // Default status
    this.lastActive,
    this.createdAt,
  });

  // Add joinDate getter
  String get joinDate {
    if (createdAt == null) return 'Unknown';
    try {
      final date = createdAt!.toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  // Add toCsvRow method
  List<String> toCsvRow() {
    return [
      uid,
      email,
      displayName,
      isAdmin ? 'Admin' : 'User',
      status,
      joinDate,
      lastActive != null ? lastActive!.toDate().toString() : 'Never'
    ];
  }

  // Add fromFirestore factory constructor
  factory AdminUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AdminUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      isAdmin: data['role'] == 'admin',
      status: data['status'] ?? 'active',
      lastActive: data['lastActive'] as Timestamp?,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'isAdmin': isAdmin,
      'status': status,
      'lastActive': lastActive,
      'createdAt': createdAt,
    };
  }

  factory AdminUser.fromMap(Map<String, dynamic> map) {
    return AdminUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoURL: map['photoURL'],
      isAdmin: map['isAdmin'] ?? false,
      status: map['status'] ?? 'active',
      lastActive: map['lastActive'],
      createdAt: map['createdAt'],
    );
  }

  AdminUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    bool? isAdmin,
    String? status, // Add status to copyWith
    Timestamp? lastActive,
    Timestamp? createdAt,
  }) {
    return AdminUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      isAdmin: isAdmin ?? this.isAdmin,
      status: status ?? this.status, // Use the new status
      lastActive: lastActive ?? this.lastActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}