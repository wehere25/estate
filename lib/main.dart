import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

// Core imports
import 'core/config/firebase_options.dart';
import 'core/theme/theme_provider.dart';
import 'core/utils/debug_logger.dart';
import 'core/services/global_auth_service.dart';
import 'core/utils/navigation_logger.dart';
import 'features/auth/domain/providers/auth_provider.dart';
import 'features/property/data/property_repository.dart';
import 'features/favorites/providers/favorites_provider.dart';
import 'features/property/presentation/providers/property_provider.dart';
import 'features/storage/providers/storage_provider.dart';
import 'core/providers/provider_container.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/home/providers/home_provider.dart';

// Make globalAuthService accessible throughout the app
final GlobalAuthService globalAuthService = GlobalAuthService();

// Flag to track if App Check was successfully initialized
bool _isAppCheckInitialized = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DebugLogger.info('🚀 App starting - Flutter binding initialized');

  // Guard flag to prevent duplicate initializations
  bool isAppAlreadyInitialized = false;

  try {
    // IMPORTANT: Only initialize Firebase once by checking apps list
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      DebugLogger.info('✅ Firebase initialized successfully');
    } else {
      // If Firebase is already initialized, use the existing instance
      DebugLogger.info(
          '✅ Firebase was already initialized, using existing instance');
    }

    // Initialize App Check with proper error handling
    // Do this before auth initialization to ensure tokens are available
    try {
      await _initializeAppCheck();
      _isAppCheckInitialized = true;
    } catch (e) {
      // Don't fail the app just because App Check failed
      _isAppCheckInitialized = false;
      DebugLogger.error(
          '❌ Firebase App Check initialization error - continuing anyway', e);
    }

    // Let the system settle a bit after App Check initialization
    await Future.delayed(const Duration(milliseconds: 500));

    // Initialize global auth service if not already done
    if (!isAppAlreadyInitialized) {
      isAppAlreadyInitialized = true;

      try {
        DebugLogger.info('🔑 Starting GlobalAuthService initialization');
        await globalAuthService.initialize();
        DebugLogger.info('✅ GlobalAuthService initialized');
      } catch (e) {
        DebugLogger.error('❌ Error initializing GlobalAuthService', e);
        // Create emergency auth provider to prevent null errors
        globalAuthService.createEmergencyAuthProvider();
      }
    }
  } catch (e) {
    DebugLogger.error('❌ Error during app initialization', e);
    // Create emergency auth provider to ensure app doesn't crash
    globalAuthService.createEmergencyAuthProvider();
  }

  // Initialize shared preferences and repositories
  final sharedPreferences = await SharedPreferences.getInstance();
  final propertyRepository = PropertyRepository();

  // Initialize global provider container
  final providerContainer = ProviderContainer();
  providerContainer.initialize();
  DebugLogger.provider('Provider container initialized');

  // Initialize navigation logger
  NavigationLogger.log(
    NavigationEventType.routeGeneration,
    'App starting',
    data: {'buildMode': kReleaseMode ? 'RELEASE' : 'DEBUG'},
  );

  // Build and run app
  DebugLogger.info('🏁 Starting app with MultiProvider');

  // Run the app with proper error handling
  runApp(
    MultiProvider(
      providers: [
        // Make sure to handle null auth provider case
        ChangeNotifierProvider<AuthProvider>.value(
          value: globalAuthService.authProvider,
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<PropertyProvider>(
          create: (_) => PropertyProvider(propertyRepository),
        ),
        ChangeNotifierProvider<FavoritesProvider>(
          create: (_) =>
              FavoritesProvider(propertyRepository, sharedPreferences),
        ),
        ChangeNotifierProvider<StorageProvider>(
          create: (_) => StorageProvider(),
        ),
      ],
      child: const AppWithErrorBoundary(),
    ),
  );

  DebugLogger.info('🏁 App started');
}

// App Check initialization with proper retry and error handling
Future<void> _initializeAppCheck() async {
  // Add a retry mechanism for App Check initialization
  int attempts = 0;
  const maxAttempts = 3;

  while (attempts < maxAttempts) {
    try {
      DebugLogger.info(
          'Initializing Firebase App Check (attempt ${attempts + 1}/$maxAttempts)');

      if (kDebugMode) {
        // In debug mode, use debug providers that don't require real attestation
        await FirebaseAppCheck.instance.activate(
          webProvider: ReCaptchaV3Provider('dummy-key'),
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
          // Don't throw errors if setup fails
        );
        DebugLogger.info('✅ Initialized Firebase App Check in debug mode');
        break;
      } else {
        // In production mode, use the appropriate providers
        // But set a proper timeout to avoid hanging
        await FirebaseAppCheck.instance
            .activate(
          androidProvider: AndroidProvider.playIntegrity,
          appleProvider: AppleProvider.deviceCheck,
          // Add a timeout for the operation
        )
            .timeout(const Duration(seconds: 5), onTimeout: () {
          throw TimeoutException('App Check activation timed out');
        });
        DebugLogger.info('✅ Initialized Firebase App Check in production mode');
        break;
      }
    } catch (e) {
      attempts++;
      DebugLogger.error(
          '❌ App Check initialization attempt $attempts failed', e);

      if (attempts >= maxAttempts) {
        // On final failure, log and continue without App Check
        DebugLogger.warning(
            '⚠️ Failed to initialize App Check after $maxAttempts attempts. App will continue without App Check verification.');
        // Set a flag to indicate App Check is not active
        _isAppCheckInitialized = false;
        return;
      }

      // Wait before retrying
      await Future.delayed(Duration(seconds: attempts));
    }
  }

  // Register token refresh listener
  FirebaseAppCheck.instance.onTokenChange.listen(
    (token) {
      DebugLogger.info('App Check token refreshed successfully');
    },
    onError: (error) {
      DebugLogger.error('App Check token refresh error', error);
      // Don't fail the app for token refresh errors
    },
  );
}

// Top-level error boundary component
class AppWithErrorBoundary extends StatefulWidget {
  const AppWithErrorBoundary({Key? key}) : super(key: key);

  @override
  State<AppWithErrorBoundary> createState() => _AppWithErrorBoundaryState();
}

class _AppWithErrorBoundaryState extends State<AppWithErrorBoundary> {
  // Track initialization state
  bool _isRouterInitialized = false;
  String? _initError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize the router with the auth provider from context
    if (!_isRouterInitialized) {
      try {
        // This is key - properly initialize the AppRouter with the auth provider
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        AppRouter.initializeWithProvider(authProvider);
        setState(() {
          _isRouterInitialized = true;
        });
      } catch (e) {
        DebugLogger.error('Failed to initialize router', e);
        setState(() {
          _initError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      // Show error screen if router initialization failed
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.red.shade100,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Error',
                  style: TextStyle(color: Colors.red, fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  _initError!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Restart app state to attempt recovery
                    setState(() {
                      _initError = null;
                      _isRouterInitialized = false;
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show loading screen until router is initialized
    if (!_isRouterInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initializing application...'),
              ],
            ),
          ),
        ),
      );
    }

    // Once router is initialized, show the actual app
    return const MyApp();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DebugLogger.info('📱 Building MyApp widget');
    try {
      // Router should be initialized by now
      final router = AppRouter.router;
      DebugLogger.info('✅ Got router from AppRouter.router');

      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => HomeProvider()),
          // Add PropertyProvider to the MultiProvider
          ChangeNotifierProvider(
              create: (_) => PropertyProvider(PropertyRepository())),
          // Other providers
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp.router(
              title: 'Real Estate App',
              routerConfig: router,
              debugShowCheckedModeBanner: false,
              theme: themeProvider.isDarkMode
                  ? AppTheme.darkTheme
                  : AppTheme.lightTheme,
              themeMode: themeProvider.themeMode,
              builder: (context, child) {
                return child ??
                    const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
              },
            );
          },
        ),
      );
    } catch (e) {
      DebugLogger.error('❌ CRITICAL ERROR in MyApp build', e);
      // Fallback to a basic error screen if routing fails
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.red,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Critical Error',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Navigate back to root to attempt recovery
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/', (route) => false);
                  },
                  child: const Text('Go to Home Screen'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
