import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String role;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.role = 'user',
  });

  factory UserModel.fromFirebase(firebase_auth.User user, Map<String, dynamic>? userData) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? userData?['displayName'],
      photoUrl: user.photoURL ?? userData?['photoURL'],
      role: userData?['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role,
    };
  }
}
