import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '/core/constants/app_colors.dart';
import '/core/utils/snackbar_utils.dart';
import '/features/favorites/providers/favorites_provider.dart';
import '/core/theme/theme_provider.dart';
import '/core/services/global_auth_service.dart' show GlobalAuthService;
import '../../../../features/auth/domain/providers/auth_provider.dart';
import '../../../../features/auth/domain/services/admin_service.dart';

class ProfileScreen extends StatelessWidget {
  final bool showNavBar;

  const ProfileScreen({Key? key, this.showNavBar = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return showNavBar
        ? Scaffold(
            appBar: AppBar(
              title: const Text('My Profile'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    // Create settings modal function inline
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => const _SettingsModalContent(),
                    );
                  },
                ),
              ],
            ),
            body: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                return const _ProfileScreenContent();
              },
            ),
          )
        : const _ProfileScreenContent(); // Just return the content without wrapping in scaffold when used in shell
  }
}

// Extract settings modal to a separate widget
class _SettingsModalContent extends StatefulWidget {
  const _SettingsModalContent({Key? key}) : super(key: key);

  @override
  State<_SettingsModalContent> createState() => _SettingsModalContentState();
}

class _SettingsModalContentState extends State<_SettingsModalContent> {
  bool _isDarkMode = false;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    final savedDarkMode = _prefs.getBool('settings_dark_mode') ?? false;

    if (mounted) {
      setState(() {
        _isDarkMode = savedDarkMode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Dark Mode Toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable dark theme for the app'),
            value: _isDarkMode,
            onChanged: (value) {
              setState(() => _isDarkMode = value);
            },
          ),

          const SizedBox(height: 16),

          // Apply Button with proper mounted checks
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyThemeChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightColorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Apply Theme'),
            ),
          ),

          // Add extra space for bottom padding
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
        ],
      ),
    );
  }

  Future<void> _applyThemeChanges() async {
    try {
      await _prefs.setBool('settings_dark_mode', _isDarkMode);

      if (!mounted) return;

      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

      if (_isDarkMode != themeProvider.isDarkMode) {
        await themeProvider.toggleTheme();
      }

      if (!mounted) return;

      // Store context before Navigator.pop()
      final currentContext = context;
      Navigator.pop(currentContext);

      if (mounted) {
        SnackBarUtils.showSuccessSnackBar(
            currentContext, 'Theme settings updated');
      }
    } catch (e) {
      debugPrint('Error applying theme changes: $e');
      if (mounted) {
        SnackBarUtils.showErrorSnackBar(
            context, 'Failed to update theme settings');
      }
    }
  }
}

class _ProfileScreenContent extends StatefulWidget {
  const _ProfileScreenContent({Key? key}) : super(key: key);

  @override
  State<_ProfileScreenContent> createState() => _ProfileScreenContentState();
}

class _ProfileScreenContentState extends State<_ProfileScreenContent> {
  // User data with SharedPreferences integration
  late SharedPreferences _prefs;
  final Map<String, dynamic> _userData = {
    'name': 'John Doe',
    'email': 'john.doe@example.com',
    'phone': '+1 (555) 123-4567',
    'profileImage': 'https://randomuser.me/api/portraits/men/32.jpg',
    'joinDate':
        DateTime.now().subtract(const Duration(days: 365)).toIso8601String(),
    'role': 'User',
    'bio': 'Passionate about real estate and finding the perfect home.',
  };

  // UI state
  bool _isDarkMode = false;
  bool _isLoading = false;
  File? _imageFile;

  // Form controllers for editing
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Get the current theme mode
    _loadThemeSettings();
    debugPrint('ProfileScreen: Building screen');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Load user data from SharedPreferences with fixed context usage
  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      _prefs = await SharedPreferences.getInstance();

      if (!mounted) return;
      setState(() {
        _userData['name'] = _prefs.getString('user_name') ?? _userData['name'];
        _userData['email'] =
            _prefs.getString('user_email') ?? _userData['email'];
        _userData['profileImage'] =
            _prefs.getString('user_profile_image') ?? _userData['profileImage'];
        _userData['bio'] = _prefs.getString('user_bio') ?? _userData['bio'];
        _userData['role'] = _prefs.getString('user_role') ?? _userData['role'];
        _userData['joinDate'] =
            _prefs.getString('user_join_date') ?? _userData['joinDate'];

        // Load theme settings only
        _isDarkMode = _prefs.getBool('settings_dark_mode') ?? false;

        // Initialize controllers
        _nameController.text = _userData['name'];
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (!mounted) return;

      // Store context reference for safe usage
      final currentContext = context;
      SnackBarUtils.showErrorSnackBar(
          currentContext, 'Failed to load user data');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Simplified save user data method
  Future<void> _saveUserData() async {
    setState(() => _isLoading = true);

    try {
      await _prefs.setString('user_name', _userData['name']);
      await _prefs.setString('user_email', _userData['email']);
      await _prefs.setString('user_profile_image', _userData['profileImage']);
      await _prefs.setString('user_join_date', _userData['joinDate']);

      // Save only dark mode setting
      await _prefs.setBool('settings_dark_mode', _isDarkMode);

      if (mounted) {
        // Store context for safe usage
        final currentContext = context;
        SnackBarUtils.showSuccessSnackBar(
            currentContext, 'Profile updated successfully');
      }
    } catch (e) {
      debugPrint('Error saving user data: $e');
      if (mounted) {
        // Store context for safe usage
        final currentContext = context;
        SnackBarUtils.showErrorSnackBar(
            currentContext, 'Failed to save user data');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Fixed _loadThemeSettings with better context usage
  void _loadThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Get the value from SharedPreferences
    final savedDarkMode = prefs.getBool('settings_dark_mode') ?? false;

    // Ensure we're in sync with the ThemeProvider
    if (mounted) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

      // Only update state if there's a mismatch - prevents unnecessary state changes
      if (savedDarkMode != themeProvider.isDarkMode) {
        setState(() {
          _isDarkMode = themeProvider.isDarkMode;
        });
      } else {
        setState(() {
          _isDarkMode = savedDarkMode;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('ProfileScreen: Building screen');

    return Scaffold(
      // Remove the duplicate AppBar here since it's already in the parent ProfileScreen
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(),
                  const Divider(height: 32),
                  _buildProfileOptions(),
                  const Divider(height: 32),
                  _buildPropertyStatistics(),
                  const Divider(height: 32),
                  _buildAccountOptions(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile image with photo management options
          GestureDetector(
            onTap: () => _showImageOptions(),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _imageFile != null
                      ? FileImage(File(_imageFile!.path)) as ImageProvider
                      : (_userData['profileImage'].toString().startsWith('http')
                          ? NetworkImage(_userData['profileImage'])
                              as ImageProvider
                          : FileImage(File(_userData['profileImage']))
                              as ImageProvider),
                ),
                CircleAvatar(
                  backgroundColor: AppColors.lightColorScheme.primary,
                  radius: 18,
                  child: const Icon(Icons.camera_alt,
                      color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // User name only - simplified
          Text(
            _userData['name'],
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            _userData['email'],
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),

          // Join date
          const SizedBox(height: 8),
          Text(
            'Member since ${_formatDate(DateTime.parse(_userData['joinDate']))}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),

          // Edit profile button
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _navigateToEditProfile(),
            icon: const Icon(Icons.edit),
            label: const Text('Edit Name'), // Changed to Edit Name for clarity
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.lightColorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Activity',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Favorites with real counts from the provider
          _buildProfileTile(
            icon: Icons.favorite,
            title: 'Favorites',
            subtitle: 'Properties you\'ve saved',
            onTap: () => context.push('/favorites'),
            trailing: Consumer<FavoritesProvider>(
              builder: (_, provider, __) => provider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('${provider.favorites.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),

          // Recently viewed with count from shared preferences
          _buildProfileTile(
            icon: Icons.history,
            title: 'Recently Viewed',
            subtitle: 'Properties you\'ve browsed',
            onTap: () => _navigateToRecentlyViewed(),
            trailing: Text(
                '${_prefs.getStringList('recently_viewed_properties')?.length ?? 0}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),

          // Saved searches with count from shared preferences
          _buildProfileTile(
            icon: Icons.search,
            title: 'Saved Searches',
            subtitle: 'Your saved search criteria',
            onTap: () => _navigateToSavedSearches(),
            trailing: Text(
                '${_prefs.getStringList('saved_searches')?.length ?? 0}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyStatistics() {
    // Check if the user is an admin
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bool isAdmin = authProvider.user != null &&
        AdminService.isUserAdmin(authProvider.user);

    // If user is an admin, display admin options
    if (isAdmin) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Dashboard',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    count: 1,
                    color: Colors.purple,
                    onTap: () => context.push('/admin/dashboard'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.people,
                    title: 'Users',
                    count:
                        0, // Using default value instead of non-existent userCount property
                    color: Colors.blue,
                    onTap: () => context.push('/admin/users'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.home_work,
                    title: 'Properties',
                    count: _prefs.getStringList('user_listings')?.length ?? 0,
                    color: Colors.green,
                    onTap: () => context.push('/admin/properties'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // For non-admin users, display the original property statistics
    // Get actual stats from shared preferences
    final listingCount = _prefs.getStringList('user_listings')?.length ?? 0;
    final viewCount = _prefs.getInt('total_property_views') ?? 0;
    final favoriteCount = _prefs.getInt('favorited_by_others_count') ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Properties',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.home,
                  title: 'Listed',
                  count: listingCount,
                  color: Colors.blue,
                  onTap: () => _navigateToMyProperties('listed'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.visibility,
                  title: 'Viewed',
                  count: viewCount,
                  color: Colors.green,
                  onTap: () => _navigateToMyProperties('views'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.star,
                  title: 'Favorited',
                  count: favoriteCount,
                  color: Colors.orange,
                  onTap: () => _navigateToMyProperties('favorites'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Add Notifications option
          _buildProfileTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'View your alerts and messages',
            onTap: () => context.push('/notifications'),
          ),

          // Existing options
          _buildProfileTile(
            icon: Icons.lock,
            title: 'Change Password',
            subtitle: 'Update your security credentials',
            onTap: () => _navigateToChangePassword(),
          ),

          _buildProfileTile(
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'Contact us for assistance',
            onTap: () => _navigateToSupport(),
          ),

          _buildProfileTile(
            icon: Icons.info,
            title: 'About',
            subtitle: 'App information and legal',
            onTap: () => _navigateToAbout(),
          ),

          _buildProfileTile(
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Log out of your account',
            onTap: () => _showSignOutDialog(),
            iconColor: Colors.red,
            titleColor: Colors.red,
          ),
        ],
      ),
    );
  }

  // Profile tile with consistent styling
  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    Color? iconColor,
    Color? titleColor,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor:
            (iconColor ?? AppColors.lightColorScheme.primary).withAlpha(26),
        child:
            Icon(icon, color: iconColor ?? AppColors.lightColorScheme.primary),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: titleColor,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  // Statistics card with consistent styling
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show photo options (take photo, choose from gallery, remove)
  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takeProfilePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickProfilePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfilePhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Fix other async methods with proper context handling
  Future<void> _takeProfilePhoto() async {
    debugPrint('ProfileScreen: Taking profile photo');
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 600,
        maxHeight: 600,
      );

      // Store reference before async gap
      final BuildContext? contextRef = mounted ? context : null;

      if (image != null && mounted) {
        setState(() {
          _imageFile = File(image.path);
          _userData['profileImage'] = image.path;
        });

        // Save to shared preferences
        await _prefs.setString('user_profile_image', image.path);

        // Check mounted again after async operation
        if (mounted && contextRef != null) {
          SnackBarUtils.showSuccessSnackBar(
              contextRef, 'Profile photo updated');
        }
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      // Store reference before potential async gap
      final BuildContext? contextRef = mounted ? context : null;
      if (mounted && contextRef != null) {
        SnackBarUtils.showErrorSnackBar(contextRef, 'Failed to take photo');
      }
    }
  }

  // Update _signOut method to fix context handling
  Future<void> _handleSignOut() async {
    debugPrint('ProfileScreen: Signing out');
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final globalAuthService = GlobalAuthService();
      await globalAuthService.signOut();

      if (!mounted) return;

      // Store context reference safely before async navigation
      final currentContext = context;

      // Navigate safely with mounted check
      if (mounted) {
        GoRouter.of(currentContext).go('/login');
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
      if (!mounted) return;

      // Use context safely
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Sign out dialog with confirmation
  Future<void> _showSignOutDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleSignOut();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  // Implementation of editing profile
  void _navigateToEditProfile() async {
    debugPrint('ProfileScreen: Navigating to Edit Profile');

    // Set up controller with current data - only name now
    _nameController.text = _userData['name'];

    // Show dialog with simplified form
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _userData['name'] = _nameController.text;
        // We're not updating phone or bio anymore
      });

      // Save to SharedPreferences
      await _saveUserData();
    }
  }

  // Implementation of picking a profile photo from gallery
  Future<void> _pickProfilePhoto() async {
    debugPrint('ProfileScreen: Picking profile photo from gallery');
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
      );

      if (image != null && mounted) {
        // Add mounted check
        setState(() {
          _imageFile = File(image.path);
          _userData['profileImage'] = image.path;
        });

        // Save to shared preferences
        await _prefs.setString('user_profile_image', image.path);
        if (mounted) {
          // Add mounted check
          SnackBarUtils.showSuccessSnackBar(context, 'Profile photo updated');
        }
      }
    } catch (e) {
      debugPrint('Error picking photo: $e');
      if (mounted) {
        // Add mounted check
        SnackBarUtils.showErrorSnackBar(context, 'Failed to select photo');
      }
    }
  }

  // Implementation of removing a profile photo
  void _removeProfilePhoto() async {
    debugPrint('ProfileScreen: Removing profile photo');
    setState(() {
      _imageFile = null;
      _userData['profileImage'] =
          'https://randomuser.me/api/portraits/men/32.jpg';
    });

    // Store context before async operation
    final currentContext = context;

    // Save to shared preferences
    await _prefs.setString('user_profile_image', _userData['profileImage']);

    if (mounted) {
      SnackBarUtils.showSuccessSnackBar(
          currentContext, 'Profile photo removed');
    }
  }

  // Recently viewed screen navigation with shared preferences
  void _navigateToRecentlyViewed() {
    debugPrint('ProfileScreen: Navigating to Recently Viewed');

    final recentlyViewed =
        _prefs.getStringList('recently_viewed_properties') ?? [];

    if (recentlyViewed.isEmpty) {
      SnackBarUtils.showInfoSnackBar(
          context, 'You have no recently viewed properties');
      return;
    }

    // Here you would navigate to a list screen showing the recently viewed properties
    // For now, just show a temporary dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recently Viewed'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: recentlyViewed.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('Property ${index + 1}'),
                subtitle: Text('ID: ${recentlyViewed[index]}'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/propertyDetail', extra: recentlyViewed[index]);
                },
              );
            },
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

  // Saved searches screen navigation
  void _navigateToSavedSearches() {
    debugPrint('ProfileScreen: Navigating to Saved Searches');

    final savedSearches = _prefs.getStringList('saved_searches') ?? [];

    if (savedSearches.isEmpty) {
      SnackBarUtils.showInfoSnackBar(context, 'You have no saved searches');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saved Searches'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: savedSearches.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('Search ${index + 1}'),
                subtitle: Text(savedSearches[index]),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    // Remove this search
                    savedSearches.removeAt(index);
                    _prefs.setStringList('saved_searches', savedSearches);

                    Navigator.pop(context);
                    SnackBarUtils.showSuccessSnackBar(
                        context, 'Search removed successfully');

                    // Re-open dialog with updated list
                    _navigateToSavedSearches();
                  },
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/search', extra: savedSearches[index]);
                },
              );
            },
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

  // My properties screen navigation
  void _navigateToMyProperties(String filter) {
    debugPrint(
        'ProfileScreen: Navigating to My Properties with filter: $filter');

    // For now, show a coming soon dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('My Properties - $filter'),
        content:
            const Text('This feature will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Change password dialog
  void _navigateToChangePassword() {
    debugPrint('ProfileScreen: Navigating to Change Password');

    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                SnackBarUtils.showErrorSnackBar(
                    context, 'New passwords do not match');
                return;
              }
              Navigator.pop(context);
              SnackBarUtils.showSuccessSnackBar(
                  context, 'Password changed successfully');
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  // Support screen
  void _navigateToSupport() {
    debugPrint('ProfileScreen: Navigating to Support');

    final subjectController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  prefixIcon: Icon(Icons.subject),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  prefixIcon: Icon(Icons.message),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              SnackBarUtils.showSuccessSnackBar(
                  context, 'Support request sent successfully');
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  // About screen
  void _navigateToAbout() {
    debugPrint('ProfileScreen: Navigating to About');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About'),
        content: const Text('This is a real estate app. Version 1.0.0'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Format date utility
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
