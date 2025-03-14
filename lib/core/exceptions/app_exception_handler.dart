import 'package:flutter/foundation.dart';

/// Centralized exception handler for the application
class AppExceptionHandler {
  // Private constructor
  AppExceptionHandler._();
  
  /// Handle exceptions globally
  static void handleException(dynamic exception, StackTrace? stackTrace) {
    // Log the exception
    debugPrint('Exception: $exception');
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }
    
    // Here you would add error reporting like Firebase Crashlytics
    // FirebaseCrashlytics.instance.recordError(exception, stackTrace);
  }
}
