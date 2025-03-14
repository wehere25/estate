import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/audit_log.dart';

class AuditLogList extends StatelessWidget {
  final List<Map<String, dynamic>> logs;
  final bool showHeader;
  final bool enableSelection;
  final Function(List<AuditLog>)? onBulkAction;
  final VoidCallback? onRefresh;
  final bool compact;

  const AuditLogList({
    Key? key,
    required this.logs,
    this.showHeader = true,
    this.enableSelection = false,
    this.onBulkAction,
    this.onRefresh,
    this.compact = false,
  }) : super(key: key);

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        return 'Invalid date';
      }

      return DateFormat('MMM d, y h:mm a').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'create':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      case 'login':
        return Colors.purple;
      case 'grant_admin':
        return Colors.amber;
      case 'revoke_admin':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'create':
        return Icons.add_circle_outline;
      case 'update':
        return Icons.edit_outlined;
      case 'delete':
        return Icons.delete_outline;
      case 'login':
        return Icons.login;
      case 'grant_admin':
        return Icons.admin_panel_settings;
      case 'revoke_admin':
        return Icons.no_accounts;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No logs to display'),
            if (onRefresh != null)
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                onPressed: onRefresh,
              ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          if (showHeader) _buildHeader(),
          Expanded(
            child: logs.isEmpty
                ? const Center(child: Text('No activity logs'))
                : SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width - 32,
                        ),
                        child: DataTable(
                          columnSpacing: 24,
                          horizontalMargin: 16,
                          columns: const [
                            DataColumn(label: Text('Action')),
                            DataColumn(label: Text('User')),
                            DataColumn(label: Text('Details')),
                            DataColumn(label: Text('Time')),
                          ],
                          rows: logs.map((log) => _buildLogRow(log)).toList(),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Activity Logs',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            '${logs.length} entries',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  DataRow _buildLogRow(Map<String, dynamic> log) {
    return DataRow(
      cells: [
        DataCell(_buildActionCell(log['action'] ?? 'unknown')),
        DataCell(Text(log['userId'] ?? 'System')),
        DataCell(_buildDetailsCell(log)),
        DataCell(Text(_formatTimestamp(log['timestamp']))),
      ],
    );
  }

  Widget _buildActionCell(String action) {
    Color color;
    IconData icon;

    switch (action) {
      case 'user_create':
        color = Colors.green;
        icon = Icons.person_add;
        break;
      case 'user_update':
        color = Colors.blue;
        icon = Icons.edit;
        break;
      case 'user_delete':
        color = Colors.red;
        icon = Icons.person_remove;
        break;
      case 'grant_admin_role':
      case 'revoke_admin_role':
        color = Colors.purple;
        icon = Icons.admin_panel_settings;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info_outline;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(_formatAction(action)),
      ],
    );
  }

  Widget _buildDetailsCell(Map<String, dynamic> log) {
    final metadata = log['metadata'] as Map<String, dynamic>?;
    if (metadata == null || metadata.isEmpty) {
      return const Text('No details available');
    }

    String details = '';
    metadata.forEach((key, value) {
      if (value != null) {
        details += '$key: $value, ';
      }
    });

    // Remove trailing comma and space
    if (details.isNotEmpty) {
      details = details.substring(0, details.length - 2);
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Text(
        details,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    );
  }

  String _formatAction(String action) {
    return action.split('_').map((word) {
      return word.substring(0, 1).toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
