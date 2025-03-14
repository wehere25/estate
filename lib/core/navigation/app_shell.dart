import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/domain/providers/auth_provider.dart';
import '../../features/auth/domain/services/admin_service.dart';
import '../utils/debug_logger.dart';

class AppShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({Key? key, required this.navigationShell}) : super(key: key);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  void _checkAdminStatus() {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        // Use synchronous method for immediate UI decisions
        final isAdmin = AdminService.isUserAdmin(authProvider.user);
        if (isAdmin != _isAdmin && mounted) {
          setState(() {
            _isAdmin = isAdmin;
          });
        }

        // Also start async check for accurate role determination
        AdminService.checkFirestoreAdmin(authProvider.user!.uid)
            .then((bool result) {
          if (result != _isAdmin && mounted) {
            setState(() {
              _isAdmin = result;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error checking admin status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    _checkAdminStatus(); // Keep admin status updated

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final userId = authProvider.user?.uid ?? 'guest';

          // Use the state variable for consistent UI decisions
          final bool isAdmin = _isAdmin;

          final List<NavigationDestination> destinations = [
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

          return NavigationBar(
            selectedIndex: widget.navigationShell.currentIndex,
            destinations: destinations,
            onDestinationSelected: (index) {
              final currentRoute = GoRouterState.of(context).uri.path;
              String targetRoute;
              String tabName;

              if (index == 0) {
                targetRoute = '/home';
                tabName = 'Home';
              } else if (index == 1) {
                targetRoute = '/search';
                tabName = 'Search';
              } else if (index == 2) {
                if (isAdmin) {
                  targetRoute = '/property/upload';
                  tabName = 'Post';
                } else {
                  targetRoute = '/favorites';
                  tabName = 'Favorites';
                }
              } else if (index == 3) {
                if (isAdmin) {
                  targetRoute = '/favorites';
                  tabName = 'Favorites';
                } else {
                  targetRoute = '/profile';
                  tabName = 'Profile';
                }
              } else if (index == 4) {
                if (isAdmin) {
                  targetRoute = '/profile';
                  tabName = 'Profile';
                } else {
                  targetRoute = '/home';
                  tabName = 'Home';
                }
              } else {
                targetRoute = '/home';
                tabName = 'Home';
              }

              DebugLogger.navClick(currentRoute, targetRoute, params: {
                'tabIndex': index,
                'tabName': tabName,
                'isAdmin': isAdmin,
                'userId': userId
              });

              widget.navigationShell.goBranch(
                index,
                initialLocation: index == widget.navigationShell.currentIndex,
              );
            },
          );
        },
      ),
    );
  }
}
