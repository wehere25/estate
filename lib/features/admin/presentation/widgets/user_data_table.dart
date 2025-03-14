import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/admin_user.dart';

class UserDataTable extends StatefulWidget {
  final List<AdminUser> users;
  final Function(AdminUser user, bool isAdmin) onRoleChanged;

  const UserDataTable({
    Key? key,
    required this.users,
    required this.onRoleChanged,
  }) : super(key: key);

  @override
  State<UserDataTable> createState() => _UserDataTableState();
}

class _UserDataTableState extends State<UserDataTable> {
  List<bool> _selected = [];
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  List<AdminUser> _sortedUsers = [];

  @override
  void initState() {
    super.initState();
    _selected = List.generate(widget.users.length, (index) => false);
    _sortedUsers = List.from(widget.users);
    _sortUsers();
  }

  @override
  void didUpdateWidget(UserDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.users != widget.users) {
      _selected = List.generate(widget.users.length, (index) => false);
      _sortedUsers = List.from(widget.users);
      _sortUsers();
    }
  }

  bool get _hasSelection => _selected.contains(true);

  void _sort(int columnIndex) {
    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = columnIndex;
        _sortAscending = true;
      }
      _sortUsers();
    });
  }

  void _sortUsers() {
    _sortedUsers.sort((a, b) {
      switch (_sortColumnIndex) {
        case 0: // Name
          return _sortAscending
              ? a.displayName.compareTo(b.displayName)
              : b.displayName.compareTo(a.displayName);
        case 1: // Email
          return _sortAscending
              ? a.email.compareTo(b.email)
              : b.email.compareTo(a.email);
        case 2: // Status
          return _sortAscending
              ? a.status.compareTo(b.status)
              : b.status.compareTo(a.status);
        case 3: // Admin
          return _sortAscending
              ? (a.isAdmin ? 1 : 0).compareTo(b.isAdmin ? 1 : 0)
              : (b.isAdmin ? 1 : 0).compareTo(a.isAdmin ? 1 : 0);
        default:
          return 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _hasSelection ? _buildSelectionActions() : _buildTableHeader(),
        const SizedBox(height: 8),
        Expanded(
          child: _buildUserTableContainer(),
        ),
      ],
    );
  }

  Widget _buildUserTableContainer() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTableHeaders(),
          Expanded(
            child: _sortedUsers.isEmpty
                ? const Center(child: Text("No users available"))
                : SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 24,
                        headingRowHeight: 0, // Headers are already shown above
                        dataRowMinHeight: 60,
                        dataRowMaxHeight: 60,
                        columns: const [
                          DataColumn(label: SizedBox(width: 50)),
                          DataColumn(label: SizedBox(width: 200)),
                          DataColumn(label: SizedBox(width: 250)),
                          DataColumn(label: SizedBox(width: 120)),
                          DataColumn(label: SizedBox(width: 120)),
                          DataColumn(label: SizedBox(width: 120)),
                        ],
                        rows: _buildDataRows(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<DataRow> _buildDataRows() {
    return List.generate(
      _sortedUsers.length,
      (index) {
        final user = _sortedUsers[index];
        return DataRow(
          color: WidgetStatePropertyAll<Color?>(
            _selected[index]
                ? Colors.blue.withValues(
                    alpha: 26.0, red: 33.0, green: 150.0, blue: 243.0)
                : null,
          ),
          cells: [
            DataCell(
              Checkbox(
                value: _selected[index],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selected[index] = value;
                    });
                  }
                },
              ),
            ),
            DataCell(
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontSize: 12),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      user.displayName.isNotEmpty
                          ? user.displayName
                          : 'No Name',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            DataCell(
              Text(
                user.email,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DataCell(_buildStatusBadge(user.status)),
            DataCell(Text(user.isAdmin ? 'Admin' : 'User')),
            DataCell(
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Switch(
                    value: user.isAdmin,
                    onChanged: (value) =>
                        _showRoleConfirmationDialog(user, value),
                  ),
                  _buildStatusToggleButton(user),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTableHeaders() {
    return Container(
      color: Colors.grey.shade200,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(
                width: 50,
                child: Checkbox(
                  value: _selected.isNotEmpty && _selected.every((s) => s),
                  tristate:
                      _selected.contains(true) && _selected.contains(false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selected = List.generate(
                            widget.users.length, (index) => value);
                      });
                    }
                  },
                ),
              ),
              SizedBox(
                width: 200,
                child: _buildHeaderCell("Name", 0),
              ),
              SizedBox(
                width: 250,
                child: _buildHeaderCell("Email", 1),
              ),
              SizedBox(
                width: 120,
                child: _buildHeaderCell("Status", 2),
              ),
              SizedBox(
                width: 120,
                child: _buildHeaderCell("Role", 3),
              ),
              const SizedBox(width: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String title, int columnIndex) {
    return InkWell(
      onTap: () => _sort(columnIndex),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_sortColumnIndex == columnIndex)
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusToggleButton(AdminUser user) {
    return IconButton(
      icon: Icon(
        user.status == 'active' ? Icons.block : Icons.check_circle,
        size: 18,
        color: user.status == 'active' ? Colors.red : Colors.green,
      ),
      onPressed: () => _toggleUserStatus(user),
      tooltip: user.status == 'active' ? 'Block' : 'Activate',
    );
  }

  Widget _buildTableHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'All Users (${widget.users.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            Provider.of<AdminProvider>(context, listen: false).loadUsers();
          },
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildSelectionActions() {
    final selectedCount = _selected.where((s) => s).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.lightColorScheme.primary.withValues(
            alpha: 26.0,
            red: AppColors.lightColorScheme.primary.red.toDouble(),
            green: AppColors.lightColorScheme.primary.green.toDouble(),
            blue: AppColors.lightColorScheme.primary.blue.toDouble()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '$selectedCount selected',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              final selectedUsers = _getSelectedUsers();
              _showRoleBulkUpdateDialog(selectedUsers);
            },
            child: const Text('Change Role'),
          ),
          TextButton(
            onPressed: () {
              final selectedUsers = _getSelectedUsers();
              _showExportDialog(selectedUsers);
            },
            child: const Text('Export'),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _selected =
                    List.generate(widget.users.length, (index) => false);
              });
            },
            tooltip: 'Clear selection',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color baseColor;
    String label;
    switch (status) {
      case 'active':
        baseColor = Colors.green;
        label = 'Active';
        break;
      case 'disabled':
        baseColor = Colors.red;
        label = 'Disabled';
        break;
      case 'pending':
        baseColor = Colors.orange;
        label = 'Pending';
        break;
      default:
        baseColor = Colors.grey;
        label = status.isEmpty ? 'Unknown' : status;
    }

    final color = baseColor.withValues(
        alpha: 26.0,
        red: baseColor.red.toDouble(),
        green: baseColor.green.toDouble(),
        blue: baseColor.blue.toDouble());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: baseColor),
      ),
      child: Text(
        label,
        style: TextStyle(color: baseColor, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  List<AdminUser> _getSelectedUsers() {
    final List<AdminUser> selectedUsers = [];
    for (int i = 0; i < _sortedUsers.length; i++) {
      if (_selected[i]) {
        selectedUsers.add(_sortedUsers[i]);
      }
    }
    return selectedUsers;
  }

  void _showRoleConfirmationDialog(AdminUser user, bool makeAdmin) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(makeAdmin ? 'Grant Admin Access' : 'Revoke Admin Access'),
        content: Text(
          makeAdmin
              ? 'Are you sure you want to grant admin access to ${user.displayName}?'
              : 'Are you sure you want to revoke admin access from ${user.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              widget.onRoleChanged(user, makeAdmin);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _toggleUserStatus(AdminUser user) {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final newStatus = user.status == 'active' ? 'disabled' : 'active';

    // Show confirmation dialog before changing status
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(newStatus == 'active' ? 'Activate User' : 'Block User'),
        content: Text(
            'Are you sure you want to ${newStatus == 'active' ? 'activate' : 'block'} ${user.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Updating user status...'),
                duration: Duration(seconds: 1),
              ));

              try {
                await adminProvider.updateUserStatus(user.uid, newStatus);

                if (!mounted) return;

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      'User ${newStatus == 'active' ? 'activated' : 'blocked'} successfully'),
                  backgroundColor: Colors.green,
                ));
              } catch (e) {
                if (!mounted) return;

                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text('Failed to update user status: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ));
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showRoleBulkUpdateDialog(List<AdminUser> users) {
    bool makeAdmin = false;
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: const Text('Update User Roles'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selected users: ${users.length}'),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Make Users Admins'),
                  subtitle: const Text('Grant admin privileges'),
                  value: makeAdmin,
                  onChanged: (value) {
                    setState(() {
                      makeAdmin = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final userIds = users.map((u) => u.uid).toList();
                  adminProvider.bulkUpdateUserRoles(userIds, makeAdmin);
                  Navigator.pop(dialogContext);
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showExportDialog(List<AdminUser> users) {
    late BuildContext dialogContext;
    showDialog(
      context: context,
      builder: (ctx) {
        dialogContext = ctx;
        return AlertDialog(
          title: const Text('Export Users'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ready to export ${users.length} users'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.description),
                label: const Text('Export to CSV'),
                onPressed: () => _handleExport(dialogContext, users),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleExport(
      BuildContext dialogContext, List<AdminUser> users) async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    Navigator.pop(dialogContext);

    try {
      final csvData = await adminProvider.exportUsersToCSV();
      if (!mounted) return;

      final scaffoldMessenger = ScaffoldMessenger.of(context);
      if (csvData.isNotEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Users exported to CSV')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting users: $e')),
      );
    }
  }
}
