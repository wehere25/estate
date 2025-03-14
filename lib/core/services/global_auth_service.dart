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

  GlobalAuthService._internal();

  AuthProvider? _authProvider;
  bool _isEmergencyMode = false;
  bool _isInitialized = false;

  /// Flag to track if service is fully initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the authentication service
  Future<void> initialize() async {
    NavigationLogger.log(
      NavigationEventType.providerAccess,
      'STARTING GlobalAuthService initialization',
    );

    if (_isInitialized) {
      DebugLogger.info('GlobalAuthService already initialized, skipping');
      return;
    }

    try {
      DebugLogger.info('Creating new AuthProvider instance');
      _authProvider = AuthProvider();

      if (_authProvider == null) {
        DebugLogger.error('CRITICAL: _authProvider is null after assignment');
        await createEmergencyAuthProvider();
        return;
      } else {
        DebugLogger.info('AuthProvider instance created successfully');
      }

      // Pre-check if we were previously authenticated to improve user experience
      final prefs = await SharedPreferences.getInstance();
      final wasAuthenticated = prefs.getBool('auth_user_cached') ?? false;

      if (wasAuthenticated) {
        DebugLogger.info(
            'Previous authentication session detected - preparing UI early');
      }

      // Check auth status and wait for it to complete
      DebugLogger.info('Checking auth status...');
      await _authProvider!.checkAuthStatus();

      final status = _authProvider?.status?.toString() ?? 'UNKNOWN';
      final isAuth = _authProvider?.isAuthenticated.toString() ?? 'UNKNOWN';

      DebugLogger.info(
          'Auth check complete: Status=$status, isAuthenticated=$isAuth');

      NavigationLogger.log(
        NavigationEventType.providerAccess,
        'GlobalAuthService initialization COMPLETED',
        data: {'status': status, 'isAuthenticated': isAuth},
      );

      _isInitialized = true;
    } catch (e) {
      DebugLogger.error('ERROR initializing GlobalAuthService', e);
      await createEmergencyAuthProvider();
    }
  }

  /// Creates an emergency auth provider when normal initialization fails
  Future<void> createEmergencyAuthProvider() async {
    try {
      DebugLogger.info('📢 Creating EMERGENCY AuthProvider');
      _authProvider = AuthProvider();
      _isEmergencyMode = true;

      // Also try to restore auth session in emergency mode
      await _authProvider?.checkAuthStatus();

      DebugLogger.info('✅ Emergency AuthProvider created successfully');
    } catch (e) {
      DebugLogger.error('💥 FATAL: Failed to create emergency AuthProvider', e);
      // At this point, there's not much else we can do
    }
  }

  /// Attempt to sign in with email and password
  Future<bool> signIn(String email, String password,
      {bool rememberMe = false}) async {
    try {
      if (_authProvider == null) {
        DebugLogger.error('Attempting to sign in with null auth provider');
        await createEmergencyAuthProvider();
      }

      final result =
          await _authProvider!.signIn(email, password, rememberMe: rememberMe);

      // Extra step to cache auth status in SharedPreferences for faster startup
      if (result && rememberMe) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('auth_user_cached', true);
          DebugLogger.info(
              '📝 Cached authentication status for faster startup');
        } catch (e) {
          DebugLogger.error('Failed to cache auth status', e);
        }
      }

      return _authProvider!.isAuthenticated;
    } catch (e) {
      DebugLogger.error('GlobalAuthService: Sign in failed', e);
      rethrow;
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      if (_authProvider == null) {
        DebugLogger.error('Attempting to sign out with null auth provider');
        await createEmergencyAuthProvider();
        return;
      }

      // Clear cached authentication status first
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('auth_user_cached', false);
        DebugLogger.info('📝 Cleared cached authentication status');
      } catch (e) {
        DebugLogger.error('Failed to clear cached auth status', e);
      }

      await _authProvider!.signOut();
    } catch (e) {
      DebugLogger.error('GlobalAuthService: Sign out failed', e);
      rethrow;
    }
  }

  /// Check if a user is already authenticated
  Future<bool> checkIfAuthenticated() async {
    // First check SharedPreferences for faster response
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedAuthStatus = prefs.getBool('auth_user_cached') ?? false;

      // If we have a cached status, return quickly for better UX
      if (cachedAuthStatus) {
        DebugLogger.info('Found cached authentication status: true');
      }
    } catch (e) {
      DebugLogger.error('Error checking cached auth status', e);
    }

    // Then do the full check with the auth provider
    if (_authProvider == null) {
      await initialize();
    }

    return isAuthenticated;
  }

  // Getters for auth status with null safety
  bool get isAuthenticated {
    if (_authProvider == null) {
      DebugLogger.error('Accessing isAuthenticated with null auth provider');
      return false;
    }

    final result = _authProvider!.isAuthenticated;
    DebugLogger.info('GlobalAuthService.isAuthenticated = $result');
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
          'CRITICAL: Accessing null _authProvider, creating emergency instance');
      createEmergencyAuthProvider();
    }

    DebugLogger.info('GlobalAuthService.authProvider accessed successfully');
    return _authProvider!;
  }
}
