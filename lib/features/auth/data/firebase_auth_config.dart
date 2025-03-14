
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/logger.dart';

/// Class to handle Firebase Auth configuration and handle known issues
class FirebaseAuthConfig {
  static const String _tag = 'FirebaseAuthConfig';
  
  /// Fix for the PigeonUserDetails casting error
  static Future<User?> signInSafely(String email, String password) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    
    try {
      AppLogger.d(_tag, 'Attempting sign in for $email');
      
      // First try regular sign-in
      final UserCredential userCred = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return userCred.user;
    } catch (e) {
      if (e.toString().contains('PigeonUserDetails') || 
          e.toString().contains('type \'List<Object?>\'')) {
        AppLogger.w(_tag, 'Detected PigeonUserDetails error, trying alternative sign-in');
        
        // Alternative approach using try-catch for each step
        try {
          // Force sign out first
          await auth.signOut();
          
          // Try sign in again with error handling
          final credential = await auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          
          // Retrieve user directly
          final user = auth.currentUser;
          
          // Manual verification
          if (user != null && user.email == email) {
            return user;
          } else {
            throw Exception('User authentication succeeded but identity verification failed');
          }
        } catch (e2) {
          AppLogger.e(_tag, 'Error in alternative sign-in approach', e2);
          rethrow;
        }
      }
      
      AppLogger.e(_tag, 'Sign in failed', e);
      rethrow;
    }
  }
  
  /// Check if user is already logged in
  static User? getCurrentUser() {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (e) {
      AppLogger.d(_tag, 'No saved credentials for auto-login');
      return null;
    }
  }
}
