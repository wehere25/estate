import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'app_theme_extensions.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: AppColors.primaryColor,
    scaffoldBackgroundColor: AppColors.lightColor,
    colorScheme: AppColors.lightColorScheme,

    // AppBar theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      shadowColor: AppColors.primaryColor.withOpacity(0.5),
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(
        color: Colors.white,
        size: 26,
      ),
    ),

    // Card theme
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    ),

    // Elevated Button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          inherit: true, // Add this to fix TextStyle interpolation errors
        ),
      ),
    ),

    // Text Button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            inherit: true, // Add this to fix TextStyle interpolation errors
          )),
    ),

    // Outlined Button theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryColor,
        side: BorderSide(color: AppColors.primaryColor),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    // Bottom Navigation bar theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primaryColor,
      unselectedItemColor: AppColors.grayColor,
      selectedIconTheme: const IconThemeData(
        size: 28,
        color: AppColors.primaryColor,
      ),
      unselectedIconTheme: IconThemeData(
        size: 24,
        color: AppColors.grayColor,
      ),
      selectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      elevation: 8,
    ),

    // Floating Action Button theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Input Decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightGrayColor.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.primaryColor,
          width: 2,
        ),
      ),
      prefixIconColor: AppColors.primaryColor,
      suffixIconColor: AppColors.grayColor,
      hintStyle: TextStyle(
        color: AppColors.grayColor,
        fontSize: 16,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    // Icon theme
    iconTheme: const IconThemeData(
      color: AppColors.primaryColor,
      size: 24,
    ),

    // Text theme
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 32,
        color: AppColors.darkColor,
      ),
      displayMedium: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 28,
        color: AppColors.darkColor,
      ),
      displaySmall: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 24,
        color: AppColors.darkColor,
      ),
      headlineLarge: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 20,
        color: AppColors.darkColor,
      ),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: AppColors.darkColor,
      ),
      headlineSmall: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: AppColors.darkColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppColors.darkColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.darkColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: AppColors.grayColor,
      ),
    ),

    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.lightGrayColor,
      disabledColor: Colors.grey[300],
      selectedColor: AppColors.primaryColor.withOpacity(0.2),
      secondarySelectedColor: AppColors.primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: TextStyle(color: AppColors.darkColor),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Divider theme
    dividerTheme: DividerThemeData(
      color: AppColors.lightGrayColor,
      thickness: 1,
      space: 24,
    ),

    // Checkbox theme
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primaryColor;
        }
        return Colors.transparent;
      }),
      checkColor: MaterialStateProperty.all(Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),

    // Switch theme
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primaryColor;
        }
        return AppColors.grayColor;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primaryColor.withOpacity(0.5);
        }
        return AppColors.lightGrayColor;
      }),
    ),

    // Slider theme
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.primaryColor,
      thumbColor: AppColors.primaryColor,
      overlayColor: AppColors.primaryColor.withOpacity(0.2),
      inactiveTrackColor: AppColors.lightGrayColor,
    ),

    // Tab theme
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.primaryColor,
      unselectedLabelColor: AppColors.grayColor,
      indicatorColor: AppColors.primaryColor,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),

    extensions: [
      AppThemeExtension.light,
    ],
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    primaryColor: Colors.blue[400],
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: ColorScheme.dark(
      primary: Colors.blue[400]!,
      secondary: Colors.blueGrey[300]!,
      surface: const Color(0xFF1E1E1E),
      background: const Color(0xFF121212),
      error: Colors.red[400]!,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.black,
    ),

    // AppBar theme for dark mode
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 2,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      iconTheme: IconThemeData(
        color: Colors.white,
        size: 26,
      ),
    ),

    // Card theme for dark mode
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    ),

    // Bottom Navigation bar theme for dark mode - this fixes the invisible navbar
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF1E1E1E), // Dark background
      selectedItemColor: Colors.blue[400], // Blue for selected items
      unselectedItemColor: Colors.grey[400], // Light grey for unselected
      selectedIconTheme: IconThemeData(
        size: 28,
        color: Colors.blue[400],
      ),
      unselectedIconTheme: IconThemeData(
        size: 24,
        color: Colors.grey[400],
      ),
      selectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      elevation: 8,
    ),

    // Elevated Button theme for dark mode
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[400],
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          inherit: true, // Fix for TextStyle interpolation issues
        ),
      ),
    ),

    // Text Button theme for dark mode
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.blue[300],
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          inherit: true, // Fix for TextStyle interpolation issues
        ),
      ),
    ),

    // Outlined Button theme for dark mode
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue[300],
        side: BorderSide(color: Colors.blue[400]!),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    // Floating Action Button theme for dark mode
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.blue[400],
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Input Decoration theme for dark mode
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.blue[400]!,
          width: 2,
        ),
      ),
      prefixIconColor: Colors.blue[400],
      suffixIconColor: Colors.grey[400],
      hintStyle: TextStyle(
        color: Colors.grey[500],
        fontSize: 16,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    // Icon theme for dark mode
    iconTheme: IconThemeData(
      color: Colors.grey[300],
      size: 24,
    ),

    // Text theme for dark mode
    textTheme: TextTheme(
      displayLarge: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 32,
        color: Colors.white,
      ),
      displayMedium: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 28,
        color: Colors.white,
      ),
      displaySmall: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 24,
        color: Colors.white,
      ),
      headlineLarge: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 20,
        color: Colors.white,
      ),
      headlineMedium: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: Colors.white,
      ),
      headlineSmall: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: Colors.white,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        color: Colors.white,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: Colors.grey[400],
      ),
    ),

    // Chip theme for dark mode
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF2A2A2A),
      disabledColor: Colors.grey[700],
      selectedColor: Colors.blue[700],
      secondarySelectedColor: Colors.blue[400],
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: const TextStyle(color: Colors.white),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Divider theme for dark mode
    dividerTheme: const DividerThemeData(
      color: Colors.white24,
      thickness: 1,
      space: 24,
    ),

    // Checkbox theme for dark mode
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.blue[400]!;
        }
        return Colors.grey[800]!;
      }),
      checkColor: MaterialStateProperty.all(Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),

    // Switch theme for dark mode
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.blue[400];
        }
        return Colors.grey[400];
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.blue.withOpacity(0.5);
        }
        return Colors.grey[700];
      }),
    ),

    // Slider theme for dark mode
    sliderTheme: SliderThemeData(
      activeTrackColor: Colors.blue[400],
      thumbColor: Colors.blue[400],
      overlayColor: Colors.blue.withOpacity(0.2),
      inactiveTrackColor: Colors.grey[800],
    ),

    // Tab theme for dark mode
    tabBarTheme: TabBarThemeData(
      labelColor: Colors.blue[400],
      unselectedLabelColor: Colors.grey[400],
      indicatorColor: Colors.blue[400],
      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),

    extensions: [
      AppThemeExtension.dark,
    ],
  );
}

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color? customColor1;
  final Color? customColor2;
  final Color? profileBackground;
  final Color? cardBackground;

  const AppThemeExtension({
    required this.customColor1,
    required this.customColor2,
    required this.profileBackground,
    required this.cardBackground,
  });

  static const light = AppThemeExtension(
    customColor1: AppColors.primaryColor,
    customColor2: AppColors.primaryLight,
    profileBackground: AppColors.primaryLight,
    cardBackground: Colors.white,
  );

  static const dark = AppThemeExtension(
    customColor1: Color(0xFF4CCEAB),
    customColor2: Color(0xFF007A5E),
    profileBackground: Color(0xFF1E3B34),
    cardBackground: Color(0xFF1E1E1E),
  );

  @override
  ThemeExtension<AppThemeExtension> copyWith({
    Color? customColor1,
    Color? customColor2,
    Color? profileBackground,
    Color? cardBackground,
  }) {
    return AppThemeExtension(
      customColor1: customColor1 ?? this.customColor1,
      customColor2: customColor2 ?? this.customColor2,
      profileBackground: profileBackground ?? this.profileBackground,
      cardBackground: cardBackground ?? this.cardBackground,
    );
  }

  @override
  ThemeExtension<AppThemeExtension> lerp(
    covariant ThemeExtension<AppThemeExtension>? other,
    double t,
  ) {
    if (other is! AppThemeExtension) {
      return this;
    }
    return AppThemeExtension(
      customColor1: Color.lerp(customColor1, other.customColor1, t),
      customColor2: Color.lerp(customColor2, other.customColor2, t),
      profileBackground:
          Color.lerp(profileBackground, other.profileBackground, t),
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t),
    );
  }
}
