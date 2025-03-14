import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/utils/debug_logger.dart';

class UserProfileService {
  static const _keyPrefix = 'user_profile_';
  static const _keyName = '${_keyPrefix}name';
  static const _keyEmail = '${_keyPrefix}email';
  
  // Save user profile data using SharedPreferences as a backup
  static Future<void> saveUserProfile(User user, {String? name}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save the user ID as key for lookup
      await prefs.setString('${_keyPrefix}${user.uid}_name', name ?? user.displayName ?? 'User');
      await prefs.setString('${_keyPrefix}${user.uid}_email', user.email ?? 'No Email');
      await prefs.setString('${_keyPrefix}${user.uid}_created_at', DateTime.now().toIso8601String());
      
      // Also save as current user for easy access
      await prefs.setString(_keyName, name ?? user.displayName ?? 'User');
      await prefs.setString(_keyEmail, user.email ?? 'No Email');
      
      DebugLogger.info('Saved user profile to SharedPreferences: ${user.uid}');
    } catch (e) {
      DebugLogger.error('Error saving user profile', e);
    }
  }
  
  // Get profile info for the current user
  static Future<Map<String, String>> getCurrentUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        return {
          'name': 'Guest User',
          'email': 'Not Signed In',
          'created_at': DateTime.now().toIso8601String(),
        };
      }
      
      // Try to get user-specific data first
      String name = prefs.getString('${_keyPrefix}${user.uid}_name') ?? 
                   prefs.getString(_keyName) ?? 
                   user.displayName ?? 
                   'User';
                   
      String email = prefs.getString('${_keyPrefix}${user.uid}_email') ?? 
                    prefs.getString(_keyEmail) ?? 
                    user.email ?? 
                    'No Email';
      
      String createdAt = prefs.getString('${_keyPrefix}${user.uid}_created_at') ?? 
                        DateTime.now().toIso8601String();
      
      return {
        'name': name,
        'email': email,
        'created_at': createdAt,
      };
    } catch (e) {
      DebugLogger.error('Error getting user profile', e);
      return {
        'name': 'User',
        'email': 'Error loading profile',
        'created_at': DateTime.now().toIso8601String(),
      };
    }
  }
  
  // Update the current user's profile
  static Future<void> updateProfile({String? name, String? email}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        DebugLogger.error('Attempted to update profile with no signed-in user');
        return;
      }
      
      // Update Firebase profile if possible
      try {
        if (name != null) {
          await user.updateDisplayName(name);
        }
        if (email != null && email != user.email) {
          await user.updateEmail(email);
        }
      } catch (e) {
        DebugLogger.error('Error updating Firebase profile, falling back to local storage', e);
      }
      
      // Always update local storage as backup
      if (name != null) {
        await prefs.setString('${_keyPrefix}${user.uid}_name', name);
        await prefs.setString(_keyName, name);
      }
      
      if (email != null) {
        await prefs.setString('${_keyPrefix}${user.uid}_email', email);
        await prefs.setString(_keyEmail, email);
      }
      
      DebugLogger.info('Updated user profile: ${user.uid}');
    } catch (e) {
      DebugLogger.error('Error updating user profile', e);
    }
  }
}
