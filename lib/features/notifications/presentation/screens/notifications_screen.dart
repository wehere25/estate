import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/models/notification_type.dart';
import '../widgets/notification_card.dart';
import 'package:azharapp/features/auth/domain/providers/auth_provider.dart';
import '../../../../core/utils/dev_utils.dart';
import '../../../../core/navigation/app_scaffold.dart';

class NotificationsScreen extends StatefulWidget {
  final bool showNavBar;

  const NotificationsScreen({Key? key, this.showNavBar = true})
      : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animation controller for smoother UI transitions
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeNotifications() {
    // Access the auth provider to get the user ID
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid ?? DevUtils.devUserId;
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    // Initialize and listen for notifications
    notificationProvider.initialize(userId);
    DevUtils.log('Initialized notifications for user $userId');
  }

  // Show a confirmation dialog for deleting all notifications
  Future<bool> _confirmDeleteAll(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete All Notifications'),
            content: const Text(
                'Are you sure you want to delete all notifications? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete All',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Delete all notifications
  Future<void> _deleteAllNotifications(String userId) async {
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    await notificationProvider.deleteAllNotifications(userId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications deleted'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid ?? DevUtils.devUserId;
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Notifications',
      showNavBar: widget.showNavBar,
      actions: [
        // Refresh button
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh notifications',
          onPressed: () {
            _initializeNotifications();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Refreshing notifications...'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
        if (notificationProvider.notifications.isNotEmpty) ...[
          // Mark all as read button
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: 'Mark all as read',
            onPressed: () {
              notificationProvider.markAllAsRead(userId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read'),
                ),
              );
            },
          ),
          // Delete all button with popup menu for confirmation
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete all notifications',
            onPressed: () async {
              final confirmed = await _confirmDeleteAll(context);
              if (confirmed) {
                await _deleteAllNotifications(userId);
              }
            },
          ),
        ],
      ],
      body: notificationProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: _buildNotificationsList(notificationProvider, userId),
            ),
    );
  }

  Widget _buildNotificationsList(
      NotificationProvider notificationProvider, String userId) {
    final notifications = notificationProvider.notifications;

    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        _initializeNotifications();
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: notifications.length + 1, // +1 for the header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader(notifications);
          }

          final notification = notifications[index - 1];
          return NotificationCard(
            notification: notification,
            onTap: () {
              notificationProvider.markAsRead(notification.id);
            },
            onDelete: () {
              notificationProvider.deleteNotification(notification.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification deleted'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(List<NotificationModel> notifications) {
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You have $unreadCount unread ${unreadCount == 1 ? 'notification' : 'notifications'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: unreadCount > 0
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No notifications yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'We\'ll notify you when there\'s something new',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _initializeNotifications,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
