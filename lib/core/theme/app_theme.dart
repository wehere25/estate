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
        ),
      ),
    ),

    // Text Button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
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

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    useMaterial3: true,
    primaryColor: AppColors.primaryColor,
    scaffoldBackgroundColor: AppColors.surfaceDark,
    colorScheme: AppColors.darkColorScheme,

    // AppBar theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.secondaryColor,
      elevation: 0,
      iconTheme: const IconThemeData(
        color: Colors.white,
        size: 26,
      ),
    ),

    // Card theme
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shadowColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    ),

    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    // Input decoration theme for dark mode
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
          color: AppColors.darkColorScheme.primary,
          width: 2,
        ),
      ),
      prefixIconColor: AppColors.darkColorScheme.primary,
      hintStyle: TextStyle(color: AppColors.grayColor),
    ),

    // Icon theme
    iconTheme: IconThemeData(
      color: AppColors.darkColorScheme.primary,
      size: 24,
    ),

    // Bottom navigation bar theme for dark mode
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1A1A1A),
      selectedItemColor: AppColors.primaryColor,
      unselectedItemColor: AppColors.grayColor,
      selectedIconTheme: IconThemeData(
        size: 28,
        color: AppColors.primaryColor,
      ),
      unselectedIconTheme: IconThemeData(
        size: 24,
        color: AppColors.grayColor,
      ),
    ),

    // Floating action button theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
    ),

    // Switch theme for dark mode
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.darkColorScheme.primary;
        }
        return Colors.grey;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.darkColorScheme.primary.withOpacity(0.5);
        }
        return Colors.grey.withOpacity(0.3);
      }),
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
