import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/logger.dart';
import 'models/user_model.dart';

class AuthRepository {
  static const String _tag = 'AuthRepository';
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserModel> signInWithEmailAndPassword(String email, String password) async {
    try {
      AppLogger.d(_tag, 'Signing in with email: $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) throw Exception('No user found');
      
      final userData = await _getUserData(credential.user!.uid);
      return UserModel.fromFirebase(credential.user!, userData);
    } catch (e) {
      AppLogger.e(_tag, 'Sign in failed', e);
      throw _handleAuthError(e);
    }
  }

  // Sign up with email and password
  Future<UserModel> signUpWithEmailAndPassword(String email, String password) async {
    try {
      AppLogger.d(_tag, 'Creating account for email: $email');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) throw Exception('Failed to create user');
      
      // Create user document
      await _createUserDocument(credential.user!);
      
      final userData = await _getUserData(credential.user!.uid);
      return UserModel.fromFirebase(credential.user!, userData);
    } catch (e) {
      AppLogger.e(_tag, 'Sign up failed', e);
      throw _handleAuthError(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      AppLogger.i(_tag, 'User signed out');
    } catch (e) {
      AppLogger.e(_tag, 'Sign out failed', e);
      throw _handleAuthError(e);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      AppLogger.i(_tag, 'Password reset email sent to $email');
    } catch (e) {
      AppLogger.e(_tag, 'Password reset failed', e);
      throw _handleAuthError(e);
    }
  }

  // Helper methods
  Future<Map<String, dynamic>?> _getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> _createUserDocument(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
      'role': 'user',
      'displayName': user.displayName,
      'photoURL': user.photoURL,
    });
  }

  String _handleAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'Email is already registered.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'weak-password':
          return 'The password provided is too weak.';
        default:
          return e.message ?? 'An unknown error occurred.';
      }
    }
    return 'An unexpected error occurred.';
  }
}
