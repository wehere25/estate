import 'package:flutter/material.dart';
import 'route_names.dart';

/// Service for centralized navigation handling
class NavigationService {
  // Singleton pattern
  NavigationService._internal();
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  
  // Navigation key for accessing navigator without context
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  /// Navigate to a named route
  Future<T?> navigateTo<T>(String routeName, {Object? arguments}) async {
    if (navigatorKey.currentState == null) {
      debugPrint('Navigator state is null. Cannot navigate to $routeName');
      return null;
    }
    
    return navigatorKey.currentState!.pushNamed<T>(routeName, arguments: arguments);
  }
  
  /// Replace the current route
  Future<T?> replaceTo<T>(String routeName, {Object? arguments}) async {
    if (navigatorKey.currentState == null) return null;
    
    return navigatorKey.currentState!.pushReplacementNamed<T, dynamic>(
      routeName, 
      arguments: arguments
    );
  }
  
  /// Pop to a specific route
  void popUntil(String routeName) {
    if (navigatorKey.currentState == null) return;
    
    navigatorKey.currentState!.popUntil(
      (route) => route.settings.name == routeName
    );
  }
  
  /// Pop the current route
  void goBack<T>({T? result}) {
    if (navigatorKey.currentState == null) return;
    
    navigatorKey.currentState!.pop<T>(result);
  }
  
  /// Clear the navigation stack and replace with a new route
  Future<T?> navigateAndRemoveUntil<T>(String routeName, {Object? arguments}) async {
    if (navigatorKey.currentState == null) return null;
    
    return navigatorKey.currentState!.pushNamedAndRemoveUntil<T>(
      routeName, 
      (route) => false, 
      arguments: arguments
    );
  }

  // Add a helper method specifically for the property upload page
  Future<dynamic> navigateToPropertyUpload({bool isAdmin = false, dynamic propertyToEdit}) {
    debugPrint('🧭 NavigationService: Navigating to property upload screen');
    return navigatorKey.currentState!.pushNamed(
      '/property/upload',
      arguments: {
        'isAdminMode': isAdmin,
        if (propertyToEdit != null) 'propertyToEdit': propertyToEdit,
      },
    );
  }
}
