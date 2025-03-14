import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_provider.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../core/constants/app_colors.dart';
import '/features/property/domain/models/property_model.dart';
import '/features/property/presentation/providers/property_provider.dart';
import '../../../../core/utils/debug_logger.dart';

class ManagePropertiesScreen extends StatefulWidget {
  const ManagePropertiesScreen({Key? key}) : super(key: key);

  @override
  State<ManagePropertiesScreen> createState() => _ManagePropertiesScreenState();
}

class _ManagePropertiesScreenState extends State<ManagePropertiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String _selectedFilter = 'All';
  final List<PropertyModel> _selectedProperties = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Defer loading to avoid layout issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeData();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Initialize admin provider first
      await Provider.of<AdminProvider>(context, listen: false).initialize();
      // Then load properties
      await _loadProperties();

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      DebugLogger.error('Failed to initialize admin properties', e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadProperties() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Load real properties from Firestore
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);
      await propertyProvider.fetchProperties();

      // Also fetch the admin properties to ensure UI consistency
      await Provider.of<AdminProvider>(context, listen: false).loadProperties();
    } catch (e) {
      DebugLogger.error('Failed to load properties', e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Properties'),
        backgroundColor: AppColors.lightColorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProperties,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildSafeBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/property/add'),
        label: const Text('Add Property'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.lightColorScheme.primary,
      ),
    );
  }

  // Added a safe body builder to prevent layout errors
  Widget _buildSafeBody() {
    if (_isLoading && !_isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading properties...'),
          ],
        ),
      );
    }

    // Check for admin provider errors
    final adminProvider = Provider.of<AdminProvider>(context);
    if (adminProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: ${adminProvider.error}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                adminProvider.clearError();
                _initializeData();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return _buildContentSafely();
  }

  // Modified to prevent layout errors and use real properties
  Widget _buildContentSafely() {
    // Use the PropertyProvider to get actual properties from Firestore
    return Consumer<PropertyProvider>(
      builder: (context, propertyProvider, _) {
        // Handle case when properties are null or loading
        if (propertyProvider.properties.isEmpty && _isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Get all properties, not just mock ones
        final properties = propertyProvider.properties;
        final filteredProperties = _filterProperties(properties);

        return Column(
          children: [
            _buildSearchBar(),
            _buildFilters(),
            if (_selectedProperties.isNotEmpty) _buildBulkActionBar(),
            Expanded(
              child: filteredProperties.isEmpty
                  ? const Center(child: Text('No properties found'))
                  : _buildPropertyList(filteredProperties),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: AppTextField(
        controller: _searchController,
        hintText: 'Search by title, description or location',
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
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', _selectedFilter == 'All'),
            _buildFilterChip('For Sale', _selectedFilter == 'For Sale'),
            _buildFilterChip('For Rent', _selectedFilter == 'For Rent'),
            _buildFilterChip('Featured', _selectedFilter == 'Featured'),
            _buildFilterChip(
                'Pending Review', _selectedFilter == 'Pending Review'),
          ],
        ),
      ),
    );
  }

  List<PropertyModel> _filterProperties(List<PropertyModel> properties) {
    var filtered = _searchController.text.isEmpty
        ? properties
        : properties.where((property) {
            final query = _searchController.text.toLowerCase();
            return property.title.toLowerCase().contains(query) ||
                property.description.toLowerCase().contains(query) ||
                (property.location?.toLowerCase() ?? '').contains(query);
          }).toList();

    // Then apply category filter
    if (_selectedFilter != 'All') {
      filtered = filtered.where((property) {
        switch (_selectedFilter) {
          case 'For Sale':
            return property.listingType.toLowerCase() == 'sale';
          case 'For Rent':
            return property.listingType.toLowerCase() == 'rent';
          case 'Featured':
            return property.featured;
          case 'Pending Review':
            return !property.isApproved;
          default:
            return true;
        }
      }).toList();
    }
    return filtered;
  }

  Widget _buildFilterChip(String label, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() {
            _selectedFilter = label;
          });
        },
        selectedColor:
            AppColors.lightColorScheme.primary.withAlpha((0.2 * 255).round()),
        checkmarkColor: AppColors.lightColorScheme.primary,
      ),
    );
  }

  Widget _buildBulkActionBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color:
            AppColors.lightColorScheme.primary.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedProperties.length} selected',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton.icon(
            icon: const Icon(Icons.check_circle),
            label: const Text('Approve'),
            onPressed: () => _approveBulkProperties(),
          ),
          TextButton.icon(
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
            onPressed: () => _confirmDeleteBulkProperties(),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _selectedProperties.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyList(List<PropertyModel> properties) {
    return ListView.builder(
      itemCount: properties.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final property = properties[index];
        final isSelected = _selectedProperties.contains(property);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: InkWell(
            onTap: () => _navigateToPropertyDetail(property),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  _buildPropertyImage(property),

                  const SizedBox(width: 12),

                  // Property info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(property.location ?? 'No location'),
                        const SizedBox(height: 4),
                        _buildPropertyStatusBadges(property),
                      ],
                    ),
                  ),

                  // Action buttons
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked ?? false) {
                              _selectedProperties.add(property);
                            } else {
                              _selectedProperties.remove(property);
                            }
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _navigateToPropertyEdit(property),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteProperty(property),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method to navigate to property detail - handles nullable id
  void _navigateToPropertyDetail(PropertyModel property) {
    final id = property.id;
    if (id != null && id.isNotEmpty) {
      context.push('/property/$id');
    }
  }

  // Helper method to navigate to property edit - handles nullable id
  void _navigateToPropertyEdit(PropertyModel property) {
    final id = property.id;
    if (id != null && id.isNotEmpty) {
      context.push('/property/edit/$id');
    }
  }

  Widget _buildPropertyImage(PropertyModel property) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 80,
        height: 80,
        child: property.images?.isNotEmpty == true
            ? Image.network(
                property.images!.first,
                fit: BoxFit.cover,
                // Add more robust error handling
                errorBuilder: (context, error, stackTrace) {
                  DebugLogger.error('Failed to load property image', error);
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.home, size: 40, color: Colors.grey),
                  );
                },
              )
            : Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.home, size: 40),
              ),
      ),
    );
  }

  Widget _buildPropertyStatusBadges(PropertyModel property) {
    return Wrap(
      spacing: 8,
      children: [
        _buildPropertyBadge(
          property.listingType.toLowerCase() == 'sale'
              ? 'For Sale'
              : 'For Rent',
          property.listingType.toLowerCase() == 'sale'
              ? Colors.blue
              : Colors.green,
        ),
        if (property.featured) _buildPropertyBadge('Featured', Colors.orange),
        if (!(property.isApproved))
          _buildPropertyBadge('Pending Review', Colors.red),
      ],
    );
  }

  Widget _buildPropertyBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  void _confirmDeleteProperty(PropertyModel property) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property'),
        content: Text('Are you sure you want to delete "${property.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProperty(property);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteProperty(PropertyModel property) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Check if property has an ID
      final id = property.id;
      if (id == null || id.isEmpty) {
        throw Exception("Property doesn't have a valid ID");
      }

      // Use the PropertyProvider to delete the property from Firestore
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);
      await propertyProvider.deleteProperty(id);

      // Show success message - only if still mounted
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted: ${property.title}'),
        ),
      );

      // Refresh the properties list
      await _loadProperties();
    } catch (e) {
      DebugLogger.error('Failed to delete property', e);

      // Show error message - only if still mounted
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting property: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _confirmDeleteBulkProperties() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Properties'),
        content: Text(
            'Are you sure you want to delete ${_selectedProperties.length} properties?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBulkProperties();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteBulkProperties() async {
    if (!mounted) return;

    final count = _selectedProperties.length;
    setState(() => _isLoading = true);

    try {
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);

      // Delete properties one by one
      for (final property in _selectedProperties) {
        final id = property.id;
        // Skip properties with no id
        if (id == null || id.isEmpty) {
          DebugLogger.warning('Skipping property with no valid ID');
          continue;
        }
        await propertyProvider.deleteProperty(id);
      }

      // Show success message - only if still mounted
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted $count properties')),
      );

      // Clear selected properties
      setState(() {
        _selectedProperties.clear();
      });

      // Refresh the properties list
      await _loadProperties();
    } catch (e) {
      DebugLogger.error('Failed to delete properties in bulk', e);

      // Show error message - only if still mounted
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting properties: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _approveBulkProperties() async {
    if (!mounted) return;

    final count = _selectedProperties.length;
    setState(() => _isLoading = true);

    try {
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);

      // Approve properties one by one
      for (final property in _selectedProperties) {
        final id = property.id;
        // Skip properties with no id
        if (id == null || id.isEmpty) {
          DebugLogger.warning('Skipping property with no valid ID');
          continue;
        }
        // Update each property with the isApproved flag
        await propertyProvider.updateProperty(id, {'isApproved': true});
      }

      // Show success message - only if still mounted
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approved $count properties')),
      );

      // Clear selected properties
      setState(() {
        _selectedProperties.clear();
      });

      // Refresh the properties list
      await _loadProperties();
    } catch (e) {
      DebugLogger.error('Failed to approve properties in bulk', e);

      // Show error message - only if still mounted
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving properties: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
