import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/saved_search.dart';

class SavedSearchTile extends StatelessWidget {
  final SavedSearch savedSearch;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleNotifications;

  const SavedSearchTile({
    Key? key,
    required this.savedSearch,
    required this.onTap,
    required this.onDelete,
    required this.onToggleNotifications,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final lastUsedDate = savedSearch.lastUsedAt ?? savedSearch.createdAt;
    final formattedDate = dateFormat.format(lastUsedDate);

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      savedSearch.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      savedSearch.notificationsEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      color: savedSearch.notificationsEnabled
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                    onPressed: () => onToggleNotifications(
                        !savedSearch.notificationsEnabled),
                    tooltip: savedSearch.notificationsEnabled
                        ? 'Disable notifications'
                        : 'Enable notifications',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Search: ${savedSearch.query.isEmpty ? "All properties" : savedSearch.query}',
                style: const TextStyle(fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (savedSearch.filters.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Filters: ${savedSearch.filters.length} ${savedSearch.filters.length == 1 ? 'filter' : 'filters'} applied',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Last used: $formattedDate',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Used ${savedSearch.usageCount} ${savedSearch.usageCount == 1 ? 'time' : 'times'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
