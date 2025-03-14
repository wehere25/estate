import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/debug_logger.dart';

class FirebaseInitializer {
  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      await _initializeAppCheck();
    } catch (e) {
      DebugLogger.error('Error initializing Firebase', e);
      rethrow;
    }
  }

  static Future<void> _initializeAppCheck() async {
    try {
      // Wait a moment for Firebase to fully initialize
      await Future.delayed(const Duration(milliseconds: 500));

      if (kDebugMode) {
        DebugLogger.info('Initializing App Check in debug mode');
        // Activate debug provider with debug token
        await FirebaseAppCheck.instance.activate(
          webProvider: ReCaptchaV3Provider('dummy-key'),
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        );
      } else {
        DebugLogger.info('Initializing App Check in production mode');
        // Use production providers
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.playIntegrity,
          appleProvider: AppleProvider.appAttest,
        );
      }

      // Add retry logic for token refresh
      FirebaseAppCheck.instance.onTokenChange.listen((token) {
        DebugLogger.info('App Check token refreshed');
      }, onError: (error) {
        DebugLogger.error('Error refreshing App Check token', error);
        // Retry token refresh after delay
        Future.delayed(const Duration(seconds: 5), () {
          FirebaseAppCheck.instance.getToken(true);
        });
      });
    } catch (e) {
      if (kDebugMode) {
        // In debug mode, just log the error but don't throw
        DebugLogger.warning(
            'App Check initialization failed (non-critical): $e');
      } else {
        DebugLogger.error('Error initializing App Check', e);
        rethrow;
      }
    }
  }
}
