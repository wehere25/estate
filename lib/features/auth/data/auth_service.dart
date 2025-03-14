import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/exceptions/auth_exception.dart';
import '../../../core/utils/logger.dart';

class AuthService {
  static const String _tag = 'AuthService';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is admin - synchronous with asynchronous validation
  Future<bool> isAdmin() async {
    final user = currentUser;
    if (user == null) return false;

    try {
      // Check custom claims first
      final idTokenResult = await user.getIdTokenResult(true);
      if (idTokenResult.claims?['admin'] == true) {
        return true;
      }

      // Check admin collection
      final adminDoc =
          await _firestore.collection('admins').doc(user.uid).get();
      if (adminDoc.exists) {
        return true;
      }

      // Check user document role as final fallback
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      return userDoc.data()?['role']?.toString().toLowerCase() == 'admin';
    } catch (e) {
      AppLogger.e(_tag, 'Error checking admin status', e);
      return false;
    }
  }

  // Sign in with email and password - fixed implementation
  Future<User?> signIn(String email, String password) async {
    try {
      AppLogger.d(_tag, 'Attempting sign in');

      // Direct Firebase Auth usage instead of the undefined method
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return userCredential.user;
    } catch (e) {
      AppLogger.e(_tag, 'Error during sign in', e);

      String message = 'Authentication failed';

      // Providing user-friendly error messages
      if (e.toString().contains('user-not-found') ||
          e.toString().contains('wrong-password') ||
          e.toString().contains('invalid-credential')) {
        message = 'Invalid email or password';
      } else if (e.toString().contains('too-many-requests')) {
        message = 'Too many failed login attempts. Please try again later';
      } else if (e.toString().contains('network-request-failed')) {
        message = 'Network error. Please check your connection';
      }

      throw AuthException(message);
    }
  }

  // Remove the unused _updateUserData method or keep it with a note
  // Future<void> _updateUserData(String uid, Map<String, dynamic> data) async {
  //   // Method removed since it's not being used
  // }

  // Create new user account
  Future<User?> signUp(String email, String password) async {
    try {
      AppLogger.d(_tag, 'Attempting sign up');

      // First sign out to clear any existing state
      await _auth.signOut();

      // Create the user account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;

      if (user != null) {
        // Create the user document
        await _createUserDocument(user.uid, email);

        AppLogger.d(_tag, 'Sign up successful');
        return user;
      } else {
        throw AuthException('Failed to create account');
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.e(_tag, 'Sign up failed', e);
      throw AuthException.fromCode(e.code);
    } catch (e) {
      AppLogger.e(_tag, 'Sign up failed with generic error', e);
      throw AuthException('Registration failed: $e');
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(String uid, String email) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'user', // Default role
        'isActive': true,
      });

      AppLogger.d(_tag, 'User document created');
    } catch (e) {
      // Just log the error without throwing
      AppLogger.e(_tag, 'Failed to create user document', e);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      AppLogger.d(_tag, 'Password reset email sent');
    } on FirebaseAuthException catch (e) {
      AppLogger.e(_tag, 'Password reset failed', e);
      throw AuthException.fromCode(e.code);
    } catch (e) {
      AppLogger.e(_tag, 'Password reset failed with generic error', e);
      throw AuthException('Password reset failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Just use the standard Firebase sign out
      await _auth.signOut();
      AppLogger.d(_tag, 'Sign out successful');
    } catch (e) {
      AppLogger.e(_tag, 'Sign out failed', e);
      throw AuthException('Sign out failed: $e');
    }
  }

  // Check and refresh authentication state
  Future<User?> refreshAuthState() async {
    try {
      // Get current user
      final user = _auth.currentUser;

      if (user != null) {
        // User is authenticated - refresh token
        await user.reload();
        AppLogger.d(_tag, 'Auth state refreshed for ${user.email}');
        return _auth.currentUser;
      }

      return null;
    } catch (e) {
      AppLogger.e(_tag, 'Error refreshing auth state', e);
      return null;
    }
  }
}
