import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/debug_logger.dart';

/// A wrapper widget that handles back button functionality consistently across the app.
///
/// This widget will:
/// 1. Log back button presses for debugging
/// 2. Allow customizing onWillPop behavior
/// 3. Support confirmation dialogs when leaving screens with unsaved changes
class BackButtonHandler extends StatelessWidget {
  final Widget child;
  final String screenName;
  final Future<bool> Function()? onWillPop;
  final VoidCallback? onBackPressed;
  final bool showConfirmation;
  final String confirmationTitle;
  final String confirmationMessage;
  final bool handleHardwareBack;

  const BackButtonHandler({
    Key? key,
    required this.child,
    required this.screenName,
    this.onWillPop,
    this.onBackPressed,
    this.showConfirmation = false,
    this.confirmationTitle = 'Leave Page?',
    this.confirmationMessage =
        'You have unsaved changes. Are you sure you want to leave?',
    this.handleHardwareBack = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use PopScope which is the modern replacement for WillPopScope
    return PopScope(
      canPop: false, // Always handle pops ourselves
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // Log back button press
        DebugLogger.info('🔙 Back button pressed on $screenName');

        bool shouldPop = true;

        // If we have custom back logic, execute it
        if (onWillPop != null) {
          shouldPop = await onWillPop!();
        }

        // Show confirmation dialog if needed
        if (shouldPop && showConfirmation) {
          shouldPop = await _showConfirmationDialog(context);
        }

        // If we should pop and we're still mounted
        if (shouldPop && context.mounted) {
          // If custom back press handling is provided, use that
          if (onBackPressed != null) {
            onBackPressed!();
          } else {
            // Default behavior - just pop the current route
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // If we can't pop, try to go back with GoRouter
              if (context.canPop()) {
                context.pop();
              } else {
                // Last resort - go to home
                context.go('/home');
              }
            }
          }
        }
      },
      child: child,
    );
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(confirmationTitle),
        content: Text(confirmationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
