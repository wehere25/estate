import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/notification_model.dart'; // Updated import path

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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? theme.cardColor
                : theme.colorScheme.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? theme.dividerColor
                  : theme.colorScheme.primary.withAlpha(50),
              width: 1,
            ),
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
                    Text(
                      notification.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.textTheme.bodyMedium?.color?.withAlpha(200),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formattedTime,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withAlpha(150),
                      ),
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
      case NotificationType.other:
        icon = Icons.notifications;
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDarkMode ? color.withAlpha(40) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }
}
