import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/domain/providers/auth_provider.dart';
import '../../features/auth/domain/services/admin_service.dart';
import '../utils/debug_logger.dart';
import 'app_bottom_nav.dart';

/// App scaffold that properly handles navigation bars to prevent duplication
class AppScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final bool showAppBar;
  final bool showNavBar;
  final int currentIndex;
  final Function(int)? onNavigationChanged;
  final List<Widget>? actions;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final PreferredSizeWidget? customAppBar;
  final Widget? leading;

  const AppScaffold({
    Key? key,
    required this.body,
    this.title,
    this.showAppBar = true,
    this.showNavBar = true,
    this.currentIndex = 0,
    this.onNavigationChanged,
    this.actions,
    this.drawer,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.customAppBar,
    this.leading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // IMPORTANT: Always disable bottom navigation in this scaffold
    // This prevents duplicate navigation bars completely
    // Navigation is handled by the shell route in app_router.dart

    // Get current route for debugging
    final currentRoute = ModalRoute.of(context)?.settings.name ?? 'unknown';

    // Debug info for tracking scaffold builds
    DebugLogger.info(
        'NAVBAR DEBUG: AppScaffold building for path: $currentRoute, ' +
            'showNavBar: $showNavBar, currentIndex: $currentIndex');

    return Scaffold(
      backgroundColor:
          backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      appBar: showAppBar
          ? customAppBar ??
              AppBar(
                title: Text(title ?? ''),
                actions: actions,
                leading: leading,
              )
          : null,
      drawer: drawer,
      body: body,
      bottomNavigationBar: showNavBar
          ? Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final isAuthenticated = authProvider.isAuthenticated;
                final isCheckingAuth = authProvider.isCheckingAuth;

                // Log bottom navbar visibility in AppScaffold
                DebugLogger.info(
                    'NAVBAR DEBUG: AppScaffold rendering bottomNav - ' +
                        'path: $currentRoute, showNavBar: $showNavBar, ' +
                        'isAuthenticated: $isAuthenticated, ' +
                        'isCheckingAuth: $isCheckingAuth');

                // Always return the bottom navigation bar unless explicitly hidden
                return AppBottomNav(
                  currentIndex: currentIndex,
                  onTap: onNavigationChanged ?? (int _) {},
                );
              },
            )
          : null,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}
