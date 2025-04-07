import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  bool _isValidEmail(String email) {
    // More comprehensive validation that requires @ and domain
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Validate input
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms and Conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    // Get authentication provider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Register user
      final success = await authProvider.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Very important: check if still mounted before proceeding
      if (!mounted) return;

      // Update loading state
      setState(() {
        _isLoading = false;
      });

      if (success) {
        // Registration successful - show a prominent verification needed dialog
        // Use Future.microtask to avoid context issues
        Future.microtask(() {
          if (!mounted) return;

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.mark_email_read,
                      size: 56,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Verify Your Email',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'We\'ve sent a verification link to your email address. Please check your inbox and verify your account before signing in.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        // Navigate to login screen with needVerification parameter
                        Future.microtask(() {
                          if (mounted)
                            context.go('/login?needVerification=true');
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightColorScheme.primary,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'GO TO LOGIN',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      } else {
        // Registration failed with error
        if (!mounted) return;

        // Handle specific error types
        final error = authProvider.error;
        if (error != null && error.contains('permission-denied')) {
          // Show the same verification dialog for permission-denied errors
          // since the account was likely created successfully
          Future.microtask(() {
            if (!mounted) return;

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.mark_email_read,
                        size: 56,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Verify Your Email',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'We\'ve sent a verification link to your email address. Please check your inbox and verify your account before signing in.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          // Navigate to login screen with needVerification parameter
                          Future.microtask(() {
                            if (mounted)
                              context.go('/login?needVerification=true');
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lightColorScheme.primary,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'GO TO LOGIN',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          });
          return;
        }

        // For "email-already-in-use" errors, show a more helpful message
        if (error != null && error.contains('email-already-in-use')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'An account with this email already exists. Try signing in instead.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'SIGN IN',
                onPressed: () {
                  if (mounted) context.go('/login');
                },
              ),
            ),
          );
          return;
        }

        // Show the error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Unexpected error
      if (!mounted) return;

      // Make sure to update loading state
      setState(() {
        _isLoading = false;
      });

      String errorMessage = e.toString();
      if (errorMessage.contains('permission-denied')) {
        // Show the same verification dialog for permission-denied errors in catch block
        Future.microtask(() {
          if (!mounted) return;

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.mark_email_read,
                      size: 56,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Verify Your Email',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'We\'ve sent a verification link to your email address. Please check your inbox and verify your account before signing in.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        // Navigate to login screen with needVerification parameter
                        Future.microtask(() {
                          if (mounted)
                            context.go('/login?needVerification=true');
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightColorScheme.primary,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'GO TO LOGIN',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      } else if (errorMessage.contains('email-already-in-use')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'An account with this email already exists. Try signing in instead.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'SIGN IN',
              onPressed: () {
                if (mounted) context.go('/login');
              },
            ),
          ),
        );
      } else {
        // Other unexpected error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleLogin() {
    if (mounted) {
      context.go('/login');
    }
  }

  void _handleBackPress() {
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _handleBackPress();
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBackPress,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        extendBodyBehindAppBar: true,
        body: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height,
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
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign up to get started',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppTextField(
                                controller: _nameController,
                                hintText: 'Full Name',
                                prefixIcon: const Icon(Icons.person_outline),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                controller: _emailController,
                                hintText: 'Email',
                                prefixIcon: const Icon(Icons.email_outlined),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }

                                  value = value.trim();
                                  if (!value.contains('@')) {
                                    return 'Email must include the @ symbol';
                                  }
                                  if (!value.contains('.')) {
                                    return 'Email must include a domain (e.g., .com, .net)';
                                  }
                                  if (!_isValidEmail(value)) {
                                    return 'Please enter a complete email (e.g., name@example.com)';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                controller: _passwordController,
                                hintText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                obscureText: _obscurePassword,
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
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                controller: _confirmPasswordController,
                                hintText: 'Confirm Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                obscureText: _obscureConfirmPassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords don\'t match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _agreedToTerms,
                                    onChanged: (value) {
                                      setState(() {
                                        _agreedToTerms = value ?? false;
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _agreedToTerms = !_agreedToTerms;
                                        });
                                      },
                                      child: RichText(
                                        text: TextSpan(
                                          text: 'I agree to the ',
                                          style: TextStyle(
                                              color: Colors.grey[700]),
                                          children: [
                                            TextSpan(
                                              text: 'Terms and Conditions',
                                              style: TextStyle(
                                                color: AppColors
                                                    .lightColorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _isLoading ? null : _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor:
                                      AppColors.lightColorScheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator()
                                    : const Text(
                                        'SIGN UP',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        TextButton(
                          onPressed: _handleLogin,
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
