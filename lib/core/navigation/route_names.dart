/// Centralized route names for the application
/// 
/// This class provides static constants for all named routes in the application
/// to prevent hardcoding strings throughout the codebase.
class RouteNames {
  // Private constructor to prevent instantiation
  RouteNames._();
  
  // Public/Auth routes
  static const String root = '/';         // Points to landing
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String resetPassword = '/reset-password';
  static const String landing = '/landing';
  
  // Main app routes
  static const String home = '/home';
  static const String search = '/search';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String favorites = '/favorites';
  
  // Property routes
  static const String propertyDetail = '/property/:id';
  static const String propertyCreate = '/property/create';
  static const String propertyEdit = '/property/:id/edit';
  static const String propertyUpload = '/property-upload';
  
  // Admin routes
  static const String adminDashboard = '/admin';
  static const String adminProperties = '/admin/properties';
  static const String adminUsers = '/admin/users';
  static const String adminAnalytics = '/admin/analytics';
}
