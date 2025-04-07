import '../utils/debug_logger.dart';
import '../utils/navigation_logger.dart';
import '../../features/auth/domain/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A global service that holds authentication provider
class GlobalAuthService {
  static final GlobalAuthService _instance = GlobalAuthService._internal();

  factory GlobalAuthService() {
    return _instance;
  }

  GlobalAuthService._internal() {
    // Initialize immediately on creation
    _quickInit();
  }

  AuthProvider? _authProvider;
  bool _isEmergencyMode = false;
  bool _isInitialized = false;
  bool _authCheckInProgress = false;
  bool _cachedAuthStatus = false;

  /// Flag to track if service is fully initialized
  bool get isInitialized => _isInitialized;

  /// Quick initialization to read cached values - this runs immediately on app start
  void _quickInit() async {
    try {
      DebugLogger.info(
          'NAVBAR DEBUG: GlobalAuthService - Starting _quickInit()');
      final prefs = await SharedPreferences.getInstance();
      _cachedAuthStatus = prefs.getBool('auth_user_cached') ?? false;
      if (_cachedAuthStatus) {
        DebugLogger.info(
            'NAVBAR DEBUG: GlobalAuthService - Quick init found cached auth status: true');

        // Immediately create auth provider with cached status
        // This ensures we don't show login screen at all
        _authProvider = AuthProvider(initialAuthStatus: true);
        _isInitialized = true;
        DebugLogger.info(
            'NAVBAR DEBUG: GlobalAuthService - Created AuthProvider with initialAuthStatus=true');
      } else {
        DebugLogger.info(
            'NAVBAR DEBUG: GlobalAuthService - No cached auth status found, will do full check');
      }
    } catch (e) {
      DebugLogger.error(
          'NAVBAR DEBUG: GlobalAuthService - Quick init error', e);
    }
  }

  /// Initialize auth service and check previous auth state
  Future<void> initialize() async {
    DebugLogger.info(
        'NAVBAR DEBUG: GlobalAuthService - Initializing GlobalAuthService');

    if (_isInitialized) {
      DebugLogger.info(
          'NAVBAR DEBUG: GlobalAuthService - Already initialized, skipping');
      return;
    }

    try {
      // Set auth status checking flag to prevent duplicate checks
      _authCheckInProgress = true;

      // If auth provider already created by _quickInit, just use it
      if (_authProvider == null) {
        DebugLogger.info(
            'NAVBAR DEBUG: GlobalAuthService - Creating new AuthProvider with cachedAuthStatus=$_cachedAuthStatus');
        // Create auth provider with cached status
        _authProvider = AuthProvider(initialAuthStatus: _cachedAuthStatus);
      } else {
        DebugLogger.info(
            'NAVBAR DEBUG: GlobalAuthService - Using existing AuthProvider from _quickInit');
      }

      // Optimization: Skip full auth check for returning users
      if (_cachedAuthStatus) {
        _isInitialized = true;
        _authCheckInProgress = false;
        DebugLogger.info(
            'NAVBAR DEBUG: GlobalAuthService - Initialized with cached status, skipping full check');
        return;
      }

      // For new sessions, do a full check
      if (_authProvider != null) {
        DebugLogger.info(
            'NAVBAR DEBUG: GlobalAuthService - Doing full auth check');
        // Priority loading - get remember me value ASAP
        final rememberMe = await _authProvider!.loadRememberMePreference();
        _authProvider!.setRememberMe(rememberMe);
        DebugLogger.info(
            'NAVBAR DEBUG: GlobalAuthService - Calling checkAuthStatus()');
        await _authProvider!.checkAuthStatus();
        DebugLogger.info(
            'NAVBAR DEBUG: GlobalAuthService - checkAuthStatus() completed, authenticated=${_authProvider!.isAuthenticated}');
      }

      _authCheckInProgress = false;
      _isInitialized = true;
      DebugLogger.info(
          'NAVBAR DEBUG: GlobalAuthService - Initialization complete');
    } catch (e) {
      _authCheckInProgress = false;
      DebugLogger.error(
          'NAVBAR DEBUG: GlobalAuthService - Failed to initialize', e);
      createEmergencyAuthProvider();
      rethrow;
    }
  }

  /// Creates an emergency auth provider when normal initialization fails
  Future<void> createEmergencyAuthProvider() async {
    try {
      DebugLogger.info('Creating emergency AuthProvider');
      _authProvider = AuthProvider(initialAuthStatus: _cachedAuthStatus);
      _isEmergencyMode = true;
      DebugLogger.info('Emergency AuthProvider created successfully');
    } catch (e) {
      DebugLogger.error('FATAL: Failed to create emergency AuthProvider', e);
    }
  }

  /// Check if a user is already authenticated
  Future<bool> checkIfAuthenticated() async {
    DebugLogger.info(
        'NAVBAR DEBUG: GlobalAuthService - checkIfAuthenticated() called');

    // Fast path: if we have cached status, return true immediately
    if (_cachedAuthStatus) {
      DebugLogger.info(
          'NAVBAR DEBUG: GlobalAuthService - Using cached auth status (true)');
      return true;
    }

    // If auth check is already in progress, don't start another one
    if (_authCheckInProgress) {
      DebugLogger.info(
          'NAVBAR DEBUG: GlobalAuthService - Auth check in progress, waiting...');
      while (_authCheckInProgress) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      DebugLogger.info(
          'NAVBAR DEBUG: GlobalAuthService - Auth check completed while waiting, result: ${isAuthenticated}');
      return isAuthenticated;
    }

    // If not initialized yet, do it now
    if (_authProvider == null) {
      DebugLogger.info(
          'NAVBAR DEBUG: GlobalAuthService - AuthProvider not initialized, calling initialize()');
      await initialize();
      DebugLogger.info(
          'NAVBAR DEBUG: GlobalAuthService - initialize() completed, authenticated=${isAuthenticated}');
    }

    return isAuthenticated;
  }

  // Getters for auth status with null safety
  bool get isAuthenticated {
    if (_cachedAuthStatus) {
      DebugLogger.info(
          'NAVBAR DEBUG: GlobalAuthService - isAuthenticated returning true due to _cachedAuthStatus');
      return true;
    }
    if (_authProvider == null) {
      DebugLogger.info(
          'NAVBAR DEBUG: GlobalAuthService - isAuthenticated returning false due to null _authProvider');
      return false;
    }

    final result = _authProvider!.isAuthenticated;
    DebugLogger.info(
        'NAVBAR DEBUG: GlobalAuthService - isAuthenticated returning ${result} from _authProvider');
    return result;
  }

  bool get isLoading {
    if (_authProvider == null) {
      return false;
    }
    return _authProvider!.isLoading;
  }

  String? get error {
    if (_authProvider == null) {
      return "Authentication service not initialized";
    }
    return _authProvider!.error;
  }

  /// Returns true if running in emergency fallback mode
  bool get isEmergencyMode => _isEmergencyMode;

  /// Safe getter that never returns null - creates emergency instance if needed
  AuthProvider get authProvider {
    if (_authProvider == null) {
      DebugLogger.error(
          'Accessing null _authProvider, creating emergency instance');
      createEmergencyAuthProvider();
    }

    return _authProvider!;
  }

  /// Attempt to sign in with email and password
  Future<bool> signIn(
      {required String email,
      required String password,
      bool rememberMe = false}) async {
    try {
      DebugLogger.info(
          'NAVBAR DEBUG: GlobalAuthService - signIn called for email: $email, rememberMe: $rememberMe');

      if (_authProvider == null) {
        DebugLogger.info(
            'NAVBAR DEBUG: GlobalAuthService - Creating emergency AuthProvider for signIn');
        await createEmergencyAuthProvider();
      }

      // Use positional parameters to match AuthProvider signature
      final result =
          await _authProvider!.signIn(email, password, rememberMe: rememberMe);

      // Cache auth status for faster startup
      if (result && rememberMe) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('auth_user_cached', true);
          _cachedAuthStatus = true;
          DebugLogger.info(
              'NAVBAR DEBUG: GlobalAuthService - Cached authentication status for faster startup');
        } catch (e) {
          DebugLogger.error(
              'NAVBAR DEBUG: GlobalAuthService - Failed to cache auth status',
              e);
        }
      }

      DebugLogger.info(
          'NAVBAR DEBUG: GlobalAuthService - signIn result: ${_authProvider!.isAuthenticated}');
      return _authProvider!.isAuthenticated;
    } catch (e) {
      DebugLogger.error('NAVBAR DEBUG: GlobalAuthService - Sign in failed', e);
      rethrow;
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      DebugLogger.info('NAVBAR DEBUG: GlobalAuthService - Starting signOut()');

      if (_authProvider == null) {
        DebugLogger.info(
            'NAVBAR DEBUG: GlobalAuthService - Creating emergency AuthProvider for signOut');
        await createEmergencyAuthProvider();
        return;
      }

      // Clear cached authentication status first
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('auth_user_cached', false);
        _cachedAuthStatus = false;
        DebugLogger.info(
            'NAVBAR DEBUG: GlobalAuthService - Cleared cached authentication status');
      } catch (e) {
        DebugLogger.error(
            'NAVBAR DEBUG: GlobalAuthService - Failed to clear cached auth status',
            e);
      }

      await _authProvider!.signOut();
      DebugLogger.info(
          'NAVBAR DEBUG: GlobalAuthService - signOut completed, authenticated=${_authProvider!.isAuthenticated}');
    } catch (e) {
      DebugLogger.error('NAVBAR DEBUG: GlobalAuthService - Sign out failed', e);
      rethrow;
    }
  }
}
