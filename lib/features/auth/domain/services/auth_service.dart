import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../../../core/utils/debug_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service class for Firebase Authentication operations
class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  static const String _persistenceKey = 'auth_persistence_enabled';
  static const String _authUserKey = 'auth_user_cached';
  static const String _lastLoginKey = 'auth_last_login_timestamp';
  static const String _lastRefreshKey = 'auth_last_token_refresh';

  // Token refresh timer
  Timer? _tokenRefreshTimer;

  /// Constructor with optional FirebaseAuth instance for testing
  AuthService({firebase_auth.FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance {
    // Listen for auth state changes to ensure persistence is working
    _firebaseAuth.authStateChanges().listen((user) {
      if (user != null) {
        _cacheAuthStatus(true);
        _setLastLoginTimestamp();
        _setupTokenRefresh(user);
        DebugLogger.info('Auth state changed: User is authenticated');
      } else {
        _cacheAuthStatus(false);
        _cancelTokenRefresh();
        DebugLogger.info('Auth state changed: User is signed out');
      }
    });

    // Initialize token refresh for existing user if any
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      _setupTokenRefresh(currentUser);
    }
  }

  /// Set up periodic token refresh to prevent "session expired" errors
  void _setupTokenRefresh(firebase_auth.User user) {
    // Cancel any existing timer
    _cancelTokenRefresh();

    // Set up a new timer to refresh token every 45 minutes
    // Firebase tokens typically expire after 1 hour
    _tokenRefreshTimer =
        Timer.periodic(const Duration(minutes: 45), (timer) async {
      try {
        await user.getIdToken(true);
        await _saveLastRefreshTimestamp();
        DebugLogger.info('ID token refreshed successfully');
      } catch (e) {
        DebugLogger.error('Failed to refresh ID token', e);
      }
    });
  }

  /// Cancel token refresh timer
  void _cancelTokenRefresh() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
  }

  /// Save the last token refresh timestamp
  Future<void> _saveLastRefreshTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _lastRefreshKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      DebugLogger.error('Failed to save token refresh timestamp', e);
    }
  }

  /// Save the last login timestamp
  Future<void> _setLastLoginTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastLoginKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      DebugLogger.error('Failed to save login timestamp', e);
    }
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
    try {
      // Get credential from Firebase
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;

      // Verify the user's email is verified if required
      if (user != null) {
        // Always reload the user to get the most up-to-date verification status
        await user.reload();

        // Get fresh user reference after reload
        final freshUser = _firebaseAuth.currentUser;

        // Check if user is using Google sign-in (exempt from email verification)
        bool isGoogleSignIn = freshUser?.providerData
                .any((profile) => profile.providerId == 'google.com') ??
            false;

        // Only enforce email verification for email/password sign-in (not Google)
        if (freshUser != null && !freshUser.emailVerified && !isGoogleSignIn) {
          DebugLogger.info(
              'User email not verified. Sending verification email...');

          // Send a new verification email
          await freshUser.sendEmailVerification();

          // Sign out immediately to enforce verification
          await signOut();

          // Cache the auth provider type
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('auth_provider', 'email');
          } catch (e) {
            DebugLogger.error('Failed to cache auth provider type', e);
          }

          // Throw exception to notify caller about verification requirement
          throw firebase_auth.FirebaseAuthException(
            code: 'email-not-verified',
            message:
                'Please verify your email before signing in. A new verification link has been sent.',
          );
        }

        // Continue with verified user or Google user
        if (freshUser != null && (freshUser.emailVerified || isGoogleSignIn)) {
          // Create or update user document in Firestore if needed
          try {
            await _createOrUpdateUserDocument(freshUser, isGoogleSignIn);
          } catch (e) {
            // Don't fail login if just the Firestore operation fails
            DebugLogger.error('Error creating/updating user document', e);
          }

          // Store the remember me preference and auth provider type
          if (rememberMe) {
            await _saveRememberMePreference(true);

            // Cache the auth provider type
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(
                  'auth_provider', isGoogleSignIn ? 'google' : 'email');
            } catch (e) {
              DebugLogger.error('Failed to cache auth provider type', e);
            }

            // Set Firebase persistence to long-lived session
            await firebase_auth.FirebaseAuth.instance
                .setPersistence(firebase_auth.Persistence.LOCAL);

            // Cache auth status
            await _cacheAuthStatus(true);
          } else {
            // Use session persistence (cleared when browser/app is closed)
            await firebase_auth.FirebaseAuth.instance
                .setPersistence(firebase_auth.Persistence.SESSION);
          }

          // Force token refresh and set up refresh timer
          await freshUser.getIdToken(true);
          _setupTokenRefresh(freshUser);

          return freshUser;
        }
      }

      // If we get here without returning a verified user, sign out and return null
      await signOut();
      return null;
    } catch (e) {
      DebugLogger.error('Error during sign in', e);
      rethrow;
    }
  }

  /// Create or update user document in Firestore
  Future<void> _createOrUpdateUserDocument(
      firebase_auth.User user, bool isGoogleSignIn) async {
    // Check if user document exists
    final docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    // Create document if it doesn't exist
    if (!docSnapshot.exists) {
      DebugLogger.info('Creating missing user document for ${user.email}');

      // Get the display name from SharedPreferences if available
      final prefs = await SharedPreferences.getInstance();
      final storedEmail = prefs.getString('last_registration_email');
      final storedName = prefs.getString('last_registration_name');

      // Use stored name if this is the same email that just registered
      final displayName = (storedEmail == user.email && storedName != null)
          ? storedName
          : user.displayName;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'displayName': displayName,
        'photoURL': user.photoURL,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': user.emailVerified,
        'lastLogin': FieldValue.serverTimestamp(),
        'authProvider': isGoogleSignIn ? 'google' : 'email',
      }, SetOptions(merge: true));

      // Clear the stored registration info after using it
      if (storedEmail == user.email) {
        await prefs.remove('last_registration_email');
        await prefs.remove('last_registration_name');
      }
    } else {
      // Update last login time
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'lastLogin': FieldValue.serverTimestamp(),
        'emailVerified': user.emailVerified,
        'authProvider': isGoogleSignIn ? 'google' : 'email',
      });
    }
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

  /// Create a new user with email and password
  Future<firebase_auth.User?> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      // Create the user account
      final result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;

      // Send verification email immediately
      if (user != null) {
        await user.sendEmailVerification();
        DebugLogger.auth('Verification email sent to ${user.email}');

        // Important: Force sign out to prevent auto-login
        // Store user data temporarily so we can return it
        final userData = user;

        // Sign out immediately after registration
        await _firebaseAuth.signOut();
        DebugLogger.auth(
            'User signed out after registration to enforce email verification');

        // Clear persisted auth status since we're forcing sign out
        await _cacheAuthStatus(false);

        // Return the user data we captured before signing out
        return userData;
      }

      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      DebugLogger.error('Error creating user', e);
      rethrow;
    }
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

      // Force refresh to ensure profile changes are applied
      await user.reload();
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  /// Verify email with action code
  Future<void> verifyEmail(String actionCode) async {
    await _firebaseAuth.applyActionCode(actionCode);
    // Reload the user to update emailVerified status
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.reload();
    }
  }

  /// Resend verification email to current user
  Future<void> resendVerificationEmail() async {
    final user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    } else {
      throw Exception('No signed-in user or email already verified');
    }
  }

  /// Check if email is verified
  Future<bool> isEmailVerified() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      // Reload to get the most up-to-date status
      await user.reload();
      return user.emailVerified;
    }
    return false;
  }

  /// Manually refresh the auth token
  Future<String?> refreshToken() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        final token = await user.getIdToken(true);
        await _saveLastRefreshTimestamp();
        return token;
      } catch (e) {
        DebugLogger.error('Failed to refresh token', e);
        rethrow;
      }
    }
    return null;
  }

  /// Sign out
  Future<void> signOut() async {
    // Clear the remember me preference when signing out
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_persistenceKey, false);
      await prefs.setBool(_authUserKey, false);
      await prefs.remove(_lastLoginKey);
      await prefs.remove(_lastRefreshKey);
    } catch (e) {
      DebugLogger.error('Failed to clear auth preferences', e);
    }

    // Cancel token refresh timer
    _cancelTokenRefresh();

    await _firebaseAuth.signOut();
  }

  /// Clean up resources
  void dispose() {
    _cancelTokenRefresh();
  }

  /// Verify token is valid and not expired
  Future<bool> verifyTokenValidity() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return false;
    }

    try {
      // Try to get a token and check if operation succeeds
      final token = await user.getIdToken(true);
      if (token != null && token.isNotEmpty) {
        // Token is valid, update timestamp
        await _saveLastRefreshTimestamp();
        DebugLogger.info('Auth token is valid and has been refreshed');
        return true;
      }
      return false;
    } catch (e) {
      DebugLogger.error('Token validation failed', e);

      // Check if error indicates token is expired or invalid
      if (e.toString().contains('expired') ||
          e.toString().contains('invalid') ||
          e.toString().contains('user-token-expired')) {
        // Try to reauthenticate silently if possible
        return false;
      }

      return false;
    }
  }

  /// Get the Firebase ID token for API requests
  Future<String?> getIdToken() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        return await user.getIdToken();
      } catch (e) {
        DebugLogger.error('Failed to get ID token', e);
        return null;
      }
    }
    return null;
  }

  /// Send verification email to a specific email address
  /// This is used when a user tries to login with an unverified email
  Future<void> sendVerificationEmailToAddress(String email) async {
    try {
      // First check if the email belongs to an existing user
      var methods = await _firebaseAuth.fetchSignInMethodsForEmail(email);

      if (methods.isEmpty) {
        throw firebase_auth.FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found with this email address.',
        );
      }

      // Can't directly send verification email without being logged in
      // So we'll send a password reset email instead, which indirectly helps verify
      DebugLogger.info(
          'Sending password reset email to $email as verification alternative');
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      DebugLogger.info(
          'Password reset email sent to $email which will help verify the account');
    } catch (e) {
      DebugLogger.error('Failed to send verification email to address', e);
      rethrow;
    }
  }
}
