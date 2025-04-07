import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../domain/providers/auth_provider.dart';
import '../../domain/enums/auth_status.dart';
import '../screens/login_screen.dart';
import '../../../../features/home/presentation/screens/home_screen.dart';
import '../../../../core/utils/debug_logger.dart';
import '../../../../core/navigation/app_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper widget that directs users based on authentication status
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _cachedAuth = false;

  @override
  void initState() {
    super.initState();
    _loadCachedAuth();
  }

  Future<void> _loadCachedAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedAuth = prefs.getBool('auth_user_cached') ?? false;

      if (mounted) {
        setState(() {
          _cachedAuth = cachedAuth;
        });
      }
    } catch (e) {
      DebugLogger.error('Failed to load cached auth', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Redirect to proper shell route if we have cached auth
    if (_cachedAuth) {
      DebugLogger.info(
          'NAVBAR DEBUG: AuthWrapper using cached auth - redirecting to /home shell route');

      // Use a post-frame callback to avoid build-time navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/home');
      });

      // Show a loading indicator while redirecting
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Consumer<AuthProvider>(
      builder: (ctx, authProvider, _) {
        final authStatus = authProvider.status;

        // Log detailed debug info for authentication state
        DebugLogger.info('NAVBAR DEBUG: AuthWrapper - ' +
            'authStatus: $authStatus, ' +
            'isCheckingAuth: ${authProvider.isCheckingAuth}, ' +
            'isAuthenticated: ${authProvider.isAuthenticated}, ' +
            'usingCachedAuth: ${authProvider.usingCachedAuth}');

        // If still checking auth but we have a cached status, redirect to home
        if (authProvider.isCheckingAuth) {
          DebugLogger.info(
              'NAVBAR DEBUG: AuthWrapper - still checking auth, redirecting to /home');

          // Use a post-frame callback to avoid build-time navigation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/home');
          });

          // Show a loading indicator while redirecting
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If authenticated, redirect to home
        if (authStatus == AuthStatus.authenticated) {
          DebugLogger.info(
              'NAVBAR DEBUG: AuthWrapper - authenticated, redirecting to /home');

          // Use a post-frame callback to avoid build-time navigation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/home');
          });

          // Show a loading indicator while redirecting
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Only show LoginScreen when definitely not authenticated
        DebugLogger.info(
            'NAVBAR DEBUG: AuthWrapper - definitely not authenticated, showing LoginScreen');
        return const LoginScreen();
      },
    );
  }
}
