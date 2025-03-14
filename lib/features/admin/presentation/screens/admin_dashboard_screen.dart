import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/admin_provider.dart';
import '../widgets/user_data_table.dart';
import '../widgets/stats_card.dart';
import '../../domain/models/admin_user.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_text_field.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<AdminUser> _filteredUsers = [];
  final List<String> _selectedPropertyIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Use post-frame callback to avoid initialization during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);

      // Initialize provider if needed
      if (!adminProvider.isInitialized) {
        await adminProvider.preInitialize();
      }

      // Load data sequentially to avoid state conflicts
      await adminProvider.loadDashboardStats();
      await adminProvider.loadUsers();
      await adminProvider.loadActivityLogs();

      // Update filtered users after data is loaded
      if (mounted) {
        _updateFilteredUsers(adminProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading dashboard data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateFilteredUsers(AdminProvider provider) {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = query.isEmpty
          ? List.from(provider.users)
          : provider.users.where((user) {
              return user.email.toLowerCase().contains(query) ||
                  user.displayName.toLowerCase().contains(query);
            }).toList();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        // Show loading indicator while initializing
        if (_isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing admin panel...'),
                ],
              ),
            ),
          );
        }

        // Show error if initialization failed
        if (provider.error != null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(provider.error ?? 'Unknown error'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // Rest of your existing build method
        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
            backgroundColor: AppColors.lightColorScheme.primary,
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Analytics'),
                Tab(text: 'Users'),
                Tab(text: 'Content Moderation'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _initializeData,
                tooltip: 'Refresh Data',
              ),
            ],
          ),
          drawer: _buildAdminNavigationDrawer(),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildAnalyticsTabWithConstraints(provider),
              _buildUsersTabWithConstraints(provider),
              _buildContentModerationTabWithConstraints(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTabWithConstraints(AdminProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard Analytics',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),

                // Quick navigation cards
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildQuickNavigation(),
                ),

                const SizedBox(height: 32),

                // Summary cards row using StatsCard widget
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      StatsCard(
                        title: 'Total Properties',
                        value: provider.stats.totalProperties.toString(),
                        icon: Icons.home,
                        color: Colors.white,
                        onTap: () => context.push('/admin/properties'),
                      ),
                      const SizedBox(width: 16),
                      StatsCard(
                        title: 'Active Users',
                        value: provider.stats.activeUsers.toString(),
                        icon: Icons.people,
                        color: Colors.white,
                        onTap: () => context.push('/admin/users'),
                      ),
                      const SizedBox(width: 16),
                      StatsCard(
                        title: 'Pending Reviews',
                        value: provider.stats.pendingReviews.toString(),
                        icon: Icons.rate_review,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUsersTabWithConstraints(AdminProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          AppTextField(
            controller: _searchController,
            hintText: 'Search users by name or email',
            prefixIcon: const Icon(Icons.search),
            onChanged: (value) {
              _updateFilteredUsers(provider);
            },
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _updateFilteredUsers(provider);
                    },
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: UserDataTable(
              users: _filteredUsers,
              onRoleChanged: (user, isAdmin) {
                provider.toggleUserRole(user, isAdmin);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentModerationTabWithConstraints(AdminProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: constraints.maxHeight,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModerationHeader(provider.flaggedProperties.length),
              const SizedBox(height: 16),
              Expanded(
                child: provider.flaggedProperties.isEmpty
                    ? const Center(child: Text('No flagged content to review'))
                    : ListView.builder(
                        itemCount: provider.flaggedProperties.length,
                        itemBuilder: (context, index) {
                          final property = provider.flaggedProperties[index];
                          final isSelected =
                              _selectedPropertyIds.contains(property['id']);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ExpansionTile(
                              leading: Icon(
                                isSelected
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                color: isSelected ? Colors.green : null,
                              ),
                              title: Text(property['title']),
                              subtitle:
                                  Text('Flagged by: ${property['flaggedBy']}'),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Reason: ${property['flagReason']}'),
                                      const SizedBox(height: 8),
                                      Text(
                                          'Description: ${property['description']}'),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                if (isSelected) {
                                                  _selectedPropertyIds
                                                      .remove(property['id']);
                                                } else {
                                                  _selectedPropertyIds
                                                      .add(property['id']);
                                                }
                                              });
                                            },
                                            child: Text(isSelected
                                                ? 'Deselect'
                                                : 'Select'),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () {
                                              // Handle content moderation action
                                              provider.moderateContent(
                                                  property['id'], 'approve');
                                            },
                                            child: const Text('Take Action'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // New method to build the admin navigation drawer
  Widget _buildAdminNavigationDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('Admin Panel'),
            accountEmail: Text(
                'Logged in as ${FirebaseAuth.instance.currentUser?.email ?? 'Admin'}'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.admin_panel_settings,
                  size: 40, color: Colors.blue),
            ),
            decoration: BoxDecoration(
              color: AppColors.lightColorScheme.primary,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: true,
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Manage Users'),
            onTap: () {
              Navigator.pop(context);
              context.push('/admin/users');
            },
          ),
          ListTile(
            leading: const Icon(Icons.home_work),
            title: const Text('Manage Properties'),
            onTap: () {
              Navigator.pop(context);
              context.push('/admin/properties');
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_home),
            title: const Text('Add New Property'),
            onTap: () {
              Navigator.pop(context);
              context.push('/property/add');
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Analytics'),
            onTap: () {
              Navigator.pop(context);
              context.push('/admin/analytics');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to settings when implemented
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Exit Admin Panel'),
            onTap: () {
              Navigator.pop(context);
              context.go('/home');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickNavigation() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    'Add Property',
                    Icons.add_home,
                    Colors.green,
                    () => context.push('/property/add'),
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    'Manage Users',
                    Icons.people,
                    Colors.blue,
                    () => context.push('/admin/users'),
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    'Manage Properties',
                    Icons.home_work,
                    Colors.orange,
                    () => context.push('/admin/properties'),
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    'View Analytics',
                    Icons.analytics,
                    Colors.purple,
                    () => context.push('/admin/analytics'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha((0.1 * 255).round()),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModerationHeader(int flaggedCount) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Flagged Content ($flaggedCount)',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        ElevatedButton(
          onPressed: _selectedPropertyIds.isEmpty
              ? null
              : () {
                  // Handle bulk action on selected properties
                },
          child: const Text('Bulk Action'),
        ),
      ],
    );
  }
}
