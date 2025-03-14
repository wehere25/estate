import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_role.dart';

/// Domain model for authenticated user
class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final UserRole role;
  final bool emailVerified;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final Map<String, dynamic>? preferences;
  final String? phoneNumber;

  /// Constructor
  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    this.role = UserRole.user,
    this.emailVerified = false,
    this.createdAt,
    this.lastLogin,
    this.preferences,
    this.phoneNumber,
  });

  /// Create a copy with some fields replaced
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    UserRole? role,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? lastLogin,
    Map<String, dynamic>? preferences,
    String? phoneNumber,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      role: role ?? this.role,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      preferences: preferences ?? this.preferences,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role.toString().split('.').last,
      'emailVerified': emailVerified,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'preferences': preferences,
      'phoneNumber': phoneNumber,
    };
  }

  /// Create model from map (Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      role: _parseUserRole(map['role']),
      emailVerified: map['emailVerified'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      lastLogin: (map['lastLogin'] as Timestamp?)?.toDate(),
      preferences: map['preferences'] as Map<String, dynamic>?,
      phoneNumber: map['phoneNumber'],
    );
  }

  static UserRole _parseUserRole(String? role) {
    if (role == null) return UserRole.user;
    
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'agent':
        return UserRole.agent;
      default:
        return UserRole.user;
    }
  }
  
  /// Check if user is admin
  bool get isAdmin => role == UserRole.admin;
  
  /// Check if user is agent
  bool get isAgent => role == UserRole.agent;
}
