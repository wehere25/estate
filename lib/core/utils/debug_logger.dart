import 'package:flutter/foundation.dart';

class DebugLogger {
  // Generic info logs
  static void info(String message) {
    if (kDebugMode) {
      print('ℹ️ INFO: $message');
    }
  }

  // Error logs
  static void error(String message, [dynamic error]) {
    if (kDebugMode) {
      print('❌ ERROR: $message');
      if (error != null) print(error);
    }
  }

  // Enhanced user interaction logs with detailed information
  static void click(
    String component,
    String action, {
    Map<String, dynamic>? data,
    String? screen,
    String? source,
    String? target,
    String? userId,
  }) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toString();
      final dataString = data != null ? '\n    Data: $data' : '';
      final screenInfo = screen != null ? '\n    Screen: $screen' : '';
      final sourceInfo = source != null ? '\n    Source: $source' : '';
      final targetInfo = target != null ? '\n    Target: $target' : '';
      final userInfo = userId != null ? '\n    User: $userId' : '';

      print(
          '👆 CLICK [${timestamp.split('.')[0]}]: $component - $action$screenInfo$sourceInfo$targetInfo$userInfo$dataString');
    }
  }

  // Track navigation events with click context
  static void navClick(String source, String destination,
      {Map<String, dynamic>? params}) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toString();
      final paramsInfo = params != null ? '\n    Params: $params' : '';

      print(
          '🧭 NAV CLICK [${timestamp.split('.')[0]}]: $source → $destination$paramsInfo');
    }
  }

  // Authentication related logs
  static void auth(String message) {
    if (kDebugMode) {
      print('🔐 AUTH: $message');
    }
  }

  // Provider/State management logs
  static void provider(String message) {
    if (kDebugMode) {
      print('🔄 PROVIDER: $message');
    }
  }

  // Navigation logs
  static void route(String message) {
    if (kDebugMode) {
      print('🧭 NAV: $message');
    }
  }

  // API/Network logs
  static void api(String method, String endpoint, [dynamic data]) {
    if (kDebugMode) {
      print('🌐 API: $method $endpoint');
      if (data != null) print('📦 Data: $data');
    }
  }

  // Add warning method to fix undefined method errors
  static void warning(String message) {
    if (kDebugMode) {
      print('⚠️ WARNING: $message');
    }
  }

  // Keep warn as alias for warning for compatibility
  static void warn(String message) => warning(message);

  // Track UI events beyond clicks (like long press, hover, etc)
  static void uiEvent(String eventType, String component,
      {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toString();
      final dataString = data != null ? '\n    Data: $data' : '';

      print(
          '🖱️ UI EVENT [${timestamp.split('.')[0]}]: $eventType on $component$dataString');
    }
  }
}
