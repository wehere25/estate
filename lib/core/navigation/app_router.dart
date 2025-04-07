import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// Admin imports
import '../../features/admin/presentation/wrappers/admin_wrapper.dart';

// Auth imports
import '../../features/auth/domain/providers/auth_provider.dart';
import '../../features/auth/domain/enums/auth_status.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/landing_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
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
import '../../features/search/presentation/screens/saved_searches_screen.dart';

// Utils
import '../../core/utils/debug_logger.dart';
import '../utils/navigation_logger.dart';
import '../../features/auth/domain/services/admin_service.dart';

// Navigation keys
final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

// Store the original request path for redirecting after login
String? _originalRequestPath;

// Auth state refresh notifier
final _refreshNotifier = AuthRefreshNotifier();

// Auth refresh notifier to trigger router refresh when auth state changes
class AuthRefreshNotifier extends ChangeNotifier {
  // Call this method when auth state changes
  void notifyAuthChanged() {
    notifyListeners();
  }
}

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
      initialLocation: authProvider.isAuthenticated ? '/home' : '/',
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

        // Get current auth status
        final isLoggedIn = authProvider.isAuthenticated;
        final isVerified = authProvider.user?.emailVerified ?? false;
        final isLoading = authProvider.isLoading;
        final isCheckingAuth = authProvider.isCheckingAuth;
        final authStatus = authProvider.status;

        // For previously authenticated users, skip splash screen to prevent it from showing on every app launch
        if (state.uri.path == '/' &&
            isLoggedIn &&
            !isLoading &&
            !isCheckingAuth) {
          DebugLogger.info(
              'User already authenticated, skipping splash screen');
          return '/home';
        }

        // Never redirect from the splash screen during initial app launch - let it handle navigation
        if (state.uri.path == '/' && (isLoading || isCheckingAuth)) {
          return null;
        }

        // If we're still checking auth status, don't redirect
        if (isCheckingAuth) {
          return null;
        }

        // Store current path for later redirect if needed
        final goingTo = state.matchedLocation;
        if (!isLoggedIn &&
            !publicRoutes.contains(goingTo) &&
            goingTo != '/login') {
          DebugLogger.info('Storing redirect path: $goingTo');
          _originalRequestPath = goingTo;
        }

        // Don't redirect if still loading auth state
        if (isLoading) {
          return null;
        }

        // Handle email verification requirement
        // Important: Check unverified status first to prevent auth state flicker
        if (authStatus == AuthStatus.unverified ||
            (isLoggedIn && !isVerified && !publicRoutes.contains(goingTo))) {
          DebugLogger.info('User email not verified, redirecting to login');

          // Force sign out unverified users and redirect to login
          // Use microtask to avoid router issues
          Future.microtask(() async {
            await authProvider.signOut();
          });

          return '/login?needVerification=true';
        }

        // Authentication redirects
        if (!isLoggedIn) {
          // Allow public paths without authentication
          if (publicRoutes.contains(goingTo)) {
            return null;
          }

          // Redirect to login for protected paths
          if (goingTo != '/login' && goingTo != '/register') {
            DebugLogger.info(
                'Not authenticated, redirecting to login from $goingTo');
            return '/login';
          }
        } else {
          // Redirect authenticated users away from auth screens
          if (goingTo == '/login' || goingTo == '/register') {
            return _originalRequestPath ?? '/home';
          }
        }

        // Handle initial route redirection - only redirect authenticated users
        // But don't override splash screen behavior
        if (isLoggedIn && (state.uri.path == '/landing')) {
          DebugLogger.info(
              'User authenticated, redirecting to shell route /home');
          return '/home';
        }

        // For first launch, don't redirect from splash screen
        // but redirect root path to landing if coming from elsewhere
        if (!isLoggedIn &&
            state.uri.path == '/' &&
            state.fullPath != null &&
            state.fullPath != '/') {
          DebugLogger.info(
              'First visit from somewhere else, redirecting to landing screen');
          return '/landing';
        }

        return null;
      },

      // Define all routes
      routes: [
        // PUBLIC AUTHENTICATION ROUTES
        GoRoute(
          path: '/',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
          // Initial splash screen that shows app logo and transitions to landing/login
        ),
        GoRoute(
          path: '/landing',
          name: 'landing',
          builder: (context, state) => const LandingScreen(),
          // Introductory page showcasing featured properties before login
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

        // NEW ROUTE
        GoRoute(
          path: '/saved_searches',
          name: 'savedSearches',
          builder: (context, state) => const SavedSearchesScreen(),
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
      initialLocation: authProvider.isAuthenticated ? '/home' : '/',
      debugLogDiagnostics: true,
      routes: [
        // Create the shell route for tabbed navigation (used by the main app screens)
        _createShellRoute(),

        // Keep your existing routes for non-tabbed screens
        GoRoute(
          path: '/',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
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
          path: '/search_results',
          name: 'searchResults',
          builder: (context, state) {
            final Map<String, dynamic>? extra =
                state.extra as Map<String, dynamic>?;
            final query =
                extra?['query'] as String? ?? state.uri.queryParameters['q'];
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
        GoRoute(
          path: '/saved_searches',
          name: 'savedSearches',
          builder: (context, state) => const SavedSearchesScreen(),
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

  /// Create a stateful shell route for tabbed navigation
  static StatefulShellRoute _createShellRoute() {
    return StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        // Get the current path and index
        final currentPath = GoRouterState.of(context).uri.path;
        final activeIndex = navigationShell.currentIndex;

        // Get authentication status
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final isAuthenticated = authProvider.isAuthenticated;
        final isCheckingAuth = authProvider.isCheckingAuth;
        final userId = authProvider.user?.uid ?? 'guest';

        // Check if user is admin
        final isAdmin = authProvider.user != null
            ? AdminService.isUserAdmin(authProvider.user)
            : false;

        // Debug logging for shell navigation
        DebugLogger.info(
            'NAVBAR DEBUG: Building navigation shell with index: $activeIndex, ' +
                'Auth state: ${isAuthenticated ? "Authenticated" : "Unauthenticated"}, ' +
                'Checking Auth: $isCheckingAuth, ' +
                'Current path: $currentPath');

        // Return the stateful shell with proper navigation
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              // Log navbar construction
              DebugLogger.info(
                  'NAVBAR DEBUG: Building navbar for path: $currentPath, ' +
                      'User: $userId, isAdmin: $isAdmin');

              // Always show navbar
              return BottomNavigationBarWithPersistence(
                isAdmin: isAdmin,
                userId: userId,
                currentPath: currentPath,
                onDestinationSelected: (index) {
                  // The direct branch navigation is the most reliable approach
                  _navigateToTabIndex(context, navigationShell, index, isAdmin,
                      userId, currentPath);
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
        // Favorites branch (or Admin-only Post branch depending on user role)
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
        // Admin routes branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/property/upload',
              builder: (context, state) =>
                  const PropertyUploadScreen(showNavBar: false),
            ),
          ],
        ),
        // Notifications branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/notifications',
              name: 'notifications',
              builder: (context, state) =>
                  const NotificationsScreen(showNavBar: false),
            ),
          ],
        ),
      ],
    );
  }

  // Helper method to navigate to the correct branch based on tab index
  static void _navigateToTabIndex(
      BuildContext context,
      StatefulNavigationShell navigationShell,
      int index,
      bool isAdmin,
      String userId,
      String currentPath) {
    // Determine which branch to navigate to based on user role and tab index
    int branchIndex;
    String tabName = "Unknown";

    if (!isAdmin) {
      // Normal user navigation
      switch (index) {
        case 0: // Home
          branchIndex = 0;
          tabName = "Home";
          break;
        case 1: // Search
          branchIndex = 1;
          tabName = "Search";
          break;
        case 2: // Favorites
          branchIndex = 2;
          tabName = "Favorites";
          break;
        case 3: // Profile
          branchIndex = 3;
          tabName = "Profile";
          break;
        default:
          branchIndex = 0;
          tabName = "Home";
      }
    } else {
      // Admin user navigation
      switch (index) {
        case 0: // Home
          branchIndex = 0;
          tabName = "Home";
          break;
        case 1: // Search
          branchIndex = 1;
          tabName = "Search";
          break;
        case 2: // Post (admin specific)
          branchIndex = 4;
          tabName = "Post";
          break;
        case 3: // Favorites
          branchIndex = 2;
          tabName = "Favorites";
          break;
        case 4: // Profile
          branchIndex = 3;
          tabName = "Profile";
          break;
        default:
          branchIndex = 0;
          tabName = "Home";
      }
    }

    // Navigate to the selected branch
    navigationShell.goBranch(branchIndex);

    // Log navigation for debugging
    DebugLogger.info('NAVBAR DEBUG: Tab clicked - index: $index, ' +
        'from: $currentPath, to branch: $branchIndex, ' +
        'tabName: $tabName, isAdmin: $isAdmin, userId: $userId');
  }

  // Add new widget for bottom navigation bar with persistence
  static Widget BottomNavigationBarWithPersistence({
    required bool isAdmin,
    required String userId,
    required String currentPath,
    required Function(int) onDestinationSelected,
  }) {
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

    // Determine selected index based on current path - important for consistent highlighting
    int selectedIndex = 0; // Default to Home

    if (currentPath.startsWith('/search')) {
      selectedIndex = 1;
    } else if (currentPath.startsWith('/property/upload') ||
        currentPath.startsWith('/property/add')) {
      selectedIndex = isAdmin ? 2 : 0; // Only valid for admins
    } else if (currentPath.startsWith('/favorites')) {
      selectedIndex = isAdmin ? 3 : 2;
    } else if (currentPath.startsWith('/profile')) {
      selectedIndex = isAdmin ? 4 : 3;
    }

    // Ensure index is within valid range
    if (selectedIndex >= destinations.length) {
      selectedIndex = 0; // Default to home if index out of bounds
    }

    // Log navbar rendering with its complete state
    DebugLogger.info('NAVBAR DEBUG: Rendering navbar - ' +
        'path: $currentPath, selectedIndex: $selectedIndex, ' +
        'isAdmin: $isAdmin, userId: $userId, ' +
        'destinations count: ${destinations.length}');

    return NavigationBar(
      selectedIndex: selectedIndex,
      destinations: destinations,
      onDestinationSelected: onDestinationSelected,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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
