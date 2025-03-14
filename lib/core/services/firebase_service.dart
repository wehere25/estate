import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '/core/config/firebase_options.dart';
import '/core/exceptions/app_exceptions.dart';

/// Service class to handle Firebase initialization and provide better error handling
class FirebaseService {
  // Singleton instance
  static final FirebaseService _instance = FirebaseService._internal();
  
  // Private flag to track initialization status
  bool _isInitialized = false;
  
  // Factory constructor to return the singleton instance
  factory FirebaseService() => _instance;
  
  // Private constructor for singleton pattern
  FirebaseService._internal();
  
  // Getter for initialization status
  bool get isInitialized => _isInitialized;
  
  /// Initialize Firebase with better error handling
  Future<void> initializeFirebase() async {
    if (_isInitialized) {
      debugPrint('Firebase is already initialized');
      return;
    }
    
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
      debugPrint('Firebase initialized successfully');
    } catch (e, stackTrace) {
      final message = 'Error initializing Firebase: $e';
      debugPrint(message);
      throw AppException(message, originalException: e);
    }
  }
  
  /// Reset service (mainly for testing)
  void reset() {
    _isInitialized = false;
  }
}
