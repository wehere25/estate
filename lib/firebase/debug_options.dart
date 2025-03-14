// This file provides a debug configuration for Firebase App Check
// Use this file only during development

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

class FirebaseDebugConfig {
  /// Get a debug token for FirebaseAppCheck during development
  static Future<void> setupDebugToken() async {
    if (kDebugMode) {
      // Set debug token to bypass Firebase App Check in development
      // In production, this should never be used
      try {
        // Initialize App Check with debug provider
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        );
        
        // Set debug token manually if needed
        // FirebaseAppCheck.instance.setAppCheckDebugToken('YOUR-DEBUG-TOKEN');
        
        debugPrint('DEBUG: Firebase App Check debug mode activated');
      } catch (e) {
        debugPrint('ERROR: Failed to set Firebase App Check debug token: $e');
      }
    }
  }
}
