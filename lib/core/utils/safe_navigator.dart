
import 'package:flutter/material.dart';
import '../services/global_auth_service.dart';
import '../navigation/route_names.dart';
import '../../core/utils/debug_logger.dart';

/// Helper for safer navigation with auth checks
class SafeNavigator {
  // Navigate to a protected route that requires authentication
  static void navigateToProtectedRoute(BuildContext context, String routeName, {Object? arguments}) {
    final globalAuthService = GlobalAuthService();
    
    if (globalAuthService.isAuthenticated) {
      DebugLogger.route('Navigating to protected route: $routeName');
      Navigator.of(context).pushNamed(routeName, arguments: arguments);
    } else {
      DebugLogger.route('Redirecting to login (authentication required)');
      Navigator.of(context).pushReplacementNamed(RouteNames.login);
    }
  }
  
  // Replace current screen with a protected route
  static void replaceWithProtectedRoute(BuildContext context, String routeName, {Object? arguments}) {
    final globalAuthService = GlobalAuthService();
    
    if (globalAuthService.isAuthenticated) {
      DebugLogger.route('Replacing with protected route: $routeName');
      Navigator.of(context).pushReplacementNamed(routeName, arguments: arguments);
    } else {
      DebugLogger.route('Redirecting to login (authentication required)');
      Navigator.of(context).pushReplacementNamed(RouteNames.login);
    }
  }
  
  // Use this for navigation actions after auth operations
  static void navigateAfterAuth(BuildContext context, bool success) {
    if (success) {
      DebugLogger.route('Auth success, navigating to home');
      Navigator.of(context).pushReplacementNamed(RouteNames.home);
    } else {
      DebugLogger.route('Auth failed, staying on current page');
      // Stay on current page
    }
  }
}
