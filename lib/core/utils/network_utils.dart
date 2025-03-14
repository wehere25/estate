import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'debug_logger.dart';
import 'app_logger.dart'; // Fixed import path

/// Utility class to handle network related operations
class NetworkUtils {
  static const String _tag = 'NetworkUtils';
  static final Connectivity _connectivity = Connectivity();

  /// Check if device is connected to the internet
  static Future<bool> isConnected() async {
    try {
      // Get connectivity status
      final result = await _connectivity.checkConnectivity();
      
      // Check if we have any connection
      if (result == ConnectivityResult.none) {
        return false;
      }
      
      // Test actual internet connection by pinging Google
      final response = await http.get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.e(_tag, 'Error checking internet connection', e);
      return false;
    }
  }

  /// Stream of connectivity changes
  static Stream<ConnectivityResult> get connectivityChanges => 
      _connectivity.onConnectivityChanged;

  /// Get current connection type as string
  static Future<String> getConnectionType() async {
    final result = await _connectivity.checkConnectivity();
    switch (result) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
        return 'No Connection';
      // Removed redundant default case that was causing the warning
    }
  }
  
  /// Retry a function with exponential backoff
  static Future<T> retryWithBackoff<T>({
    required Future<T> Function() function,
    required int maxRetries,
    Duration initialBackoff = const Duration(milliseconds: 500),
  }) async {
    var currentRetry = 0;
    var backoff = initialBackoff;
    
    while (true) {
      try {
        return await function();
      } catch (e) {
        currentRetry++;
        if (currentRetry >= maxRetries) {
          rethrow;
        }
        
        AppLogger.w(_tag, 'Operation failed, retrying in ${backoff.inMilliseconds}ms', e);
        await Future.delayed(backoff);
        
        // Exponential backoff: double the wait time
        backoff *= 2;
      }
    }
  }
}
