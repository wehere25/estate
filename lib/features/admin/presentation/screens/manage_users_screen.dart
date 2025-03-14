import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../widgets/user_data_table.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_text_field.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({Key? key}) : super(key: key);

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await Provider.of<AdminProvider>(context, listen: false).loadUsers();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: AppColors.lightColorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Help',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: _buildContent(),
            ),
    );
  }

  Widget _buildContent() {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        final filteredUsers = _searchController.text.isEmpty
            ? provider.users
            : provider.users.where((user) {
                final query = _searchController.text.toLowerCase();
                return user.displayName.toLowerCase().contains(query) ||
                    user.email.toLowerCase().contains(query);
              }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildSearchAndFilters(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: filteredUsers.isEmpty && provider.users.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No users match "${_searchController.text}"',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              child: const Text('Clear search'),
                            ),
                          ],
                        ),
                      )
                    : filteredUsers.isEmpty
                        ? const Center(
                            child: Text('No users available'),
                          )
                        : UserDataTable(
                            users: filteredUsers,
                            onRoleChanged: (user, isAdmin) {
                              provider.toggleUserRole(user, isAdmin);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isAdmin
                                        ? 'Admin role granted to ${user.displayName}'
                                        : 'Admin role removed from ${user.displayName}',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _searchController,
          hintText: 'Search users by name or email',
          prefixIcon: const Icon(Icons.search),
          onChanged: (_) => setState(() {}),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip('All Users', true),
              _buildFilterChip('Admins', false),
              _buildFilterChip('Regular Users', false),
              _buildFilterChip('Active', false),
              _buildFilterChip('Disabled', false),
              _buildFilterChip('New (7 days)', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          // Filter logic would be implemented here
        },
        selectedColor: AppColors.lightColorScheme.primary.withOpacity(0.2),
        showCheckmark: true,
        checkmarkColor: AppColors.lightColorScheme.primary,
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Management Help'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'User Management',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Use the search box to find users by name or email\n'
                '• Click on column headers to sort the table\n'
                '• Toggle the admin switch to grant or revoke admin privileges\n'
                '• Select multiple users with checkboxes for bulk actions',
              ),
              SizedBox(height: 16),
              Text(
                'User Roles',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Admin: Full access to admin panel and management features\n'
                '• User: Regular user access only',
              ),
              SizedBox(height: 16),
              Text(
                'User Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Active: User can access the platform normally\n'
                '• Disabled: User access is restricted\n'
                '• Pending: User registration is awaiting approval',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
