import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../../features/auth/domain/providers/auth_provider.dart';
import '../../features/auth/domain/services/admin_service.dart';
import '../../core/utils/debug_logger.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/property/presentation/screens/property_detail_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/landing_screen.dart';
import '../../features/auth/presentation/wrappers/auth_wrapper.dart';
import '../../features/property/presentation/screens/property_map_screen.dart';
import '../../features/admin/presentation/screens/property_upload_screen.dart';

class AppNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _barHeightAnimation;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _barHeightAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();

    // Schedule admin check after the first frame renders to avoid build issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdminStatus(context);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Check if the user is admin - improved implementation with more reliable auth checks
  void _checkAdminStatus(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        DebugLogger.info(
            'Checking admin status for user: ${authProvider.user?.uid}');
        bool isAdmin = await AdminService.isUserAdmin(authProvider.user!);

        // Only update state if the admin status actually changed
        if (isAdmin != _isAdmin && mounted) {
          setState(() {
            _isAdmin = isAdmin;
          });
          DebugLogger.info('Admin status updated: $_isAdmin');
        }
      } else {
        // Reset admin status if no user is logged in
        if (_isAdmin && mounted) {
          setState(() {
            _isAdmin = false;
          });
        }
      }
    } catch (e) {
      DebugLogger.error('Error checking admin status', e);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check admin status on dependencies change (like user authentication state)
    _checkAdminStatus(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Listen for auth changes and update admin status if needed
        if (authProvider.user != null) {
          _isAdmin = AdminService.isUserAdmin(authProvider.user);
        } else {
          _isAdmin = false;
        }

        DebugLogger.info('Navigation bar building with isAdmin: $_isAdmin');

        // Define navigation items based on admin status
        final List<BottomNavigationBarItem> navItems = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          if (_isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle),
              label: 'Post',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border_outlined),
            activeIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 56 * (1 - _barHeightAnimation.value)),
              child: BottomNavigationBar(
                items: navItems,
                currentIndex: _getAdjustedIndex(widget.currentIndex, _isAdmin),
                onTap: (index) =>
                    widget.onTap(_convertIndexForNavigation(index, _isAdmin)),
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Theme.of(context).colorScheme.primary,
                unselectedItemColor: Colors.grey,
                showUnselectedLabels: true,
                elevation: 8,
              ),
            );
          },
        );
      },
    );
  }

  // Helper to adjust the index based on admin status
  int _getAdjustedIndex(int index, bool isAdmin) {
    // For display purposes - converts the app index to navbar index
    if (!isAdmin && index >= 2) {
      return index - 1;
    }
    return index;
  }

  // Helper to convert tapped index to navigation index
  int _convertIndexForNavigation(int tappedIndex, bool isAdmin) {
    // For navigation purposes - converts the navbar index to app index
    if (!isAdmin && tappedIndex >= 2) {
      return tappedIndex + 1;
    }
    return tappedIndex;
  }
}

/// Scaffold with integrated navigation support
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
    // We need to detect if we're on a main navigation route
    // to avoid showing duplicate navigation bars
    final String currentPath = GoRouterState.of(context).uri.path;
    final List<String> mainNavigationRoutes = [
      '/', // Add root path to main routes
      '/home',
      '/search',
      '/favorites',
      '/profile',
      '/property/upload',
      '/notifications'
    ];

    // If we're on a main route and showNavBar is true, this could cause duplication
    // The shell route navigation should handle these routes
    final bool shouldDeferToShellNavigation =
        mainNavigationRoutes.contains(currentPath);

    // Log for debugging navigation issues
    DebugLogger.info('AppNavigation - Path: $currentPath, ' +
        'ShouldDefer: $shouldDeferToShellNavigation, ' +
        'ShowNavBar: $showNavBar');

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text(title),
              actions: actions,
            )
          : null,
      body: body,
      floatingActionButton: floatingActionButton,
      // Only add navigation when not deferring to shell navigation
      bottomNavigationBar: null, // Always set to null to avoid duplication
    );
  }
}
