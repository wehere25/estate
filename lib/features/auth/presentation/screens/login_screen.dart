import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/debug_logger.dart';
import '../../domain/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      setState(() {
        _rememberMe = authProvider.rememberMe;
      });

      // Check for needVerification parameter in the URL
      final router = GoRouter.of(context);
      final needVerification = router.routeInformationProvider.value.uri
          .queryParameters['needVerification'];

      if (needVerification == 'true') {
        // Show more prominent verification notice after a slight delay
        Future.delayed(Duration(milliseconds: 200), () {
          if (!mounted) return;

          // Show verification alert
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.mark_email_read, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please verify your email before signing in. Check your inbox for the verification link.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 8),
              behavior: SnackBarBehavior.fixed,
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DebugLogger.info('Building LoginScreen UI');
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 380;

    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Check if we're still checking auth status or already authenticated
          if (authProvider.isCheckingAuth) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (authProvider.isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              DebugLogger.info(
                  'User is authenticated, navigating to home screen');
              context.go('/home');
            });
          }

          return Container(
            // Remove fixed height to prevent keyboard issues
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.lightColorScheme.primary,
                  AppColors.lightColorScheme.primaryContainer,
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenSize.width * 0.06,
                    vertical: screenSize.height * 0.02,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: screenSize.height * 0.05),

                      // Logo container
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(25),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.home,
                            size: isSmallScreen ? 36 : 48,
                            color: AppColors.lightColorScheme.primary,
                          ),
                        ),
                      ),

                      SizedBox(height: screenSize.height * 0.03),

                      // Welcome Text with animation
                      TweenAnimationBuilder(
                        duration: const Duration(milliseconds: 800),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, double value, child) {
                          return Opacity(
                            opacity: value,
                            child: child,
                          );
                        },
                        child: Column(
                          children: [
                            Text(
                              'Welcome Back',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 32,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign in to continue',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: screenSize.height * 0.04),

                      // Login card
                      Card(
                        elevation: 8,
                        shadowColor: Colors.black26,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'Enter your email',
                                    prefixIcon: Icon(Icons.email_outlined),
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!RegExp(
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                        .hasMatch(value)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: 'Enter your password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    border: const OutlineInputBorder(),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  obscureText: _obscurePassword,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Transform.scale(
                                          scale: 0.9,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            onChanged: (value) {
                                              setState(() {
                                                _rememberMe = value ?? false;
                                              });
                                              // Update the provider's remember me preference
                                              authProvider
                                                  .setRememberMe(_rememberMe);
                                            },
                                            activeColor: AppColors
                                                .lightColorScheme.primary,
                                          ),
                                        ),
                                        Text(
                                          'Remember Me',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 12 : 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        context.push('/reset-password');
                                      },
                                      child: Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 14,
                                          color: AppColors
                                              .lightColorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => _handleEmailPasswordSignIn(
                                          context, authProvider),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    backgroundColor:
                                        AppColors.lightColorScheme.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    disabledBackgroundColor:
                                        Colors.grey.shade300,
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'SIGN IN',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => _handleGoogleSignIn(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black87,
                                    side: const BorderSide(color: Colors.grey),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: SvgPicture.asset(
                                    'assets/images/google_g_logo.svg',
                                    height: 24,
                                    width: 24,
                                  ),
                                  label: const Text(
                                    'Sign in with Google',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                // Fix overflow by wrapping Row in SingleChildScrollView
                                const SizedBox(height: 24),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Don\'t have an account?',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            context.push('/register'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text(
                                          'Sign Up',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Sign up link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Don\'t have an account?',
                            style: TextStyle(color: Colors.white70),
                          ),
                          TextButton(
                            onPressed: () {
                              context.push('/register');
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Updated method to handle email/password sign in with better error handling
  void _handleEmailPasswordSignIn(
      BuildContext context, AuthProvider authProvider) async {
    DebugLogger.info('Login button pressed');

    // Validate form
    if (!_formKey.currentState!.validate()) {
      DebugLogger.info('Form validation failed');
      return;
    }

    // Hide keyboard to improve user experience
    FocusScope.of(context).unfocus();

    // Get values
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    DebugLogger.info('Attempting to sign in with email: $email');

    try {
      // Set loading state
      setState(() {
        _isSubmitting = true;
      });

      // Attempt sign in with remember me preference
      final success = await authProvider.signIn(
        email,
        password,
        rememberMe: _rememberMe,
      );

      if (!mounted) return;

      if (success) {
        DebugLogger.info('Email/password sign in successful');
        // Reset form
        _formKey.currentState!.reset();
        _emailController.clear();
        _passwordController.clear();
      } else if (authProvider.error?.contains('verify your email') == true) {
        // This is an email verification error, show special dialog
        _showEmailVerificationRequiredDialog(email);
      } else {
        // Show the error from the auth provider
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Authentication failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      DebugLogger.error('Error during sign in', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getFriendlyErrorMessage(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Only set state if the widget is still mounted
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Show dialog for email verification with resend option
  void _showEmailVerificationRequiredDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Email Verification Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your account requires email verification.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('We sent a verification link to $email.'),
              const SizedBox(height: 8),
              const Text(
                'Please check your email and verify your account before signing in.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Resend verification email safely
                try {
                  Navigator.of(dialogContext).pop(); // Close dialog first

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sending verification email...'),
                      duration: Duration(seconds: 2),
                    ),
                  );

                  final authProvider =
                      Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.resendVerificationEmailToAddress(email);

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Verification email sent. Please check your inbox.'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 4),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;

                  // Don't display permission denied errors to the user
                  if (!e.toString().contains('permission-denied')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    // Show success message even for permission errors
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Verification email sent. Please check your inbox.'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                }
              },
              child: const Text('RESEND VERIFICATION'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // New helper method to transform Firebase error messages into user-friendly messages
  String _getFriendlyErrorMessage(String error) {
    if (error.contains('user-not-found') || error.contains('wrong-password')) {
      return 'Invalid email or password. Please try again.';
    } else if (error.contains('too-many-requests')) {
      return 'Too many failed login attempts. Please try again later or reset your password.';
    } else if (error.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection and try again.';
    } else if (error.contains('verify your email')) {
      return 'Please verify your email before signing in.';
    } else if (error.contains('permission-denied')) {
      return 'Account setup in progress. Please try again in a moment.';
    }
    return 'Login failed: ${error.substring(0, math.min(error.length, 100))}';
  }

  // Google sign in handler
  void _handleGoogleSignIn(BuildContext context) async {
    DebugLogger.info('CLICK: GoogleSignInButton - Google Sign In Attempt');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final success = await authProvider.signInWithGoogle();
      if (success) {
        DebugLogger.info('Google sign in successful, navigating to home');
        if (context.mounted) {
          context.go('/home');
        }
      } else {
        DebugLogger.info('Google sign in was cancelled or failed');
      }
    } catch (e) {
      DebugLogger.error('Error during Google sign in', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getFriendlyErrorMessage(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
