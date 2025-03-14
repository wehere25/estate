import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/debug_logger.dart';

/// Service class for Firebase Authentication operations
class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  static const String _persistenceKey = 'auth_persistence_enabled';
  static const String _authUserKey = 'auth_user_cached';

  /// Constructor with optional FirebaseAuth instance for testing
  AuthService({firebase_auth.FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance {
    // Listen for auth state changes to ensure persistence is working
    _firebaseAuth.authStateChanges().listen((user) {
      if (user != null) {
        _cacheAuthStatus(true);
        DebugLogger.info('Auth state changed: User is authenticated');
      } else {
        _cacheAuthStatus(false);
        DebugLogger.info('Auth state changed: User is signed out');
      }
    });
  }

  /// Cache the authentication status
  Future<void> _cacheAuthStatus(bool isAuthenticated) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_authUserKey, isAuthenticated);
      DebugLogger.info('Authentication status cached: $isAuthenticated');
    } catch (e) {
      DebugLogger.error('Failed to cache auth status', e);
    }
  }

  /// Get the current authenticated user
  firebase_auth.User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  /// Check if user was previously authenticated
  Future<bool> wasPreviouslyAuthenticated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_authUserKey) ?? false;
    } catch (e) {
      DebugLogger.error('Failed to get cached auth status', e);
      return false;
    }
  }

  /// Sign in with email and password
  Future<firebase_auth.User?> signInWithEmailAndPassword(
      String email, String password,
      {bool rememberMe = false}) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Store the remember me preference
    if (rememberMe) {
      await _saveRememberMePreference(true);
      // Explicitly cache auth status
      await _cacheAuthStatus(true);
    }

    return credential.user;
  }

  /// Save remember me preference to SharedPreferences
  Future<void> _saveRememberMePreference(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_persistenceKey, enabled);
      DebugLogger.info('Remember me preference saved: $enabled');
    } catch (e) {
      DebugLogger.error('Failed to save remember me preference', e);
    }
  }

  /// Get the saved remember me preference
  Future<bool> getSavedRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_persistenceKey) ?? false;
    } catch (e) {
      DebugLogger.error('Failed to get remember me preference', e);
      return false;
    }
  }

  /// Create new user with email and password
  Future<firebase_auth.User?> createUserWithEmailAndPassword(
      String email, String password) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential.user;
  }

  /// Update user profile
  Future<void> updateUserProfile(
      {String? displayName, String? photoURL}) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  /// Sign out
  Future<void> signOut() async {
    // Clear the remember me preference when signing out
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_persistenceKey, false);
      await prefs.setBool(_authUserKey, false);
    } catch (e) {
      DebugLogger.error('Failed to clear auth preferences', e);
    }

    await _firebaseAuth.signOut();
  }
}
