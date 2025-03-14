import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

enum ThemeOption { light, dark, system }

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  ThemeMode _themeMode = ThemeMode.light;
  late SharedPreferences _prefs;
  
  // Add a variable to track the current theme option
  ThemeOption _themeOption = ThemeOption.light;
  
  ThemeProvider() {
    _loadThemePreference();
  }
  
  // Getters
  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _themeMode;
  ThemeData get themeData => _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
  
  // Add the missing themeOption getter
  ThemeOption get themeOption => _themeOption;
  
  // Load saved theme preference
  Future<void> _loadThemePreference() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final savedTheme = _prefs.getString('theme_preference') ?? 'light';
      
      // Set theme based on saved preference
      if (savedTheme == 'dark') {
        _isDarkMode = true;
        _themeMode = ThemeMode.dark;
        _themeOption = ThemeOption.dark;
      } else if (savedTheme == 'system') {
        _themeMode = ThemeMode.system;
        _themeOption = ThemeOption.system;
        // For system mode, we determine dark/light based on platform brightness
        final platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        _isDarkMode = platformBrightness == Brightness.dark;
      } else {
        _isDarkMode = false;
        _themeMode = ThemeMode.light;
        _themeOption = ThemeOption.light;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }
  
  // Set theme mode
  Future<void> setTheme(ThemeOption themeOption) async {
    try {
      _themeOption = themeOption; // Update the current theme option
      
      switch (themeOption) {
        case ThemeOption.dark:
          _isDarkMode = true;
          _themeMode = ThemeMode.dark;
          await _prefs.setString('theme_preference', 'dark');
          break;
        case ThemeOption.light:
          _isDarkMode = false;
          _themeMode = ThemeMode.light;
          await _prefs.setString('theme_preference', 'light');
          break;
        case ThemeOption.system:
          _themeMode = ThemeMode.system;
          // For system mode, we determine dark/light based on platform brightness
          final platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
          _isDarkMode = platformBrightness == Brightness.dark;
          await _prefs.setString('theme_preference', 'system');
          break;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting theme: $e');
    }
  }
  
  // Toggle between light and dark mode
  Future<void> toggleTheme() async {
    try {
      _isDarkMode = !_isDarkMode;
      _themeMode = _isDarkMode ? ThemeMode.dark : ThemeMode.light;
      _themeOption = _isDarkMode ? ThemeOption.dark : ThemeOption.light;
      await _prefs.setString('theme_preference', _isDarkMode ? 'dark' : 'light');
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling theme: $e');
    }
  }
}

