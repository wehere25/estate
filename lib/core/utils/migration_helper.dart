
import 'dart:io';

/// Helper class to update imports across the project
class MigrationHelper {
  /// Maps old import paths to new ones
  static final Map<String, String> importMap = {
    // Auth imports
    'auth/providers/auth_provider.dart': 'features/auth/domain/providers/auth_provider.dart',
    'auth/screens/login_screen.dart': 'features/auth/presentation/screens/login_screen.dart',
    
    // Navigation imports
    'core/navigation/route_names.dart': 'core/navigation/route_names.dart', // Same location
    
    // Service imports
    'services/auth_service.dart': 'core/services/global_auth_service.dart',
    'services/firebase_service.dart': 'core/services/firebase_service.dart',
    
    // Util imports
    'utils/debug_logger.dart': 'core/utils/debug_logger.dart',
    
    // Feature imports
    'home/home_screen.dart': 'features/home/presentation/screens/home_screen.dart',
    'property/property_detail.dart': 'features/property/presentation/screens/property_detail_screen.dart',
  };

  /// Updates imports in a file
  static void updateImports(String filePath) {
    if (!File(filePath).existsSync()) return;
    
    try {
      final content = File(filePath).readAsStringSync();
      var updatedContent = content;
      
      importMap.forEach((oldPath, newPath) {
        updatedContent = updatedContent.replaceAll(
          "import '$oldPath'", 
          "import '$newPath'"
        );
      });
      
      if (content != updatedContent) {
        File(filePath).writeAsStringSync(updatedContent);
        print('Updated imports in $filePath');
      }
    } catch (e) {
      print('Error updating $filePath: $e');
    }
  }
}
