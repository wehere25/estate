
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:azharapp/features/home/presentation/screens/home_screen.dart';

/// Auth status enum to track authentication state
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  authenticating,
  error,
}

/// Combines authentication provider and wrapper functionality
class AuthProvider extends ChangeNotifier {
  // Private variables
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  
  // Constructor
  AuthProvider() {
    checkAuthStatus();
  }
  
  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  
  Future<void> signIn(String email, String password, [BuildContext? context]) async {
    _setStatus(AuthStatus.authenticating);
    try {
      // Implementation will be added later
      await Future.delayed(const Duration(seconds: 1)); // Simulate auth delay
      _setStatus(AuthStatus.authenticated);
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(AuthStatus.error);
    }
  }
  
  Future<void> signUp(String email, String password, [dynamic context]) async {
    // Implementation will be added later
    _setStatus(AuthStatus.authenticated);
  }
  
  Future<void> signOut() async {
    try {
      // Implementation will be added later
      _setStatus(AuthStatus.unauthenticated);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Error during sign out: $_errorMessage");
    }
  }

  Future<AuthStatus> checkAuthStatus() async {
    _status = AuthStatus.authenticated; // For development only
    notifyListeners();
    return _status;
  }
  
  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }
  
  // Auth wrapper functionality incorporated as a widget getter
  Widget get authWrapper {
    switch (_status) {
      case AuthStatus.authenticated:
        return const HomeScreen();
      case AuthStatus.unauthenticated:
        // Will return LoginScreen in the future
        return const HomeScreen(); // For development
      default:
        return const HomeScreen(); // For development
    }
  }
}
