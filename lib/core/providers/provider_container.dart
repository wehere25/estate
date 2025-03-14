
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/domain/providers/auth_provider.dart';

/// A global singleton container for providers
/// This allows us to access providers outside the widget tree
class ProviderContainer {
  static final ProviderContainer _instance = ProviderContainer._internal();
  factory ProviderContainer() => _instance;
  ProviderContainer._internal();

  // Store our provider instances here
  AuthProvider? _authProvider;

  // Initialize providers
  void initialize() {
    _authProvider = AuthProvider();
  }

  // Get the auth provider singleton
  AuthProvider get authProvider {
    if (_authProvider == null) {
      initialize();
    }
    return _authProvider!;
  }

  // Wrap a widget with all necessary providers
  Widget wrapWithProviders(Widget child) {
    // Ensure providers are initialized
    if (_authProvider == null) {
      initialize();
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        // Add more providers here if needed
      ],
      child: child,
    );
  }
}
