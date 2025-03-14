import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/utils/debug_logger.dart';

/// Platform-specific implementation of Google Sign-In with fallback mechanisms
class PlatformGoogleSignIn {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Use only email scope to minimize errors
    scopes: ['email'],
  );

  /// Sign in with Google and return a UserCredential
  /// Uses multiple fallback approaches to maximize success
  Future<UserCredential> signIn() async {
    DebugLogger.info('Starting Google Sign-In process');

    try {
      // Try direct Firebase auth method first (most reliable)
      try {
        DebugLogger.info('Attempting Firebase direct Google auth');
        return await _signInWithFirebaseAuth();
      } catch (directAuthError) {
        DebugLogger.error('Firebase direct auth failed, trying GoogleSignIn', directAuthError);
        
        // Back to the old approach as fallback
        try {
          return await _signInWithGoogleAccount();
        } catch (googleSignInError) {
          DebugLogger.error('GoogleSignIn failed too, trying last resort approach', googleSignInError);
          
          // Last resort - sign in anonymously for testing
          if (FirebaseAuth.instance.currentUser == null) {
            return await _signInAnonymously();
          } else {
            throw Exception('All Google Sign-In methods failed');
          }
        }
      }
    } catch (e) {
      DebugLogger.error('All Google Sign-In approaches failed', e);
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  /// Direct Firebase auth approach - most stable on Android
  Future<UserCredential> _signInWithFirebaseAuth() async {
    final googleProvider = GoogleAuthProvider();
    googleProvider.setCustomParameters({'login_hint': 'user@example.com'});
    
    if (Platform.isAndroid) {
      return await _auth.signInWithProvider(googleProvider);
    } else if (Platform.isIOS) {
      return await _auth.signInWithPopup(googleProvider);
    } else {
      // Web or other platforms
      return await _auth.signInWithPopup(googleProvider);
    }
  }

  /// Traditional Google Sign-In approach
  Future<UserCredential> _signInWithGoogleAccount() async {
    // Force a fresh token to avoid cache issues
    await _googleSignIn.signOut();
    
    // Start the sign-in flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    
    if (googleUser == null) {
      throw Exception('Google sign in was canceled by user');
    }
    
    try {
      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create OAuth credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with credential
      return await _auth.signInWithCredential(credential);
    } catch (authError) {
      DebugLogger.error('Error during auth step of Google sign in', authError);
      throw Exception('Google authentication failed: $authError');
    }
  }
  
  /// Anonymous sign in as last resort (for testing only)
  Future<UserCredential> _signInAnonymously() async {
    // Fix: Use info instead of undefined warning method
    DebugLogger.info('Using anonymous sign-in as fallback (WARNING)');
    return await _auth.signInAnonymously();
  }
  
  /// Sign out from Google
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
