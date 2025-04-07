import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../utils/debug_logger.dart';
import '../../features/auth/domain/providers/auth_provider.dart';
import '../../features/auth/domain/services/admin_service.dart';

class AppBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    // Debug log to track when AppBottomNav is initialized
    DebugLogger.info(
        'NAVBAR DEBUG: AppBottomNav initialized with index: ${widget.currentIndex}');
  }

  @override
  void didUpdateWidget(AppBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Debug log to track when AppBottomNav updates
    if (oldWidget.currentIndex != widget.currentIndex) {
      DebugLogger.info(
          'NAVBAR DEBUG: AppBottomNav updated - index changed from ${oldWidget.currentIndex} to ${widget.currentIndex}');
    }
  }

  @override
  void dispose() {
    // Debug log when AppBottomNav is disposed
    DebugLogger.info('NAVBAR DEBUG: AppBottomNav disposed');
    super.dispose();
  }

  // Check if the user is admin
  void _checkAdminStatus(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      // Use synchronous check for UI decisions
      final isAdmin = AdminService.isUserAdmin(authProvider.user);
      if (isAdmin != _isAdmin) {
        setState(() {
          _isAdmin = isAdmin;
        });
        // Log admin status change
        DebugLogger.info('NAVBAR DEBUG: Admin status changed to: $isAdmin');
      }

      // Also start async check for accurate role determination
      AdminService.checkFirestoreAdmin(authProvider.user!.uid)
          .then((bool result) {
        if (result != _isAdmin && mounted) {
          setState(() {
            _isAdmin = result;
          });
          // Log admin status update from Firestore
          DebugLogger.info(
              'NAVBAR DEBUG: Admin status updated from Firestore to: $result');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check admin status on each build to ensure it's current
    _checkAdminStatus(context);

    // Get current route for debugging
    final currentPath = GoRouterState.of(context).uri.path;

    // Log every build of the navigation bar
    DebugLogger.info(
        'NAVBAR DEBUG: AppBottomNav building for path: $currentPath, ' +
            'index: ${widget.currentIndex}, isAdmin: $_isAdmin');

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Get admin status
        final bool isAdmin = _isAdmin;
        final bool isAuthenticated = authProvider.isAuthenticated;
        final userId = authProvider.user?.uid ?? 'guest';

        // Define navigation items based on admin status
        final List<NavigationDestination> navItems = [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          if (isAdmin)
            const NavigationDestination(
              icon: Icon(Icons.add_circle_outline),
              selectedIcon: Icon(Icons.add_circle),
              label: 'Post',
            ),
          const NavigationDestination(
            icon: Icon(Icons.favorite_border_outlined),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];

        // Adjust index based on admin status
        final adjustedIndex = _getAdjustedIndex(widget.currentIndex, isAdmin);

        // Log bottom nav rendering with detailed state
        DebugLogger.info('NAVBAR DEBUG: Rendering NavigationBar - ' +
            'path: $currentPath, selectedIndex: $adjustedIndex, ' +
            'items: ${navItems.length}, ' +
            'isAdmin: $isAdmin, userId: $userId, ' +
            'isAuthenticated: $isAuthenticated');

        // Animated builder for the nav bar
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 1.0, end: 0.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              // Slide up animation
              offset: Offset(0, 80 * value),
              child: child,
            );
          },
          child: NavigationBar(
            selectedIndex: adjustedIndex,
            destinations: navItems,
            onDestinationSelected: (index) {
              // Log navigation selection with detailed info
              DebugLogger.info('NAVBAR DEBUG: Navigation selected - ' +
                  'tapped index: $index, ' +
                  'converted index: ${_convertIndexForNavigation(index, isAdmin)}, ' +
                  'isAdmin: $isAdmin, path: $currentPath');

              widget.onTap(_convertIndexForNavigation(index, isAdmin));
            },
          ),
        );
      },
    );
  }

  // Helper to adjust the index based on admin status
  int _getAdjustedIndex(int index, bool isAdmin) {
    // For display purposes - converts the app index to navbar index
    // Correct index mapping for non-admin users
    if (!isAdmin) {
      // Map app indices to navbar indices correctly
      switch (index) {
        case 0:
          return 0; // Home -> Home
        case 1:
          return 1; // Search -> Search
        case 2:
          return 2; // Favorites -> Favorites
        case 3:
          return 3; // Profile -> Profile
        default:
          return 0; // Default to home for safety
      }
    }
    return index; // For admin users, use the index as is
  }

  // Helper to convert tapped index to navigation index
  int _convertIndexForNavigation(int tappedIndex, bool isAdmin) {
    // For navigation purposes - converts the navbar index to app index
    if (!isAdmin) {
      // For non-admin users:
      // Maintain consistent mapping between navbar and app indices
      switch (tappedIndex) {
        case 0:
          return 0; // Home
        case 1:
          return 1; // Search
        case 2:
          return 2; // Favorites
        case 3:
          return 3; // Profile
        default:
          return 0; // Default to home
      }
    }
    return tappedIndex; // For admin users, use the index as is
  }
}
