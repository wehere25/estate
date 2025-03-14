import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Provides convenient aliases for the app's color scheme
/// Based on EstateHub theme with primary teal (#2A9D8F) and secondary slate (#264653)
class ColorAlias {
  // Private constructor to prevent instantiation
  ColorAlias._();

  // Primary color variants
  static const Color teal = AppColors.primaryColor;
  static const Color darkSlate = AppColors.secondaryColor;
  static const Color accent = AppColors.accentColor;
  static const Color lightBg = AppColors.lightColor;

  // Gradients using our primary colors
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primaryColor,
      AppColors.secondaryColor,
    ],
  );

  static const LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.lightGrayColor,
      Color(0xFFDDDDDD), // Slightly darker light gray
    ],
  );

  // Common UI element colors using our theme
  static const Color buttonColor = AppColors.primaryColor;
  static const Color activeIconColor = AppColors.primaryColor;
  static const Color inactiveIconColor = AppColors.grayColor;

  // Background colors
  static const Color profileBackgroundColor = AppColors.lightGrayColor;
  static const Color cardBackgroundColor = Colors.white;
  static const Color pageBackgroundColor = AppColors.lightColor;

  // Status colors
  static const Color successColor = AppColors.successColor;
  static const Color infoColor = AppColors.primaryColor;
  static const Color warningColor = AppColors.accentColor;
  static const Color errorColor = AppColors.dangerColor;

  // Accent colors that complement primary/secondary
  static const Color accent1 = Color(0xFF3DAF9F); // Lighter teal
  static const Color accent2 = Color(0xFF335566); // Lighter slate
  static const Color accent3 = AppColors.accentColor; // Yellow accent

  // Opacity variants of primary color
  static Color tealWithOpacity(double opacity) =>
      AppColors.primaryColor.withOpacity(opacity);
  static const Color tealOverlay = Color(0x202A9D8F); // Teal with 20% opacity

  // Helper methods for common color use cases
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
      case 'completed':
        return successColor;
      case 'pending':
      case 'in review':
        return warningColor;
      case 'rejected':
      case 'cancelled':
      case 'failed':
        return errorColor;
      default:
        return infoColor;
    }
  }
}
