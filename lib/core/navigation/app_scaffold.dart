import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/domain/providers/auth_provider.dart';
import '../../features/auth/domain/services/admin_service.dart';
import '../utils/debug_logger.dart';

/// App scaffold that properly handles navigation bars to prevent duplication
class AppScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final int currentIndex;
  final List<Widget>? actions;
  final bool showAppBar;
  final bool showNavBar;
  final FloatingActionButton? floatingActionButton;

  const AppScaffold({
    Key? key,
    required this.body,
    this.title = '',
    this.currentIndex = 0,
    this.actions,
    this.showAppBar = true,
    this.showNavBar = true,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // IMPORTANT: Always disable bottom navigation in this scaffold
    // This prevents duplicate navigation bars completely
    // Navigation is handled by the shell route in app_router.dart

    // Log the current state for debugging
    final String currentPath = GoRouterState.of(context).uri.path;
    DebugLogger.info('AppScaffold building for path: $currentPath');

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text(title),
              actions: actions,
            )
          : null,
      body: body,
      floatingActionButton: floatingActionButton,
      // Always set to null - bottom navigation is handled by router shell
      bottomNavigationBar: null,
    );
  }
}
