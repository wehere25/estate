import 'package:flutter/foundation.dart';

class AppLogger {
  static void d(String tag, String message) {
    if (kDebugMode) {
      print('DEBUG [$tag]: $message');
    }
  }

  static void e(String tag, String message, [dynamic error]) {
    if (kDebugMode) {
      print('ERROR [$tag]: $message');
      if (error != null) print(error);
    }
  }

  static void i(String tag, String message) {
    if (kDebugMode) {
      print('INFO [$tag]: $message');
    }
  }

  static void w(String tag, String message, [dynamic error]) {
    if (kDebugMode) {
      print('WARNING [$tag]: $message');
      if (error != null) {
        print(error);
      }
    }
  }
}
