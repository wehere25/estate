import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/debug_logger.dart';

/// Provides secure storage functionality for sensitive data
/// like authentication tokens and credentials
class SecureStorageService {
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _authPersistenceKey = 'auth_persistence_enabled';
  static const String _lastRefreshKey = 'auth_last_token_refresh';
  static const String _authUserCachedKey = 'auth_user_cached';
  static const String _authProviderKey = 'auth_provider';
  static const String _emailVerificationKey = 'email_verification_required';
  static const String _pendingVerificationEmailKey =
      'pending_verification_email';

  // Create secure storage with AES encryption for Android
  // For iOS, it uses the Keychain
  final _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
  ));

  // Singleton instance
  static final SecureStorageService _instance =
      SecureStorageService._internal();

  // Factory constructor
  factory SecureStorageService() => _instance;

  // Private constructor
  SecureStorageService._internal();

  /// Saves an authentication token securely
  Future<void> saveAuthToken(String token) async {
    try {
      await _storage.write(key: _authTokenKey, value: token);
    } catch (e) {
      DebugLogger.error('Failed to save auth token', e);
      rethrow;
    }
  }

  /// Gets the authentication token
  Future<String?> getAuthToken() async {
    try {
      return await _storage.read(key: _authTokenKey);
    } catch (e) {
      DebugLogger.error('Failed to retrieve auth token', e);
      return null;
    }
  }

  /// Saves the refresh token securely
  Future<void> saveRefreshToken(String refreshToken) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (e) {
      DebugLogger.error('Failed to save refresh token', e);
      rethrow;
    }
  }

  /// Gets the refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      DebugLogger.error('Failed to retrieve refresh token', e);
      return null;
    }
  }

  /// Saves the user ID securely
  Future<void> saveUserId(String userId) async {
    try {
      await _storage.write(key: _userIdKey, value: userId);
    } catch (e) {
      DebugLogger.error('Failed to save user ID', e);
      rethrow;
    }
  }

  /// Gets the user ID
  Future<String?> getUserId() async {
    try {
      return await _storage.read(key: _userIdKey);
    } catch (e) {
      DebugLogger.error('Failed to retrieve user ID', e);
      return null;
    }
  }

  /// Saves the authentication persistence preference
  Future<void> savePersistencePreference(bool enabled) async {
    try {
      await _storage.write(key: _authPersistenceKey, value: enabled.toString());
    } catch (e) {
      DebugLogger.error('Failed to save persistence preference', e);
      rethrow;
    }
  }

  /// Gets the authentication persistence preference
  Future<bool> getPersistencePreference() async {
    try {
      final value = await _storage.read(key: _authPersistenceKey);
      return value == 'true';
    } catch (e) {
      DebugLogger.error('Failed to get persistence preference', e);
      return false;
    }
  }

  /// Saves the last token refresh timestamp
  Future<void> saveLastRefreshTimestamp(int timestamp) async {
    try {
      await _storage.write(key: _lastRefreshKey, value: timestamp.toString());
    } catch (e) {
      DebugLogger.error('Failed to save last refresh timestamp', e);
      rethrow;
    }
  }

  /// Gets the last token refresh timestamp
  Future<int?> getLastRefreshTimestamp() async {
    try {
      final value = await _storage.read(key: _lastRefreshKey);
      return value != null ? int.parse(value) : null;
    } catch (e) {
      DebugLogger.error('Failed to get last refresh timestamp', e);
      return null;
    }
  }

  /// Saves the authentication cached status
  Future<void> saveCachedAuthStatus(bool isCached) async {
    try {
      await _storage.write(key: _authUserCachedKey, value: isCached.toString());
    } catch (e) {
      DebugLogger.error('Failed to save cached auth status', e);
      rethrow;
    }
  }

  /// Gets the authentication cached status
  Future<bool> getCachedAuthStatus() async {
    try {
      final value = await _storage.read(key: _authUserCachedKey);
      return value == 'true';
    } catch (e) {
      DebugLogger.error('Failed to get cached auth status', e);
      return false;
    }
  }

  /// Saves the authentication provider (email, google, etc.)
  Future<void> saveAuthProvider(String provider) async {
    try {
      await _storage.write(key: _authProviderKey, value: provider);
    } catch (e) {
      DebugLogger.error('Failed to save auth provider', e);
      rethrow;
    }
  }

  /// Gets the authentication provider
  Future<String?> getAuthProvider() async {
    try {
      return await _storage.read(key: _authProviderKey);
    } catch (e) {
      DebugLogger.error('Failed to get auth provider', e);
      return null;
    }
  }

  /// Saves email verification required status
  Future<void> saveEmailVerificationRequired(bool required) async {
    try {
      await _storage.write(
          key: _emailVerificationKey, value: required.toString());
    } catch (e) {
      DebugLogger.error('Failed to save email verification status', e);
      rethrow;
    }
  }

  /// Gets email verification required status
  Future<bool> getEmailVerificationRequired() async {
    try {
      final value = await _storage.read(key: _emailVerificationKey);
      return value == 'true';
    } catch (e) {
      DebugLogger.error('Failed to get email verification status', e);
      return false;
    }
  }

  /// Saves pending verification email
  Future<void> savePendingVerificationEmail(String email) async {
    try {
      await _storage.write(key: _pendingVerificationEmailKey, value: email);
    } catch (e) {
      DebugLogger.error('Failed to save pending verification email', e);
      rethrow;
    }
  }

  /// Gets pending verification email
  Future<String?> getPendingVerificationEmail() async {
    try {
      return await _storage.read(key: _pendingVerificationEmailKey);
    } catch (e) {
      DebugLogger.error('Failed to get pending verification email', e);
      return null;
    }
  }

  /// Clear all sensitive authentication data
  Future<void> clearAuthData() async {
    try {
      await _storage.delete(key: _authTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _userIdKey);
      await _storage.delete(key: _lastRefreshKey);
      await _storage.delete(key: _authUserCachedKey);
      await _storage.delete(key: _emailVerificationKey);
      await _storage.delete(key: _pendingVerificationEmailKey);
      // Don't clear persistence preference as that's a user setting
    } catch (e) {
      DebugLogger.error('Failed to clear auth data', e);
      rethrow;
    }
  }
}
