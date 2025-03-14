import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.lightColorScheme.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          NotificationItem(
            title: 'Price Drop',
            message: 'A property you liked has reduced its price by 5%',
            time: '2 hours ago',
            isRead: false,
          ),
          NotificationItem(
            title: 'New Property Match',
            message: 'A new property matching your search criteria was added',
            time: '1 day ago',
            isRead: true,
          ),
          NotificationItem(
            title: 'Viewing Reminder',
            message: 'Your property viewing is scheduled for tomorrow at 2 PM',
            time: '2 days ago',
            isRead: true,
          ),
        ],
      ),
    );
  }
}

class NotificationItem extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final bool isRead;

  const NotificationItem({
    Key? key,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isRead 
              ? Colors.grey.shade200
              : AppColors.lightColorScheme.primaryContainer,
          child: Icon(
            Icons.notifications,
            color: isRead 
              ? Colors.grey.shade600
              : AppColors.lightColorScheme.primary,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(message),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        trailing: isRead 
            ? null
            : Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.lightColorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }
}
