import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import '../../../../core/utils/debug_logger.dart';
import '../../../../core/utils/dev_utils.dart';
import '../providers/admin_provider.dart';

class AdminWrapper extends StatelessWidget {
  final Widget child;

  const AdminWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminProvider>(
      create: (_) => AdminProvider(),
      child: _AdminWrapperContent(child: child),
    );
  }
}

class _AdminWrapperContent extends StatelessWidget {
  final Widget child;

  const _AdminWrapperContent({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    return _AdminInitializerWidget(adminProvider: adminProvider, child: child);
  }
}

class _AdminInitializerWidget extends StatefulWidget {
  final AdminProvider adminProvider;
  final Widget child;

  const _AdminInitializerWidget(
      {required this.adminProvider, required this.child});

  @override
  State<_AdminInitializerWidget> createState() =>
      _AdminInitializerWidgetState();
}

class _AdminInitializerWidgetState extends State<_AdminInitializerWidget> {
  bool _initializing = true;
  String? _error;
  bool _appCheckError = false;
  int _retryCount = 0;
  static const _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _safeInitializeWithRetry();
    });
  }

  Future<void> _safeInitializeWithRetry() async {
    if (!mounted) return;

    try {
      if (!kDebugMode) {
        try {
          await FirebaseAppCheck.instance.activate(
            androidProvider: AndroidProvider.playIntegrity,
            appleProvider: AppleProvider.deviceCheck,
          );
        } catch (e) {
          DebugLogger.error('App Check error during admin initialization', e);
          if (mounted) {
            setState(() {
              _appCheckError = true;
              _initializing = false;
            });
          }
          return;
        }
      } else {
        try {
          DebugLogger.info(
              'Using debug App Check provider in development mode');
          await FirebaseAppCheck.instance.activate(
            androidProvider: AndroidProvider.debug,
            appleProvider: AppleProvider.debug,
            webProvider: ReCaptchaV3Provider('dummy-key'),
          );
        } catch (e) {
          DebugLogger.warning(
              'Debug App Check initialization failed (non-critical): $e');
        }
      }

      await widget.adminProvider.preInitialize();

      if (mounted) {
        setState(() {
          _initializing = false;
          _error = widget.adminProvider.error;
        });
      }
    } catch (e) {
      DebugLogger.error('Error during admin initialization', e);
      if (mounted) {
        setState(() {
          _error = e.toString();
          _initializing = false;
        });
      }
      if (_retryCount < _maxRetries) {
        _retryCount++;
        await Future.delayed(Duration(seconds: _retryCount));
        if (mounted) {
          _safeInitializeWithRetry();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, _) {
        if (_appCheckError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Security Check Failed')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.security, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('App security verification failed',
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('Please try again later or contact support',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  if (kDebugMode)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _appCheckError = false;
                          _initializing = true;
                        });
                        _safeInitializeWithRetry();
                      },
                      child: const Text('Retry'),
                    ),
                ],
              ),
            ),
          );
        }

        if (_initializing || adminProvider.isLoading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                      'Initializing admin panel${_retryCount > 0 ? ' (Attempt ${_retryCount + 1}/$_maxRetries)' : ''}',
                      style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          );
        }

        if ((_error != null || adminProvider.error != null) &&
            !DevUtils.isDevMode) {
          final errorMsg = _error ?? adminProvider.error ?? 'Unknown error';
          return Scaffold(
            appBar: AppBar(title: const Text('Admin Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $errorMsg',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _initializing = true;
                        _retryCount = 0;
                      });
                      adminProvider.clearError();
                      _safeInitializeWithRetry();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return widget.child;
      },
    );
  }
}
