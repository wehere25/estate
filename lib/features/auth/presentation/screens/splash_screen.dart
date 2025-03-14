import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/debug_logger.dart';
import '../../../../core/providers/provider_container.dart';
import '../../domain/providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/landing_screen.dart';
import '../../../../core/services/global_auth_service.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  bool _navigationAttempted = false;
  bool _timeoutOccurred = false;

  @override
  void initState() {
    super.initState();
    
    // Set up animations
    _controller = AnimationController(
      duration: const Duration(seconds: 3), // Longer duration for smoother effect
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );
    
    // Start animation
    _controller.forward();
    
    // Check auth state after animations complete
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkAuthAndNavigate();
      }
    });

    // Safety timeout
    Timer(const Duration(seconds: 5), () {
      if (mounted && !_navigationAttempted) {
        DebugLogger.info("Splash timeout triggered, forcing navigation");
        _navigateToLanding();
      }
    });

    // Add a timeout to ensure we don't get stuck
    Timer(const Duration(seconds: 8), () {
      if (mounted && !_timeoutOccurred) {
        _timeoutOccurred = true;
        DebugLogger.error('Splash screen timeout occurred, navigating to login screen');
        context.go('/login');
      }
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    if (_navigationAttempted || _timeoutOccurred) return; 
    _navigationAttempted = true;
    DebugLogger.info("Checking authentication status");
    
    try {
      // Allow splash to display for a moment
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      // Use the global auth service instead of Provider.of
      final globalAuthService = GlobalAuthService();
      DebugLogger.provider('SplashScreen using GlobalAuthService');
      
      // Auth status is already checked during initialization
      if (globalAuthService.isAuthenticated) {
        _navigateToHome();
      } else {
        _navigateToLanding();
      }
    } catch (e) {
      DebugLogger.error('Error during auth check', e);
      if (mounted) _navigateToLanding();
    }
  }

  void _navigateToLanding() {
    DebugLogger.route('Navigating to landing screen');
    if (!mounted) return;
    context.go('/landing');
  }

  void _navigateToHome() {
    DebugLogger.route('Navigating to home screen');
    if (!mounted) return;
    context.go('/home');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = AppColors.lightColorScheme.primary;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor, 
              primaryColor.withAlpha(200),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: child,
                  ),
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.home_rounded,
                    size: 80,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 40),
                
                // App Name
                Text(
                  'RealState',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 42,
                    letterSpacing: 1.2,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Tagline
                Text(
                  'Find Your Dream Home',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                    letterSpacing: 0.5,
                  ),
                ),
                
                const SizedBox(height: 50),
                
                // Loading indicator with custom styling
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 4,
                    backgroundColor: primaryColor.withAlpha(100),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
