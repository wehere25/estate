import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/utils/debug_logger.dart';

/// Service class that directly interacts with Firebase Authentication
/// 
/// This class handles all direct Firebase Auth API calls.
/// It should be used by the AuthRepository, not directly by providers.
class AuthService {
  final FirebaseAuth _firebaseAuth;
  
  /// Constructor with optional Firebase Auth instance for testing
  AuthService({FirebaseAuth? firebaseAuth}) 
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;
  
  /// Get the currently signed-in user
  User? get currentUser => _firebaseAuth.currentUser;
  
  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  
  /// Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      DebugLogger.auth('AuthService: Signing in with email');
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      DebugLogger.error('AuthService: Email sign-in failed', e);
      rethrow;
    }
  }
  
  /// Register with email and password
  Future<UserCredential> createUserWithEmail(String email, String password) async {
    try {
      DebugLogger.auth('AuthService: Creating user with email');
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      DebugLogger.error('AuthService: User creation failed', e);
      rethrow;
    }
  }
  
  /// Sign out the current user
  Future<void> signOut() async {
    try {
      DebugLogger.auth('AuthService: Signing out user');
      await _firebaseAuth.signOut();
    } catch (e) {
      DebugLogger.error('AuthService: Sign-out failed', e);
      rethrow;
    }
  }
  
  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      DebugLogger.auth('AuthService: Sending password reset email');
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      DebugLogger.error('AuthService: Password reset email failed', e);
      rethrow;
    }
  }
  
  /// Update user profile information
  Future<void> updateUserProfile(User user, {String? displayName, String? photoURL}) async {
    try {
      DebugLogger.auth('AuthService: Updating user profile');
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoURL);
    } catch (e) {
      DebugLogger.error('AuthService: Profile update failed', e);
      rethrow;
    }
  }
  
  /// Check if email is already in use
  Future<bool> isEmailInUse(String email) async {
    try {
      DebugLogger.auth('AuthService: Checking if email is in use');
      final methods = await _firebaseAuth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      DebugLogger.error('AuthService: Email check failed', e);
      rethrow;
    }
  }
  
  /// Reauthenticate current user (for security-sensitive operations)
  Future<UserCredential> reauthenticateUser(User user, String password) async {
    try {
      DebugLogger.auth('AuthService: Reauthenticating user');
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      return await user.reauthenticateWithCredential(credential);
    } catch (e) {
      DebugLogger.error('AuthService: Reauthentication failed', e);
      rethrow;
    }
  }
  
  /// Update user password
  Future<void> updatePassword(User user, String newPassword) async {
    try {
      DebugLogger.auth('AuthService: Updating password');
      await user.updatePassword(newPassword);
    } catch (e) {
      DebugLogger.error('AuthService: Password update failed', e);
      rethrow;
    }
  }
}
