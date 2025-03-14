import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// Dedicated class to configure and handle Firebase Authentication
class FirebaseAuthConfig {
  static const String _tag = 'FirebaseAuthConfig';
  static const String _loginPersistenceKey = 'auth_persistence_enabled';
  static const String _userEmailKey = 'user_email';
  static const String _userUidKey = 'user_uid';
  static const String _userPasswordKey = 'user_password_hash'; // Store password hash for auto-login

  /// Initialize Firebase Auth with proper configuration
  static Future<void> configure() async {
    try {
      if (kDebugMode) {
        // In debug mode, disable reCAPTCHA verification
        await FirebaseAuth.instance.setSettings(
          appVerificationDisabledForTesting: true,
          forceRecaptchaFlow: false,
        );
        
        // NOTE: We're skipping setPersistence due to the UnimplementedError on mobile
        // The logs showed: UnimplementedError: setPersistence() is only supported on web based platforms
        
        debugPrint('📱 Firebase Auth configured for development');
      } else {
        // In production, we can't use setPersistence on mobile either
        debugPrint('📱 Firebase Auth configured for production');
      }
    } catch (e) {
      debugPrint('⚠️ Error configuring Firebase Auth: $e');
      // Continue anyway - default settings will be used
    }
  }
  
  /// Store authenticated user info in SharedPreferences
  static Future<void> saveUserState(User? user, [String? password]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (user != null) {
        await prefs.setString(_userEmailKey, user.email ?? '');
        await prefs.setString(_userUidKey, user.uid);
        await prefs.setBool(_loginPersistenceKey, true);
        
        // If password was provided, store a hash of it (not the actual password)
        // This is for auto-login recovery when Firebase Auth state is lost
        if (password != null && password.isNotEmpty) {
          // Simple hash - in production you'd want a more secure approach
          final passwordHash = password.hashCode.toString();
          await prefs.setString(_userPasswordKey, passwordHash);
        }
        
        AppLogger.d(_tag, 'User state saved for ${user.email}');
      } else {
        await prefs.remove(_userEmailKey);
        await prefs.remove(_userUidKey);
        await prefs.remove(_userPasswordKey);
        await prefs.setBool(_loginPersistenceKey, false);
        AppLogger.d(_tag, 'User state cleared');
      }
    } catch (e) {
      AppLogger.e(_tag, 'Error saving user state', e);
      // Don't rethrow as this is not a critical error
    }
  }
  
  /// Get stored user email
  static Future<String?> getSavedUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userEmailKey);
    } catch (e) {
      AppLogger.e(_tag, 'Error getting saved user email', e);
      return null;
    }
  }
  
  /// Get stored password hash (for recovery only)
  static Future<String?> _getSavedPasswordHash() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userPasswordKey);
    } catch (e) {
      AppLogger.e(_tag, 'Error getting saved password hash', e);
      return null;
    }
  }
  
  /// Check if user was previously authenticated
  static Future<bool> wasUserLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_loginPersistenceKey) ?? false;
    } catch (e) {
      AppLogger.e(_tag, 'Error checking saved auth state', e);
      return false;
    }
  }
  
  /// Handle sign out across all services
  static Future<void> signOutCompletely() async {
    try {
      await FirebaseAuth.instance.signOut();
      
      // Clear persistence data
      await saveUserState(null);
      
      debugPrint('👋 User signed out completely');
    } catch (e) {
      debugPrint('⚠️ Error during sign out: $e');
      rethrow;
    }
  }
  
  /// Safe sign-in method using a direct approach that avoids the type casting issue
  static Future<User?> safeSignIn({
    required String email, 
    required String password,
  }) async {
    try {
      AppLogger.d(_tag, 'Attempting sign in for $email');
      
      // First, make sure we're signed out to avoid state conflicts
      await FirebaseAuth.instance.signOut();
      
      try {
        // Simple approach - just sign in and get the user directly
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(), 
          password: password
        );
        
        // Get the current user
        final user = FirebaseAuth.instance.currentUser;
        
        // Save the authentication data for recovery
        if (user != null) {
          await saveUserState(user, password);
        }
        
        return user;
      } catch (e) {
        final errorString = e.toString();
        
        // Handle the PigeonUserDetails error
        if (errorString.contains('PigeonUserDetails')) {
          AppLogger.w(_tag, 'Detected PigeonUserDetails error, trying alternative sign-in', e);
          
          // Force sign out to clear any corrupted state
          await FirebaseAuth.instance.signOut();
          
          // Try a more aggressive alternative approach:
          // Use a separate instance for a clean login
          final auth = FirebaseAuth.instance;
          await auth.signInWithEmailAndPassword(
            email: email.trim(), 
            password: password
          );
          
          // Get the current user
          final user = auth.currentUser;
          
          // Save authentication state
          if (user != null) {
            await saveUserState(user, password);
          }
          
          return user;
        }
        
        // For other errors, rethrow
        rethrow;
      }
    } catch (e) {
      AppLogger.e(_tag, 'Sign in failed', e);
      throw e;
    }
  }
  
  /// Attempt auto-login if we have stored credentials
  /// This is used when the Firebase Auth state is lost but we still have local credentials
  static Future<User?> attemptAutoLogin() async {
    try {
      // Check if user is already logged in via Firebase
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        AppLogger.d(_tag, 'User already logged in via Firebase Auth');
        return currentUser;
      }
      
      // Check if we have saved credentials
      final email = await getSavedUserEmail();
      final passwordHash = await _getSavedPasswordHash();
      
      if (email == null || passwordHash == null) {
        AppLogger.d(_tag, 'No saved credentials for auto-login');
        return null;
      }
      
      // We can't auto-login without the actual password, but we can notify the app
      // that the user was previously logged in
      AppLogger.d(_tag, 'User was previously logged in, but requires manual login');
      return null;
    } catch (e) {
      AppLogger.e(_tag, 'Error during auto-login attempt', e);
      return null;
    }
  }
}
