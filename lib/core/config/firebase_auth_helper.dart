import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// Helper class to manage Firebase Auth initialization and persistence
class FirebaseAuthHelper {
  static const String _tag = 'FirebaseAuthHelper';
  static const String _userEmailKey = 'user_email';
  static const String _isAuthenticatedKey = 'is_authenticated';
  
  /// Initialize Firebase Auth with appropriate persistence
  static Future<void> initialize() async {
    try {
      // Configure Firebase Auth to use the appropriate persistence
      if (kDebugMode) {
        // In debug mode, use no persistence to avoid any issues with auth state
        await FirebaseAuth.instance.setPersistence(Persistence.NONE);
        await FirebaseAuth.instance.setSettings(
          appVerificationDisabledForTesting: true,
          forceRecaptchaFlow: false,
        );
        debugPrint('⚠️ Firebase Auth in non-persistent debug mode');
      } else {
        // In production, use the default persistence (SESSION)
        await FirebaseAuth.instance.setPersistence(Persistence.SESSION);
      }
    } catch (e) {
      AppLogger.e(_tag, 'Error configuring Firebase Auth persistence', e);
    }
  }
  
  /// Store authenticated user info in SharedPreferences as backup
  static Future<void> saveUserState(User? user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (user != null) {
        await prefs.setString(_userEmailKey, user.email ?? '');
        await prefs.setBool(_isAuthenticatedKey, true);
      } else {
        await prefs.remove(_userEmailKey);
        await prefs.setBool(_isAuthenticatedKey, false);
      }
    } catch (e) {
      AppLogger.e(_tag, 'Error saving user state', e);
    }
  }
  
  /// Get stored authentication state
  static Future<bool> getSavedAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isAuthenticatedKey) ?? false;
    } catch (e) {
      AppLogger.e(_tag, 'Error getting saved auth state', e);
      return false;
    }
  }
  
  /// Wrapper for safe sign in to handle type errors
  static Future<User?> safeSignIn(String email, String password) async {
    try {
      // Sign in with email and password
      AppLogger.d(_tag, 'Safe sign in attempt for $email');
      
      try {
        // Try to sign in with normal method first
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(), 
          password: password
        );
        
        // Save user state and return user
        final user = userCredential.user;
        await saveUserState(user);
        return user;
      } catch (e) {
        // If the normal method fails with a type error, try a recovery approach
        if (e.toString().contains('PigeonUserDetails')) {
          AppLogger.w(_tag, 'Type cast error detected, trying recovery approach', e);
          
          // Force sign out first to clear any corrupted state
          await FirebaseAuth.instance.signOut();
          
          // Try again with a clean state
          final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email.trim(), 
            password: password
          );
          
          // Save user state and return user
          final user = userCredential.user;
          await saveUserState(user);
          return user;
        } else {
          // For other errors, just rethrow
          rethrow;
        }
      }
    } catch (e) {
      AppLogger.e(_tag, 'Safe sign in failed', e);
      // Clear any partial authentication state
      await saveUserState(null);
      rethrow;
    }
  }
  
  /// Complete sign out including clearing all caches
  static Future<void> completeSignOut() async {
    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      
      // Clear saved state
      await saveUserState(null);
      
      AppLogger.d(_tag, 'Complete sign out successful');
    } catch (e) {
      AppLogger.e(_tag, 'Error during complete sign out', e);
      rethrow;
    }
  }
}
