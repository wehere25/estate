import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// Admin imports
import '../../features/admin/presentation/wrappers/admin_wrapper.dart';

// Auth imports
import '../../features/auth/domain/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/landing_screen.dart';
import '../../features/auth/presentation/wrappers/auth_wrapper.dart';

// Feature imports
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/property/presentation/screens/property_detail_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/admin/presentation/screens/property_upload_screen.dart';
import '../../features/dev/screens/navigation_diagnostic_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/my_properties_screen.dart';
import '../../features/profile/presentation/screens/history_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/profile/presentation/screens/support_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/manage_users_screen.dart';
import '../../features/admin/presentation/screens/manage_properties_screen.dart';
import '../../features/admin/presentation/screens/analytics_screen.dart';
import '../../features/admin/presentation/screens/property_edit_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';

// Utils
import '../../core/utils/debug_logger.dart';
import '../utils/navigation_logger.dart';
import '../../features/auth/domain/services/admin_service.dart';

class AppRouter {
  // Private constructor to prevent instantiation
  AppRouter._();

  /// Get the GoRouter configuration for the app
  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  // Change how router is managed to prevent multiple initializations
  static GoRouter? _router;

  /// Get the router instance, initializing it if necessary
  static GoRouter getRouter(BuildContext context) {
    // Only create router if it doesn't exist yet
    _router ??= createRouter(context);
    return _router!;
  }

  /// Create and configure the router
  static GoRouter createRouter(BuildContext context) {
    // Get the auth provider for access control
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Define the routes once at the top level
    final publicRoutes = [
      '/', // Landing page
      '/landing', // Explicit landing route
      '/login',
      '/register',
      '/reset-password',
    ];

    final userRoutes = [
      '/home',
      '/search',
      '/favorites',
      '/profile',
      '/profile/edit',
      '/profile/properties',
      '/profile/history',
      '/profile/settings',
      '/profile/support',
      '/notifications',
    ];

    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/',
      debugLogDiagnostics: true, // Enable debug logs in development

      // Error handling for routes not found
      errorBuilder: (context, state) {
        DebugLogger.error(
            'Navigation error', 'Route not found: ${state.uri.path}');
        return Scaffold(
          appBar: AppBar(title: const Text('Page Not Found')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Page not found!',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 16),
                Text('Attempted route: ${state.uri.path}'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Go to Home'),
                ),
              ],
            ),
          ),
        );
      },

      // Global redirect function for access control
      redirect: (context, state) {
        DebugLogger.route('Redirecting from: ${state.uri.path}');

        // If on root path, redirect authenticated users directly to home with proper navigation
        if (state.uri.path == '/') {
          if (authProvider.isAuthenticated) {
            DebugLogger.navClick('/', '/home',
                params: {'reason': 'root_redirect', 'auth': 'true'});
            return '/home';
          }
          return null; // Don't redirect unauthenticated users from splash screen
        }

        // If already authenticated and trying to access other public routes
        if (authProvider.isAuthenticated &&
            (publicRoutes.contains(state.uri.path) && state.uri.path != '/')) {
          return '/home';
        }

        // Allow access to public routes
        if (publicRoutes.contains(state.uri.path)) {
          return null;
        }

        // Rest of your existing redirect logic...
        // Skip redirect logic for splash screen to ensure it always shows
        if (state.uri.path == '/') {
          return null; // Don't redirect from splash screen
        }

        // Log navigation events
        NavigationLogger.log(
          NavigationEventType.routeChange,
          'GoRouter redirect triggered',
          data: {
            'path': state.uri.path,
            'isAuthenticated': authProvider.isAuthenticated
          },
        );

        // Path being navigated to
        final path = state.uri.path;

        // Check if the user is authenticated
        final isAuthenticated = authProvider.isAuthenticated;

        // Use AdminService for admin checks - use synchronous method for UI decisions
        final isAdmin =
            isAuthenticated && AdminService.isUserAdmin(authProvider.user);

        // Developer-only routes are only available in debug mode with specific auth
        final isDeveloper = kDebugMode && isAdmin;

        // Check if path starts with a specific pattern
        bool pathStartsWith(String prefix) => path.startsWith(prefix);

        // ADMIN ROUTES CHECK
        if (pathStartsWith('/admin/') ||
            pathStartsWith('/property/add') ||
            pathStartsWith('/property/edit/') ||
            pathStartsWith('/property/upload')) {
          // If attempting to access admin routes without admin privileges
          if (!isAdmin) {
            DebugLogger.warn(
                'Non-admin user attempted to access admin route: $path');
            return isAuthenticated ? '/home' : '/login';
          }
          return null; // Allow access for admins
        }

        // DEVELOPER ROUTES CHECK
        if (pathStartsWith('/dev/')) {
          // Only allow developer routes in debug mode with developer role
          if (!isDeveloper) {
            DebugLogger.warning(
                'Non-developer tried to access dev route: $path');
            return '/home';
          }
          return null; // Allow access for developers
        }

        // PROPERTY DETAIL ROUTES - Special handling for property detail routes
        if (pathStartsWith('/property/') &&
            !pathStartsWith('/property/add') &&
            !pathStartsWith('/property/edit/')) {
          // If trying to view property details without authentication
          if (!isAuthenticated) {
            final redirectPath = path;
            DebugLogger.info('Storing redirect path: $redirectPath');
            // Store path locally until authentication
            return '/login?redirect=$redirectPath';
          }
          return null; // Allow access to property details for authenticated users
        }

        // USER ROUTES CHECK - Require authentication for user routes
        if (userRoutes.contains(path) ||
            userRoutes.any((route) => pathStartsWith("$route/"))) {
          if (!isAuthenticated) {
            final redirectPath = path;
            DebugLogger.info('Storing redirect path: $redirectPath');
            // Store path locally until authentication
            return '/login?redirect=$redirectPath';
          }
          return null; // Allow access for authenticated users
        }

        // PUBLIC ROUTES - Always accessible
        if (publicRoutes.contains(path)) {
          // If user is already authenticated and trying to access login/register
          if (isAuthenticated &&
              (path == '/login' || path == '/register' || path == '/')) {
            return '/home';
          }
          return null; // Allow access to public routes
        }

        // For all other routes, no redirect needed
        return null;
      },

      // Define all routes
      routes: [
        // PUBLIC AUTHENTICATION ROUTES
        GoRoute(
          path: '/',
          name: 'splash',
          builder: (context, state) => const AuthWrapper(),
          // Initial loading screen; checks authentication status and redirects accordingly
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
          // User/Admin login screen with email/password or Google Sign-In
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
          // New user registration form with email verification
        ),
        GoRoute(
          path: '/reset-password',
          name: 'resetPassword',
          builder: (context, state) => const ResetPasswordScreen(),
          // Allows users to reset forgotten passwords via email link
        ),
        GoRoute(
          path: '/landing',
          name: 'landing',
          builder: (context, state) => const LandingScreen(),
          // Introductory page showcasing featured properties before login
        ),

        // AUTHENTICATED USER ROUTES - Main App Routes
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomeScreen(showNavBar: true),
          // Main page displaying property listings with search/filter options
        ),
        GoRoute(
          path: '/search',
          name: 'search',
          builder: (context, state) {
            // Extract query parameter if available
            final query = state.uri.queryParameters['q'];
            return SearchScreen(initialQuery: query, showNavBar: true);
          },
          // Dedicated search page with advanced filtering options
        ),
        GoRoute(
          path: '/favorites',
          name: 'favorites',
          builder: (context, state) => const FavoritesScreen(showNavBar: true),
          // Lists properties saved by the user for quick access later
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(showNavBar: true),
          // User profile overview page showing personal details and settings access
        ),

        // AUTHENTICATED USER ROUTES
        GoRoute(
          path: '/profile/edit',
          name: 'profileEdit',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/profile/properties',
          name: 'myProperties',
          builder: (context, state) => const MyPropertiesScreen(),
        ),
        GoRoute(
          path: '/profile/history',
          name: 'history',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: '/profile/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/profile/support',
          name: 'support',
          builder: (context, state) => const SupportScreen(),
        ),

        // PROPERTY MANAGEMENT ROUTES
        GoRoute(
          path: '/property/:id',
          name: 'propertyDetail',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return PropertyDetailScreen(propertyId: id);
          },
          // Detailed view of a specific property listing (Authenticated Users)
        ),

        // ADMIN-ONLY PROPERTY MANAGEMENT ROUTES
        GoRoute(
          path: '/property/add',
          name: 'propertyAdd',
          builder: (context, state) => AdminWrapper(
            child: const PropertyUploadScreen(),
          ),
          // Form for adding new properties (for agents) (Admin Only)
        ),
        GoRoute(
          path: '/property/upload',
          name: 'propertyUpload',
          builder: (context, state) => AdminWrapper(
            child: const PropertyUploadScreen(),
          ),
          // Upload images and detailed info of properties (Admin Only)
        ),
        GoRoute(
          path: '/property/edit/:id',
          name: 'propertyEdit',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return AdminWrapper(
              child: PropertyEditScreen(propertyId: id),
            );
          },
          // Edit existing property details (Admin Only)
        ),

        // ADMIN ROUTES - Single definition for each
        GoRoute(
          path: '/admin/dashboard',
          name: 'adminDashboard',
          builder: (context, state) => AdminWrapper(
            child: const AdminDashboardScreen(),
          ),
          // Overview of analytics, user stats (Admin Only)
        ),
        GoRoute(
          path: '/admin/users',
          name: 'adminUsers',
          builder: (context, state) => AdminWrapper(
            child: const ManageUsersScreen(),
          ),
          // CRUD operations for managing app users (Admin Only)
        ),
        GoRoute(
          path: '/admin/properties',
          name: 'adminProperties',
          builder: (context, state) => AdminWrapper(
            child: const ManagePropertiesScreen(),
          ),
          // Admin management of all property listings (Admin Only)
        ),
        GoRoute(
          path: '/admin/analytics',
          name: 'adminAnalytics',
          builder: (context, state) => AdminWrapper(
            child: const AnalyticsScreen(),
          ),
          // Advanced analytics & reporting tools (Admin Only)
        ),

        // DEVELOPER ROUTE
        GoRoute(
          path: '/dev/diagnostics',
          name: 'diagnostics',
          builder: (context, state) => const NavigationDiagnosticScreen(),
        ),
      ],
    );
  }

  /// Initialize the router with context (safely)
  static void initialize(BuildContext context) {
    // Only initialize if not already initialized
    _router ??= createRouter(context);
  }

  /// Access the router - will throw if used before initialization
  static GoRouter get router {
    if (_router == null) {
      throw StateError(
          'AppRouter has not been initialized. Call AppRouter.initialize() first.');
    }
    return _router!;
  }

  // Add missing initializeWithProvider method
  static void initializeWithProvider(AuthProvider authProvider) {
    DebugLogger.info('🔍 TRACE: AppRouter.initializeWithProvider called');
    try {
      if (_router == null) {
        DebugLogger.info('🚀 Creating new router');
        _router = _createRouterWithProvider(authProvider);
        DebugLogger.info('✅ Router created successfully');
      } else {
        DebugLogger.info('ℹ️ Router already initialized');
      }
    } catch (e) {
      DebugLogger.error('❌ CRITICAL: Failed to initialize AppRouter', e);
      _createFallbackRouter();
    }
  }

  // Helper method to create router with provider
  static GoRouter _createRouterWithProvider(AuthProvider authProvider) {
    final publicRoutes = [
      '/', // Landing page
      '/landing', // Explicit landing route
      '/login',
      '/register',
      '/reset-password',
    ];

    final userRoutes = [
      '/home',
      '/search',
      '/favorites',
      '/profile',
      '/profile/edit',
      '/profile/properties',
      '/profile/history',
      '/profile/settings',
      '/profile/support',
      '/notifications',
    ];

    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/',
      debugLogDiagnostics: true,
      routes: [
        // Add the shell route for main navigation structure
        _createShellRoute(),

        // Keep your existing routes for non-tabbed screens
        GoRoute(
          path: '/',
          name: 'splash',
          builder: (context, state) => const AuthWrapper(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/reset-password',
          name: 'resetPassword',
          builder: (context, state) => const ResetPasswordScreen(),
        ),
        GoRoute(
          path: '/landing',
          name: 'landing',
          builder: (context, state) => const LandingScreen(),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomeScreen(showNavBar: true),
        ),
        GoRoute(
          path: '/search',
          name: 'search',
          builder: (context, state) {
            final query = state.uri.queryParameters['q'];
            return SearchScreen(initialQuery: query, showNavBar: true);
          },
        ),
        GoRoute(
          path: '/favorites',
          name: 'favorites',
          builder: (context, state) => const FavoritesScreen(showNavBar: true),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(showNavBar: true),
        ),
        GoRoute(
          path: '/profile/edit',
          name: 'profileEdit',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/profile/properties',
          name: 'myProperties',
          builder: (context, state) => const MyPropertiesScreen(),
        ),
        GoRoute(
          path: '/profile/history',
          name: 'history',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: '/profile/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/profile/support',
          name: 'support',
          builder: (context, state) => const SupportScreen(),
        ),
        GoRoute(
          path: '/notifications',
          name: 'notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/property/add',
          name: 'propertyAdd',
          builder: (context, state) => AdminWrapper(
            child: const PropertyUploadScreen(),
          ),
        ),
        GoRoute(
          path: '/property/upload',
          name: 'propertyUpload',
          builder: (context, state) => AdminWrapper(
            child: const PropertyUploadScreen(),
          ),
        ),
        GoRoute(
          path: '/property/edit/:id',
          name: 'propertyEdit',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return AdminWrapper(
              child: PropertyEditScreen(propertyId: id),
            );
          },
        ),
        GoRoute(
          path: '/property/:id',
          name: 'propertyDetail',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return PropertyDetailScreen(propertyId: id);
          },
        ),
        GoRoute(
          path: '/admin/dashboard',
          name: 'adminDashboard',
          builder: (context, state) => AdminWrapper(
            child: const AdminDashboardScreen(),
          ),
          // Overview of analytics, user stats (Admin Only)
        ),
        GoRoute(
          path: '/admin/users',
          name: 'adminUsers',
          builder: (context, state) => AdminWrapper(
            child: const ManageUsersScreen(),
          ),
          // CRUD operations for managing app users (Admin Only)
        ),
        GoRoute(
          path: '/admin/properties',
          name: 'adminProperties',
          builder: (context, state) => AdminWrapper(
            child: const ManagePropertiesScreen(),
          ),
          // Admin management of all property listings (Admin Only)
        ),
        GoRoute(
          path: '/admin/analytics',
          name: 'adminAnalytics',
          builder: (context, state) => AdminWrapper(
            child: const AnalyticsScreen(),
          ),
          // Advanced analytics & reporting tools (Admin Only)
        ),
        GoRoute(
          path: '/dev/diagnostics',
          name: 'diagnostics',
          builder: (context, state) => const NavigationDiagnosticScreen(),
        ),
      ],
      redirect: (context, state) {
        DebugLogger.route('Redirecting from: ${state.uri.path}');
        if (state.uri.path == '/') {
          return null;
        }
        NavigationLogger.log(
          NavigationEventType.routeChange,
          'GoRouter redirect triggered',
          data: {
            'path': state.uri.path,
            'isAuthenticated': authProvider.isAuthenticated
          },
        );
        final path = state.uri.path;
        final isAuthenticated = authProvider.isAuthenticated;

        // Use synchronous method for immediate UI decisions
        final isAdmin =
            isAuthenticated && AdminService.isUserAdmin(authProvider.user);

        final isDeveloper = kDebugMode && isAdmin;
        bool pathStartsWith(String prefix) => path.startsWith(prefix);
        if (pathStartsWith('/admin/') ||
            pathStartsWith('/property/add') ||
            pathStartsWith('/property/edit/') ||
            pathStartsWith('/property/upload')) {
          if (!isAdmin) {
            DebugLogger.warn(
                'Non-admin user attempted to access admin route: $path');
            return isAuthenticated ? '/home' : '/login';
          }
          return null;
        }
        if (pathStartsWith('/dev/')) {
          if (!isDeveloper) {
            DebugLogger.warning(
                'Non-developer tried to access dev route: $path');
            return '/home';
          }
          return null;
        }
        if (pathStartsWith('/property/') &&
            !pathStartsWith('/property/add') &&
            !pathStartsWith('/property/edit/')) {
          if (!isAuthenticated) {
            final redirectPath = path;
            DebugLogger.info('Storing redirect path: $redirectPath');
            return '/login?redirect=$redirectPath';
          }
          return null;
        }
        if (userRoutes.contains(path) ||
            userRoutes.any((route) => pathStartsWith("$route/"))) {
          if (!isAuthenticated) {
            final redirectPath = path;
            DebugLogger.info('Storing redirect path: $redirectPath');
            return '/login?redirect=$redirectPath';
          }
          return null;
        }
        if (publicRoutes.contains(path)) {
          if (isAuthenticated &&
              (path == '/login' || path == '/register' || path == '/')) {
            return '/home';
          }
          return null;
        }
        return null;
      },
      errorBuilder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(child: Text('Error: ${state.error}')),
        );
      },
    );
  }

  // Add this function to create StatefulShellRoutes with proper navigation control
  static StatefulShellRoute _createShellRoute() {
    return StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              // Use synchronous check for immediate UI decisions
              final isAdmin = authProvider.user != null &&
                  AdminService.isUserAdmin(authProvider.user);
              final userId = authProvider.user?.uid ?? 'guest';

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

              // Ensure the selectedIndex is valid for the current destinations array
              int safeIndex = navigationShell.currentIndex;
              if (safeIndex >= destinations.length) {
                safeIndex = 0; // Default to home tab if index is out of bounds
              }

              return NavigationBar(
                selectedIndex: safeIndex,
                destinations: destinations,
                onDestinationSelected: (index) {
                  final currentRoute = state.uri.path;
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
                      // Use property/add instead of property/upload for the admin route
                      // This fixed route uses AdminWrapper properly
                      targetRoute = '/property/add';
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

                  // Use simple context.go() for direct navigation without shell
                  context.go(targetRoute);
                },
              );
            },
          ),
        );
      },
      branches: [
        // Home branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(showNavBar: false),
            ),
          ],
        ),
        // Search branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) {
                final query = state.uri.queryParameters['q'];
                return SearchScreen(initialQuery: query, showNavBar: false);
              },
            ),
          ],
        ),
        // Post branch (admin only) - This will be skipped for non-admin users
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/property/upload',
              builder: (context, state) =>
                  const PropertyUploadScreen(showNavBar: false),
            ),
          ],
        ),
        // Favorites branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/favorites',
              builder: (context, state) =>
                  const FavoritesScreen(showNavBar: false),
            ),
          ],
        ),
        // Profile branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) =>
                  const ProfileScreen(showNavBar: false),
            ),
          ],
        ),
        // Notifications branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/notifications',
              builder: (context, state) => const NotificationsScreen(),
            ),
          ],
        ),
      ],
    );
  }

  // Fallback router creation
  static void _createFallbackRouter() {
    DebugLogger.info('⚠️ Creating FALLBACK router');
    _router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const AuthWrapper(),
        ),
      ],
    );
  }
}
