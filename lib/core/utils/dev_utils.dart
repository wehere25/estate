import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Add this import for Widget, Banner, BannerLocation and Color

/// Utility class for development-only features
class DevUtils {
  // Private constructor to prevent instantiation
  DevUtils._();

  /// Whether the app is running in development mode
  static const bool isDev = false; // Force production mode to fix issues

  /// Alias for isDev (for more readable code)
  static bool get isDevMode => isDev;

  /// Whether to bypass Firebase Auth for testing
  /// Set this to true during development to bypass actual authentication
  static const bool bypassAuth = false; // Set to false for production mode

  /// Production admin access mode - enable all admin features in production mode
  static const bool adminFeaturesForcedEnabled = true;

  /// Fake user ID for development
  static const String devUserId = 'dev-user-123';

  /// Fake user email for development
  static const String devUserEmail = 'dev@example.com';

  /// Use placeholder images for development instead of real Firebase Storage URLs
  static const bool useMockImages = false; // Set to false to use actual images

  // Known admin emails for when App Check or Cloud Functions fail
  static final List<String> knownAdminEmails = [
    // Add your actual admin emails here
    'admin@example.com',
    'darsuplex141@gmail.com', // Replace with your email
    'trashbin2605@gmail.com', // Replace with another admin email if needed
  ];

  /// Convert a Firebase Storage URL to a mock image URL if in dev mode
  static String getMockImageUrl(String? originalUrl) {
    // If originalUrl is null or empty, return a default placeholder
    if (originalUrl == null || originalUrl.isEmpty) {
      return 'https://via.placeholder.com/800x600?text=No+Image';
    }

    // Always return the original URL if it's from Firebase Storage or a local file
    if (originalUrl.contains('firebasestorage.googleapis.com') ||
        originalUrl.startsWith('file://')) {
      return originalUrl;
    }

    // If this is already a real URL (not a Firebase Storage URL), return it as-is
    if (originalUrl.startsWith('https://images.unsplash.com/') ||
        originalUrl.startsWith('https://picsum.photos/')) {
      return originalUrl;
    }

    // If it's a dev mode URL, convert it to a placeholder only if useMockImages is true
    if (isDev &&
        useMockImages &&
        (originalUrl.contains('firebasestorage.example.com') ||
            originalUrl.contains('dev-mode'))) {
      // Return a placeholder image from Unsplash or Lorem Picsum
      // Derive a consistent image from the original URL hash to maintain consistency
      final imageId = originalUrl.hashCode.abs() % 1000;
      return 'https://picsum.photos/seed/$imageId/800/600';
    }

    // Otherwise return the original URL
    return originalUrl;
  }

  /// Logs a development message with a distinct prefix
  static void log(String message) {
    if (isDev) {
      debugPrint('🛠️ DEV: $message');
    }
  }

  /// Shows a development banner if in dev mode
  static Widget devBanner(Widget child) {
    if (!isDev) return child;

    return Banner(
      message: 'DEV',
      location: BannerLocation.topEnd,
      color: const Color(0xFFFFA000),
      child: child,
    );
  }

  /// Check if email is a recognized admin email
  static bool isAdminEmail(String? email) {
    if (email == null) return false;
    return knownAdminEmails.contains(email);
  }
}
