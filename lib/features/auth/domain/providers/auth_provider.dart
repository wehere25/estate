import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/debug_logger.dart';
import '../../../../core/utils/app_logger.dart';
import '../enums/auth_status.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../services/admin_service.dart';
import '../services/user_profile_service.dart'; // Added missing import

/// Provider for authentication state and operations
class AuthProvider with ChangeNotifier {
  static const String _tag = 'AuthProvider';

  /// Authentication status
  AuthStatus _status = AuthStatus.initial;
  AuthStatus get status => _status;

  /// Current user from Firebase Authentication
  firebase_auth.User? _user;
  firebase_auth.User? get user => _user;

  /// User model with additional app-specific data
  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  /// Error message if authentication fails
  String? _error;
  String? get error => _error;

  /// Whether authentication is in progress
  bool _isLoading = false;
  bool _rememberMe = false;

  /// Flag to indicate if we're checking auth status
  bool _isCheckingAuth = true;
  bool get isCheckingAuth {
    if (_usingCachedAuth && _status == AuthStatus.authenticated) {
      return false;
    }
    return _isCheckingAuth;
  }

  /// Whether user is currently authenticated
  bool get isAuthenticated => _user != null;

  /// Whether auth is in loading state
  bool get isLoading => _isLoading;

  /// Whether to remember user login
  bool get rememberMe => _rememberMe;

  /// Auth service that handles Firebase Authentication operations
  final AuthService _authService;

  /// Google auth service for social sign-in
  final GoogleAuthService _googleAuthService;

  /// Add a flag to track if we're using cached auth
  bool _usingCachedAuth = false;

  /// Constructor with optional service injections for testing
  AuthProvider({
    AuthService? authService,
    GoogleAuthService? googleAuthService,
    bool initialAuthStatus = false,
  })  : _authService = authService ?? AuthService(),
        _googleAuthService = googleAuthService ?? GoogleAuthService() {
    if (initialAuthStatus) {
      _status = AuthStatus.authenticated;
      _isCheckingAuth = false;
      _usingCachedAuth = true;
      DebugLogger.info(
          'AuthProvider: Using cached auth status for initial state');
    }

    // Immediately load preferences for faster UI response
    loadRememberMePreference();

    // Initialize Firebase Auth listener
    _initAuth();
  }

  /// Add a getter to check if we're using cached auth
  bool get usingCachedAuth => _usingCachedAuth;

  /// Load the saved remember me preference
  Future<bool> loadRememberMePreference() async {
    try {
      _rememberMe = await _authService.getSavedRememberMe();
      DebugLogger.auth('Loaded remember me preference: $_rememberMe');
      return _rememberMe;
    } catch (e) {
      DebugLogger.error('Failed to load remember me preference', e);
      return false;
    }
  }

  /// Set remember me preference
  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  /// Check for previous authentication state immediately on startup
  Future<void> _checkPreviousAuthState() async {
    try {
      final wasAuthenticated = await _authService.wasPreviouslyAuthenticated();
      final shouldRemember = await _authService.getSavedRememberMe();

      if (wasAuthenticated && shouldRemember) {
        DebugLogger.auth(
            'Previous auth session detected, maintaining loading state');
        _status = AuthStatus.authenticating;
        // We'll let the authStateChanges listener handle the actual auth
      } else {
        _isCheckingAuth = false;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    } catch (e) {
      DebugLogger.error('Error checking previous auth state', e);
      _isCheckingAuth = false;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Initialize auth provider and setup Firebase Auth listeners
  void _initAuth() {
    try {
      // Check if we're using cached auth to avoid unnecessary processing
      if (!_usingCachedAuth) {
        _isCheckingAuth = true;
        notifyListeners();
      }

      // Start the auth check immediately
      _checkPreviousAuthState();

      // Listen to Firebase Auth state changes
      firebase_auth.FirebaseAuth.instance
          .authStateChanges()
          .listen((user) async {
        if (user != null) {
          // Always reload the user to get the latest emailVerified status
          await user.reload();
          final freshUser = firebase_auth.FirebaseAuth.instance.currentUser;

          // Check if the user signed in with Google (exempt from email verification)
          bool isGoogleSignIn = freshUser?.providerData
                  .any((profile) => profile.providerId == 'google.com') ??
              false;

          // Check if email is verified before fully authenticating (except for Google sign-in)
          if (freshUser != null &&
              (freshUser.emailVerified || isGoogleSignIn)) {
            _user = freshUser;
            _status = AuthStatus.authenticated;
            _isCheckingAuth = false;
            await _fetchUserModel();
            notifyListeners();
            DebugLogger.auth(
                'Auth state changed: User authenticated with ${isGoogleSignIn ? "Google sign-in" : "verified email"}');
          } else if (freshUser != null) {
            // User exists but email not verified
            // Do not set the user property temporarily to avoid briefly showing authenticated state
            // _user = freshUser; <-- Remove this line to prevent brief authentication

            // Update status to unverified immediately
            _status = AuthStatus.unverified;
            _isCheckingAuth = false;
            notifyListeners();
            DebugLogger.auth(
                'Auth state changed: User signed in but email not verified');

            // Force sign out for unverified users to maintain verification requirement
            // Reduce delay to be more immediate
            await _authService.signOut();
            _user = null;
            _status = AuthStatus.unauthenticated;
            notifyListeners();
          }
        } else if (_status == AuthStatus.authenticated ||
            _status == AuthStatus.unverified) {
          _user = null;
          _userModel = null;
          _status = AuthStatus.unauthenticated;
          _isCheckingAuth = false;
          notifyListeners();
          DebugLogger.auth('Auth state changed: User signed out');
        } else if (_status == AuthStatus.initial) {
          // If we're in initial state and get a null user, mark as unauthenticated
          _status = AuthStatus.unauthenticated;
          _isCheckingAuth = false;
          notifyListeners();
          DebugLogger.auth('Initial auth check complete: No user found');
        }
      });
    } catch (e) {
      DebugLogger.error('Error initializing auth provider', e);
      _status = AuthStatus.error;
      _error = 'Failed to initialize authentication provider';
      notifyListeners();
    }
  }

  /// Check authentication status on app start
  Future<void> checkAuthStatus() async {
    if (_isCheckingAuth) {
      DebugLogger.info(
          'NAVBAR DEBUG: AuthProvider - Auth check already in progress');
      return;
    }

    try {
      // Don't set _isCheckingAuth to true if we're using cached auth
      if (!_usingCachedAuth) {
        _isCheckingAuth = true;
        notifyListeners();
      }

      DebugLogger.info(
          'NAVBAR DEBUG: AuthProvider - Checking authentication status');
      _setLoading(true);

      // First check if there's a current Firebase user
      final currentUser = _authService.getCurrentUser();

      if (currentUser != null) {
        // Verify if token is valid and not expired
        final isTokenValid = await _authService.verifyTokenValidity();

        if (isTokenValid) {
          _user = currentUser;
          await _fetchUserModel();
          _status = AuthStatus.authenticated;
          DebugLogger.info(
              'NAVBAR DEBUG: AuthProvider - User is authenticated with valid token: ${_user?.email}');
        } else {
          // Token expired or invalid - force a new sign in
          _error = 'Your session has expired. Please sign in again.';
          _status = AuthStatus.unauthenticated;
          await _authService.signOut(); // Clear invalid session
          DebugLogger.info(
              'NAVBAR DEBUG: AuthProvider - Auth token expired or invalid, user signed out');
        }
      } else {
        // If no current user, check if user was previously authenticated
        // and we should try to restore the session
        final wasAuthenticated =
            await _authService.wasPreviouslyAuthenticated();
        final shouldRemember = await _authService.getSavedRememberMe();

        if (wasAuthenticated && shouldRemember) {
          _status = AuthStatus.authenticating;
          DebugLogger.info(
              'NAVBAR DEBUG: AuthProvider - Attempting to restore previous authentication session');

          // We'll let the authStateChanges listener handle the state update
          // if the Firebase Auth persistence restores the session automatically
        } else {
          _status = AuthStatus.unauthenticated;
          DebugLogger.info(
              'NAVBAR DEBUG: AuthProvider - User is not authenticated');
        }
      }

      // After checking, we're no longer using just cached auth
      _usingCachedAuth = false;
    } catch (e) {
      _status = AuthStatus.error;
      _error = 'Failed to check authentication status';
      DebugLogger.error(
          'NAVBAR DEBUG: AuthProvider - Auth status check failed', e);
    } finally {
      _setLoading(false);
      _isCheckingAuth = false;
      notifyListeners();
    }
  }

  /// Handle auth error to provide user-friendly messages
  String _handleAuthError(dynamic error) {
    DebugLogger.error('Authentication error', error);

    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-credential':
        case 'user-not-found':
        case 'wrong-password':
          return 'Invalid email or password. Please try again.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'email-already-in-use':
          return 'An account already exists for this email.';
        case 'operation-not-allowed':
          return 'This operation is not allowed. Please contact support.';
        case 'weak-password':
          return 'Password is too weak. Please choose a stronger password.';
        case 'email-not-verified':
          return 'Please verify your email before signing in. A verification link has been sent.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with the same email but different sign-in credentials.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'invalid-verification-code':
          return 'Invalid verification code. Please try again.';
        case 'invalid-verification-id':
          return 'Invalid verification ID. Please try again.';
        case 'network-request-failed':
          return 'Network error. Please check your connection and try again.';
        case 'too-many-requests':
          return 'Too many unsuccessful login attempts. Please try again later or reset your password.';
        default:
          return 'Authentication error: ${error.message ?? error.code}';
      }
    }

    return error.toString();
  }

  /// Sign in with email and password
  Future<bool> signIn(String email, String password,
      {bool rememberMe = false}) async {
    try {
      DebugLogger.info(
          'NAVBAR DEBUG: AuthProvider - Starting signIn() with email: $email');
      _setLoading(true);
      _error = null;

      // Use the passed rememberMe value or fall back to the instance variable
      final shouldRemember = rememberMe ?? _rememberMe;

      // Pass the rememberMe flag to the auth service
      final user = await _authService.signInWithEmailAndPassword(
          email, password,
          rememberMe: shouldRemember);

      // Email verification handling in AuthService now

      if (user != null) {
        _user = user;
        await _fetchUserModel();
        _status = AuthStatus.authenticated;
        _usingCachedAuth = true;
        DebugLogger.info(
            'NAVBAR DEBUG: AuthProvider - User signed in successfully: ${user.email}');
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to sign in';
        _status = AuthStatus.error;
        DebugLogger.error(
            'NAVBAR DEBUG: AuthProvider - Sign in failed - no user returned');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = _handleAuthError(e);
      _status = AuthStatus.error;
      DebugLogger.error('NAVBAR DEBUG: AuthProvider - Sign in failed', e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Register with email and password
  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      // Create the user account
      final user =
          await _authService.createUserWithEmailAndPassword(email, password);

      if (user != null) {
        // Don't try to create Firestore document directly here
        // Firebase Functions or first login will handle this

        // Store email temporarily to help with verification later
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_registration_email', email);
        await prefs.setString('last_registration_name', name);

        // Make sure the user is completely signed out before proceeding
        await _authService.signOut();

        // Important: Don't set _user here to avoid brief authentication state
        _user = null;
        _status = AuthStatus.unverified;

        // Set success message
        _error =
            'Account created! Please check your email to verify your account before signing in.';

        DebugLogger.auth(
            'User registered: $email. Verification email sent and user signed out.');
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to register';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      if (e.toString().contains('email-already-in-use')) {
        _error =
            'An account already exists for this email. Please sign in instead.';
      } else {
        _error = _handleAuthError(e);
      }
      _status = AuthStatus.error;
      DebugLogger.error('Registration failed', e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Send another verification email
  Future<bool> resendVerificationEmail() async {
    if (_user == null) {
      _error = 'No user is signed in';
      return false;
    }

    try {
      await _authService.resendVerificationEmail();
      _error =
          'A new verification email has been sent. Please check your inbox.';
      notifyListeners();
      return true;
    } catch (e) {
      _error = _handleAuthError(e);
      notifyListeners();
      return false;
    }
  }

  /// Verify email with action code
  Future<bool> verifyEmail(String actionCode) async {
    _setLoading(true);
    _error = null;

    try {
      await _authService.verifyEmail(actionCode);

      // Update our user
      if (_user != null) {
        await _user!.reload();

        // Update Firestore user document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({'emailVerified': true});
      }

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _handleAuthError(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Manually refresh the auth token to prevent session expiration
  Future<bool> refreshAuthToken() async {
    try {
      final token = await _authService.refreshToken();
      return token != null;
    } catch (e) {
      _error = _handleAuthError(e);
      DebugLogger.error('Token refresh failed', e);
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _error = null;

    try {
      DebugLogger.auth('Starting Google sign in flow');
      final user = await _googleAuthService.signInWithGoogle();

      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;
        _isCheckingAuth = false; // Explicitly set checking to false

        // Always set remember me to true for Google sign-in for better UX
        _rememberMe = true;

        // Create or update user document in Firestore
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
            'lastLogin': FieldValue.serverTimestamp(),
            'role': 'user',
            'authProvider': 'google', // Track the auth provider
            'emailVerified': true, // Google users are always verified
          }, SetOptions(merge: true));
        } catch (e) {
          // Don't fail login if Firestore update fails
          DebugLogger.error('Failed to update Firestore user document', e);
        }

        await _fetchUserModel();
        DebugLogger.auth('Google sign in successful');

        // Also set the remember me flag for Google Sign-In and cache auth status
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('auth_persistence_enabled', true);
          await prefs.setBool('auth_user_cached', true);
          await prefs.setString('auth_provider', 'google');
          DebugLogger.info(
              'Authentication persistence preferences set for Google sign-in');
        } catch (e) {
          DebugLogger.error(
              'Failed to set auth preferences for Google sign-in', e);
        }

        _setLoading(false); // Set loading to false before notifying
        notifyListeners();
        return true;
      }
      _setLoading(false);
      _error = 'Google sign in cancelled';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _setLoading(false);
      _error = _handleAuthError(e);
      _status = AuthStatus.unauthenticated;
      DebugLogger.error('Google sign in failed', e);
      notifyListeners();
      return false;
    }
  }

  /// Sign in anonymously as a guest
  Future<bool> signInAnonymously() async {
    _setLoading(true);
    _error = null;

    try {
      DebugLogger.auth('Starting anonymous sign in');
      final credential =
          await firebase_auth.FirebaseAuth.instance.signInAnonymously();

      if (credential.user != null) {
        _user = credential.user;
        _status = AuthStatus.authenticated;

        // Create a basic user document for anonymous users
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .set({
          'isAnonymous': true,
          'lastLogin': FieldValue.serverTimestamp(),
          'role': 'guest',
        }, SetOptions(merge: true));

        await _fetchUserModel();
        DebugLogger.auth('Anonymous sign in successful');
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to sign in anonymously';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = _handleAuthError(e);
      _status = AuthStatus.error;
      DebugLogger.error('Anonymous sign in failed', e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    _setLoading(true);
    DebugLogger.info('NAVBAR DEBUG: AuthProvider - Starting signOut()');

    try {
      // Clear admin status cache first
      await AdminService.clearAdminStatus();

      // Then sign out from Firebase Auth
      await _authService.signOut();

      _user = null;
      _userModel = null;
      _status = AuthStatus.unauthenticated;
      _usingCachedAuth = false;
      DebugLogger.info(
          'NAVBAR DEBUG: AuthProvider - User signed out, status: $_status');
    } catch (e) {
      _error = 'Failed to sign out';
      DebugLogger.error('NAVBAR DEBUG: AuthProvider - Sign out failed', e);
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Fetch user model from Firestore based on current Firebase user
  Future<void> _fetchUserModel() async {
    if (_user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        _userModel = UserModel.fromMap({
          'id': _user!.uid,
          'email': _user!.email,
          ...doc.data()!,
        });
      } else {
        // Create basic user model if not in Firestore yet
        _userModel = UserModel(
          id: _user!.uid,
          email: _user!.email ?? '',
          displayName: _user!.displayName,
          photoURL: _user!.photoURL,
        );
      }
    } catch (e) {
      AppLogger.e(_tag, 'Failed to fetch user model', e);
    }
  }

  /// Helper to update loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Resend verification email to a specific email address
  Future<void> resendVerificationEmailToAddress(String email) async {
    _setLoading(true);
    _error = null;

    try {
      // Don't attempt to sign in temporarily - just send a verification email
      await _authService.sendVerificationEmailToAddress(email);
      DebugLogger.auth('Verification email resent to $email');
    } catch (e) {
      String errorMsg = e.toString();
      // Handle Firestore permission errors gracefully
      if (errorMsg.contains('permission-denied')) {
        DebugLogger.error('Firestore permission error during verification', e);
        _error = 'Verification email sent. Please check your inbox.';
      } else {
        _error = _handleAuthError(e);
      }
      _status = AuthStatus.error;
      DebugLogger.error('Failed to resend verification email', e);
      notifyListeners();

      // Only throw if not a permission error
      if (!errorMsg.contains('permission-denied')) {
        throw Exception(_error);
      }
    } finally {
      _setLoading(false);
    }
  }
}
