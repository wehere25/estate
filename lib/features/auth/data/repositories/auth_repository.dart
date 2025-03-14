import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/utils/debug_logger.dart';
import '../services/auth_service.dart';

/// Repository that handles Firebase authentication operations
class AuthRepository {
  final AuthService _authService;
  
  /// Constructor with optional AuthService for testing
  AuthRepository({AuthService? authService}) 
      : _authService = authService ?? AuthService();
  
  /// Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _authService.signInWithEmail(email, password);
      return credential.user;
    } catch (e) {
      DebugLogger.error('Repository: signInWithEmailAndPassword failed', e);
      rethrow;
    }
  }
  
  /// Create a new user account
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      return await _authService.createUserWithEmail(email, password);
    } catch (e) {
      DebugLogger.error('Repository: createUserWithEmailAndPassword failed', e);
      rethrow;
    }
  }
  
  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      DebugLogger.error('Repository: sendPasswordResetEmail failed', e);
      rethrow;
    }
  }
  
  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      DebugLogger.error('Repository: signOut failed', e);
      rethrow;
    }
  }
  
  /// Get the current user
  User? getCurrentUser() {
    try {
      return _authService.currentUser;
    } catch (e) {
      DebugLogger.error('Repository: getCurrentUser failed', e);
      return null;
    }
  }
  
  /// Check if email is already in use
  Future<bool> isEmailInUse(String email) async {
    try {
      return await _authService.isEmailInUse(email);
    } catch (e) {
      DebugLogger.error('Repository: isEmailInUse failed', e);
      // Default to true to prevent account creation if check fails
      return true;
    }
  }
  
  /// Update user profile
  Future<void> updateUserProfile(User user, {String? displayName, String? photoURL}) async {
    try {
      await _authService.updateUserProfile(
        user,
        displayName: displayName,
        photoURL: photoURL,
      );
    } catch (e) {
      DebugLogger.error('Repository: updateUserProfile failed', e);
      rethrow;
    }
  }
}
