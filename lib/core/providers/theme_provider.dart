import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../constants/app_colors.dart';
import '../utils/debug_logger.dart';

class ThemeProvider with ChangeNotifier {
  // Key for storing theme preference
  static const String _themePreferenceKey = 'theme_preference';
  
  // Theme state
  bool _isDarkMode = false;
  
  // Get current theme state
  bool get isDarkMode => _isDarkMode;
  
  // Get current theme mode
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  
  // Constructor - load saved theme preference
  ThemeProvider() {
    _loadThemePreference();
  }
  
  // Load saved theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themePreferenceKey) ?? false;
      notifyListeners();
    } catch (e) {
      DebugLogger.error('Error loading theme preference', e);
    }
  }
  
  // Save theme preference to SharedPreferences
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themePreferenceKey, _isDarkMode);
    } catch (e) {
      DebugLogger.error('Error saving theme preference', e);
    }
  }
  
  // Toggle theme
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _saveThemePreference();
    notifyListeners();
  }
  
  // Set specific theme
  Future<void> setDarkMode(bool isDarkMode) async {
    if (_isDarkMode != isDarkMode) {
      _isDarkMode = isDarkMode;
      await _saveThemePreference();
      notifyListeners();
    }
  }
  
  // Add the missing getTheme() method that returns the appropriate ThemeData
  ThemeData getTheme() {
    return _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
  }
}
