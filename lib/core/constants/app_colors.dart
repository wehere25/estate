import 'package:flutter/material.dart';

class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Primary colors from the HTML/CSS theme
  static const Color primaryColor = Color(0xFF2A9D8F); // Teal green
  static const Color secondaryColor = Color(0xFF264653); // Dark blue/slate
  static const Color accentColor = Color(0xFFE9C46A); // Yellow/gold accent
  static const Color lightColor = Color(0xFFF8F9FA); // Light background
  static const Color darkColor = Color(0xFF212529); // Dark text/background
  static const Color successColor = Color(0xFF43AA8B); // Success green
  static const Color dangerColor = Color(0xFFF94144); // Danger red
  static const Color grayColor = Color(0xFF6C757D); // Gray text
  static const Color lightGrayColor =
      Color(0xFFE9ECEF); // Light gray background

  // Light theme colors - Using the new color scheme
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primaryColor, // Teal green
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF3DAF9F), // Lighter shade of primary
    onPrimaryContainer: Colors.white,
    secondary: secondaryColor, // Dark blue/slate
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFF335566), // Lighter shade of secondary
    onSecondaryContainer: Colors.white,
    tertiary: accentColor, // Yellow/gold accent
    onTertiary: Colors.black,
    tertiaryContainer: Color(0xFFEFD48F), // Lighter shade of accent
    onTertiaryContainer: Colors.black,
    error: dangerColor, // Error red
    onError: Colors.white,
    errorContainer: Color(0xFFFFCDD2),
    onErrorContainer: Color(0xFF601010),
    background: lightColor, // Light background
    onBackground: darkColor, // Dark text
    surface: Colors.white,
    onSurface: darkColor,
    outline: grayColor, // Gray outline
    surfaceVariant: lightGrayColor, // Light gray for cards and surfaces
    onSurfaceVariant: grayColor,
  );

  // Dark theme colors - Green-based dark theme
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF45B4A5), // Lighter version of primary for dark theme
    onPrimary: Colors.black,
    primaryContainer: primaryColor,
    onPrimaryContainer: Colors.white,
    secondary: Color(0xFF4A6B7A), // Lighter version of secondary for dark theme
    onSecondary: Colors.white,
    secondaryContainer: secondaryColor,
    onSecondaryContainer: Colors.white,
    tertiary: accentColor, // Yellow/gold accent
    onTertiary: Colors.black,
    tertiaryContainer: Color(0xFFDDB84A), // Darker shade of accent
    onTertiaryContainer: Colors.white,
    error: Color(0xFFEF9A9A), // Lighter error red for dark theme
    onError: Colors.black,
    errorContainer: Color(0xFFB71C1C),
    onErrorContainer: Colors.white,
    background: Color(0xFF121212), // Dark background
    onBackground: Colors.white,
    surface: Color(0xFF1E1E1E), // Dark surface
    onSurface: Colors.white,
    outline: Color(0xFF757575),
    surfaceVariant: Color(0xFF303030),
    onSurfaceVariant: Color(0xFFE0E0E0),
  );

  // Common colors
  static const Color transparent = Colors.transparent;
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const Color grey = grayColor;
  static const Color lightGrey = lightGrayColor;
  static const Color darkGrey = Color(0xFF495057); // Slightly darker gray

  // Status colors
  static const Color success = successColor;
  static const Color warning = accentColor; // Using accent as warning
  static const Color info = primaryColor;
  static const Color error = dangerColor;

  // Additional aliases for text colors
  static const Color text = darkColor;
  static const Color textLight = grayColor;
  static const Color surfaceDark = Color(0xFF121212);

  // Legacy name for backward compatibility
  static const Color primaryLight = lightGrayColor;
}
