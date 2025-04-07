import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';

class NotificationBadge extends StatelessWidget {
  final bool showZero;
  final Color? badgeColor;
  final Color? iconColor;

  const NotificationBadge({
    Key? key,
    this.showZero = false,
    this.badgeColor,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final unreadCount = provider.unreadCount;
        final shouldShowBadge = showZero || unreadCount > 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: iconColor ??
                    Theme.of(context).appBarTheme.iconTheme?.color ??
                    Colors.white,
              ),
              tooltip: 'Notifications',
              onPressed: () {
                // Navigate to notifications screen using go_router
                context.go('/notifications');
              },
            ),
            if (shouldShowBadge)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: badgeColor ?? Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
