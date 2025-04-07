import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/models/notification_type.dart';
import 'package:go_router/go_router.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Format the timestamp using the createdAt field
    final formattedTime = notification.createdAt != null
        ? DateFormat('MMM d, h:mm a').format(notification.createdAt)
        : 'Unknown time';

    // Check if property image is available in metadata
    final hasPropertyImage = notification.metadata != null &&
        notification.metadata!.containsKey('propertyImage') &&
        notification.metadata!['propertyImage'] != null;

    // Check if property price is available in metadata
    final hasPropertyPrice = notification.metadata != null &&
        notification.metadata!.containsKey('propertyPrice') &&
        notification.metadata!['propertyPrice'] != null;

    final propertyPrice = hasPropertyPrice
        ? NumberFormat.currency(locale: 'en_US', symbol: '\$')
            .format(notification.metadata!['propertyPrice'])
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: !notification.isRead
              ? theme.colorScheme.primary.withAlpha(100)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap ??
            () {
              // Mark notification as read
              if (!notification.isRead) {
                // This is handled by the parent widget's onTap
              }

              // Handle navigation based on action URL
              if (notification.actionUrl != null &&
                  notification.actionUrl!.isNotEmpty) {
                context.go(notification.actionUrl!);
              }
            },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: notification.isRead
                    ? theme.cardColor
                    : theme.colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNotificationIcon(theme, isDarkMode),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: notification.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withAlpha(200),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formattedTime,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withAlpha(150),
                              ),
                            ),
                            if (propertyPrice != null)
                              Text(
                                propertyPrice,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onDelete,
                      color: theme.colorScheme.error.withAlpha(180),
                      tooltip: 'Delete notification',
                    ),
                  ],
                ],
              ),
            ),

            // Show property image if available
            if (hasPropertyImage &&
                notification.metadata!['propertyImage'] != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: theme.dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Image.network(
                    notification.metadata!['propertyImage'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(ThemeData theme, bool isDarkMode) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.propertyListed:
        icon = Icons.home;
        color = Colors.green;
        break;
      case NotificationType.priceChange:
        icon = Icons.attach_money;
        color = Colors.orange;
        break;
      case NotificationType.statusChange:
        icon = Icons.info;
        color = Colors.blue;
        break;
      case NotificationType.chat:
        icon = Icons.chat;
        color = Colors.purple;
        break;
      case NotificationType.system:
        icon = Icons.notifications;
        color = Colors.grey;
        break;
      case NotificationType.reminder:
        icon = Icons.alarm;
        color = Colors.red;
        break;
      case NotificationType.custom:
        icon = Icons.star;
        color = Colors.amber;
        break;
      case NotificationType.other:
      default:
        icon = Icons.notifications;
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }
}
