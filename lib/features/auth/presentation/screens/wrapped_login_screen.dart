
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/providers/auth_provider.dart';
import '../../../../core/utils/debug_logger.dart';
import 'login_screen.dart';

class WrappedLoginScreen extends StatelessWidget {
  const WrappedLoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create a local auth provider just for this screen
    return ChangeNotifierProvider(
      create: (_) {
        final provider = AuthProvider();
        DebugLogger.provider('Created local AuthProvider in WrappedLoginScreen');
        return provider;
      },
      child: Builder(
        builder: (context) {
          // Verify provider is available
          try {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            DebugLogger.provider('AuthProvider is available in WrappedLoginScreen');
          } catch (e) {
            DebugLogger.error('AuthProvider NOT available in WrappedLoginScreen', e);
          }
          
          return const LoginScreen();
        },
      ),
    );
  }
}
