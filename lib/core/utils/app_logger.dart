import 'package:flutter/foundation.dart';
import 'debug_logger.dart';

/// A wrapper class for logging that provides easy tag-based logging
class AppLogger {
  // Log error - DebugLogger.error expects only 2 args, not 3
  static void e(String tag, String message, [dynamic error, StackTrace? stack]) {
    final formattedMessage = '[$tag] $message';
    if (error != null) {
      // Combine error and stack into a single error message if needed
      final errorDetails = stack != null ? '$error\n$stack' : error;
      DebugLogger.error(formattedMessage, errorDetails);
    } else {
      DebugLogger.error(formattedMessage);
    }
  }

  // Log warning - DebugLogger.warning expects only 1 arg, not 2
  static void w(String tag, String message, [dynamic details]) {
    final formattedMessage = details != null ? '[$tag] $message: $details' : '[$tag] $message';
    DebugLogger.warning(formattedMessage);
  }

  // Log info
  static void i(String tag, String message) {
    final formattedMessage = '[$tag] $message';
    DebugLogger.info(formattedMessage);
  }

  // Log debug - Replace with info since debug doesn't exist in DebugLogger
  static void d(String tag, String message) {
    if (kDebugMode) {
      final formattedMessage = '[$tag] DEBUG: $message';
      DebugLogger.info(formattedMessage); // Use info instead of debug
    }
  }
}
