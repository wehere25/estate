import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import '../config/firebase_options.dart'; // Updated import path
import 'firebase_auth_config.dart';

/// Firebase initialization and configuration utilities
class FirebaseConfig {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Initialize Firebase App Check with debug provider
      await FirebaseAppCheck.instance.activate(
        // Use debug provider for development
        androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        // Use AppleProvider for iOS
        appleProvider: AppleProvider.deviceCheck,
      );
      
      // Configure Firebase Auth specifically
      await FirebaseAuthConfig.configure();
      
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      rethrow;
    }
  }
}
