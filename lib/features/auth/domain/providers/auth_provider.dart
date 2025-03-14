import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/debug_logger.dart';
import '../../../../core/utils/app_logger.dart';
import '../enums/auth_status.dart'; // Fixed import
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../services/admin_service.dart'; // Add import for AdminService

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

  /// Constructor with optional service injections for testing
  AuthProvider({
    AuthService? authService,
    GoogleAuthService? googleAuthService,
  })  : _authService = authService ?? AuthService(),
        _googleAuthService = googleAuthService ?? GoogleAuthService() {
    // Load the remember me preference when the provider is created
    _loadRememberMePreference();

    // Listen to Firebase Auth state changes
    firebase_auth.FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && _status != AuthStatus.authenticated) {
        _user = user;
        _status = AuthStatus.authenticated;
        _fetchUserModel();
        notifyListeners();
        DebugLogger.auth('Auth state changed: User authenticated');
      } else if (user == null && _status == AuthStatus.authenticated) {
        _user = null;
        _userModel = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        DebugLogger.auth('Auth state changed: User signed out');
      }
    });
  }

  /// Load the saved remember me preference
  Future<void> _loadRememberMePreference() async {
    try {
      _rememberMe = await _authService.getSavedRememberMe();
      DebugLogger.auth('Loaded remember me preference: $_rememberMe');
    } catch (e) {
      DebugLogger.error('Failed to load remember me preference', e);
    }
  }

  /// Set remember me preference
  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  /// Check authentication status on app start
  Future<void> checkAuthStatus() async {
    DebugLogger.auth('Checking authentication status');
    _setLoading(true);

    try {
      // First check if there's a current Firebase user
      final currentUser = _authService.getCurrentUser();

      if (currentUser != null) {
        _user = currentUser;
        await _fetchUserModel();
        _status = AuthStatus.authenticated;
        DebugLogger.auth('User is authenticated: ${_user?.email}');
      } else {
        // If no current user, check if user was previously authenticated
        // and we should try to restore the session
        final wasAuthenticated =
            await _authService.wasPreviouslyAuthenticated();
        final shouldRemember = await _authService.getSavedRememberMe();

        if (wasAuthenticated && shouldRemember) {
          _status = AuthStatus.authenticating;
          DebugLogger.auth(
              'Attempting to restore previous authentication session');

          // We'll let the authStateChanges listener handle the state update
          // if the Firebase Auth persistence restores the session automatically
        } else {
          _status = AuthStatus.unauthenticated;
          DebugLogger.auth('User is not authenticated');
        }
      }
    } catch (e) {
      _status = AuthStatus.error;
      _error = 'Failed to check authentication status';
      DebugLogger.error('Auth status check failed', e);
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with email and password
  Future<bool> signIn(String email, String password, {bool? rememberMe}) async {
    _setLoading(true);
    _error = null;

    // Use the passed rememberMe value or fall back to the instance variable
    final shouldRemember = rememberMe ?? _rememberMe;

    try {
      // Pass the rememberMe flag to the auth service
      final user = await _authService.signInWithEmailAndPassword(
          email, password,
          rememberMe: shouldRemember);

      if (user != null) {
        _user = user;
        await _fetchUserModel();
        _status = AuthStatus.authenticated;
        DebugLogger.auth('User signed in: ${user.email}');
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to sign in';
        _status = AuthStatus.error;
        DebugLogger.error('Sign in failed - no user returned');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = _handleAuthError(e);
      _status = AuthStatus.error;
      DebugLogger.error('Sign in failed', e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Register with email and password
  Future<bool> register(
      String email, String password, String displayName) async {
    _setLoading(true);
    _error = null;

    try {
      final user =
          await _authService.createUserWithEmailAndPassword(email, password);
      if (user != null) {
        // Update display name
        await _authService.updateUserProfile(displayName: displayName);

        // Get updated user
        _user = _authService.getCurrentUser();

        // Create user document in Firestore
        final userMap = {
          'email': email,
          'displayName': displayName,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .set(userMap, SetOptions(merge: true));

        await _fetchUserModel();
        _status = AuthStatus.authenticated;
        DebugLogger.auth('User registered: $email');
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to register user';
        _status = AuthStatus.error;
        DebugLogger.error('Registration failed - no user returned');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = _handleAuthError(e);
      _status = AuthStatus.error;
      DebugLogger.error('Registration failed', e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
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

        // Create or update user document in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'lastLogin': FieldValue.serverTimestamp(),
          'role': 'user',
        }, SetOptions(merge: true));

        await _fetchUserModel();
        DebugLogger.auth('Google sign in successful');

        // Also set the remember me flag for Google Sign-In
        try {
          // Using direct access to SharedPreferences instead of private methods
          await _authService
              .getSavedRememberMe(); // Just to verify the service is working
          // Save the auth state using SharedPreferences directly in this method
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('auth_persistence_enabled', true);
          await prefs.setBool('auth_user_cached', true);
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

  /// Sign out current user
  Future<void> signOut() async {
    _setLoading(true);

    try {
      // Clear admin status cache first
      await AdminService.clearAdminStatus();

      // Then sign out from Firebase Auth
      await _authService.signOut();

      _user = null;
      _userModel = null;
      _status = AuthStatus.unauthenticated;
      DebugLogger.auth('User signed out');
    } catch (e) {
      _error = 'Failed to sign out';
      DebugLogger.error('Sign out failed', e);
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

  /// Helper function to handle common Firebase auth errors
  String _handleAuthError(dynamic error) {
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password.';
        case 'email-already-in-use':
          return 'Email is already in use.';
        case 'invalid-email':
          return 'Email is invalid.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many requests. Try again later.';
        default:
          return error.message ?? 'An unknown error occurred.';
      }
    }
    return 'An unexpected error occurred.';
  }
}
