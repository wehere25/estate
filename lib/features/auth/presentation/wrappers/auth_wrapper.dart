import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/providers/auth_provider.dart';
import '../../domain/enums/auth_status.dart'; // Add this import for AuthStatus
import '../screens/landing_screen.dart';
import '../screens/login_screen.dart';
import '/features/main/screens/main_container_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('AuthWrapper: Building...');
    
    final authProvider = Provider.of<AuthProvider>(context);
    
    switch (authProvider.status) {
      case AuthStatus.authenticated:
        return const MainContainerScreen();
      case AuthStatus.unauthenticated:
        return const LandingScreen(); // Show landing page instead of login directly
      case AuthStatus.error:
        return const LandingScreen(); // Show landing on error too
      default:
        return const LandingScreen(); // Default to landing
    }
  }
}
