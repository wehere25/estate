import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/utils/debug_logger.dart';

/// A simplified authentication helper that focuses on reliable authentication
class AuthHelper {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Sign in with email and password
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      DebugLogger.error('Email sign in error', e);
      rethrow;
    }
  }
  
  /// Sign in anonymously when Google sign-in fails
  Future<UserCredential> signInAnonymously() async {
    try {
      DebugLogger.info('Signing in anonymously as fallback');
      return await _auth.signInAnonymously();
    } catch (e) {
      DebugLogger.error('Anonymous sign in error', e);
      rethrow;
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  /// Get current user
  User? get currentUser => _auth.currentUser;
}
