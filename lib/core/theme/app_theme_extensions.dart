import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color cardBgColor;
  final Color statusBarColor;
  final Color searchBarBgColor;
  final Color headerGradientStart;
  final Color headerGradientEnd;

  const AppThemeExtension({
    required this.cardBgColor,
    required this.statusBarColor,
    required this.searchBarBgColor,
    required this.headerGradientStart,
    required this.headerGradientEnd,
  });

  @override
  AppThemeExtension copyWith({
    Color? cardBgColor,
    Color? statusBarColor,
    Color? searchBarBgColor,
    Color? headerGradientStart,
    Color? headerGradientEnd,
  }) {
    return AppThemeExtension(
      cardBgColor: cardBgColor ?? this.cardBgColor,
      statusBarColor: statusBarColor ?? this.statusBarColor,
      searchBarBgColor: searchBarBgColor ?? this.searchBarBgColor,
      headerGradientStart: headerGradientStart ?? this.headerGradientStart,
      headerGradientEnd: headerGradientEnd ?? this.headerGradientEnd,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) {
      return this;
    }

    return AppThemeExtension(
      cardBgColor: Color.lerp(cardBgColor, other.cardBgColor, t)!,
      statusBarColor: Color.lerp(statusBarColor, other.statusBarColor, t)!,
      searchBarBgColor:
          Color.lerp(searchBarBgColor, other.searchBarBgColor, t)!,
      headerGradientStart:
          Color.lerp(headerGradientStart, other.headerGradientStart, t)!,
      headerGradientEnd:
          Color.lerp(headerGradientEnd, other.headerGradientEnd, t)!,
    );
  }

  // Light theme extensions - using the EstateHub HTML theme colors
  static const light = AppThemeExtension(
    cardBgColor: Colors.white,
    statusBarColor: AppColors.secondaryColor, // Dark blue/slate status bar
    searchBarBgColor: Colors.white,
    headerGradientStart: AppColors.primaryColor, // Teal green start
    headerGradientEnd: AppColors.secondaryColor, // Dark blue/slate end
  );

  // Dark theme extensions
  static const dark = AppThemeExtension(
    cardBgColor: Color(0xFF1E1E1E),
    statusBarColor: Color(0xFF121212),
    searchBarBgColor: Color(0xFF2C2C2C),
    headerGradientStart: Color(0xFF45B4A5), // Lighter primary for dark theme
    headerGradientEnd: Color(0xFF1E353E), // Lighter secondary for dark theme
  );
}
