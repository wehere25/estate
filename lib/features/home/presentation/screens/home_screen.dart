import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import '../../../../core/utils/debug_logger.dart';
import '../../../../features/auth/domain/providers/auth_provider.dart';
import '../../../../features/auth/domain/services/admin_service.dart';
import '../../../../core/navigation/app_navigation.dart'; // Updated import

import '/core/constants/app_colors.dart';
import '/features/property/domain/models/property_model.dart';
import '/features/property/presentation/providers/property_provider.dart';
import '/features/property/presentation/widgets/property_card.dart';
import '/features/home/widgets/search_filter_bar.dart';
import '/features/home/widgets/property_list_header.dart';
import '/features/home/widgets/featured_properties_carousel.dart';

class HomeScreen extends StatefulWidget {
  final bool showNavBar;

  const HomeScreen({Key? key, this.showNavBar = true}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Remove the TabController declaration since we're not using it
  // late TabController _tabController;

  bool _isMapView = false;
  bool _isGridView = false;
  String _selectedFilter = 'All';
  int _selectedIndex = 0;
  bool _isAdmin = false;
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  // Add flag to prevent multiple initializations
  bool _initialized = false;

  Future<void> _loadProperties() async {
    final provider = Provider.of<PropertyProvider>(context, listen: false);
    DebugLogger.info("HomeScreen: Loading properties...");
    await provider.fetchProperties();
    DebugLogger.info(
        "HomeScreen: Properties loaded, count: ${provider.recentProperties.length}");
  }

  Future<void> _loadAllData() async {
    await _loadProperties();
  }

  @override
  void initState() {
    super.initState();
    debugPrint('🏠 HomeScreen: initState called');

    // Use postFrameCallback with initialization flag to prevent duplicate initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialized && mounted) {
        _initialized = true;
        _loadAllData();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    super.dispose();
  }

  // Override didChangeDependencies to handle re-initialization properly
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If we're remounting, we might need to check admin status again
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null && mounted) {
      final isAdmin = AdminService.isUserAdmin(authProvider.user);
      if (isAdmin != _isAdmin) {
        setState(() {
          _isAdmin = isAdmin;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        'Building HomeScreen - Screen width: ${MediaQuery.of(context).size.width}');
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    // Use a simple Scaffold instead of AppScaffold when no nav bar is needed
    return AppScaffold(
      currentIndex: _selectedIndex,
      showAppBar: false, // We'll handle our own app bar
      showNavBar: widget.showNavBar, // Pass the showNavBar parameter
      body: Column(
        children: [
          // Enhanced header with gradient matching HTML design
          Container(
            decoration: BoxDecoration(
              // Gradient matching HTML design: linear-gradient(135deg, var(--primary) 0%, var(--secondary) 100%)
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        AppColors.darkColorScheme.primary,
                        AppColors.darkColorScheme.secondary,
                      ]
                    : [
                        AppColors.primaryColor, // #2A9D8F - teal green
                        AppColors.secondaryColor, // #264653 - dark blue/slate
                      ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Radial overlay from HTML: radial-gradient(circle, rgba(255,255,255,0.1) 0%, rgba(255,255,255,0) 70%)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(-0.5, -0.5), // Top-left bias
                        radius: 1.0,
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.7],
                      ),
                    ),
                  ),
                ),
                // Content of the header
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top row with greeting and notifications icon
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: Colors.white.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Consumer<AuthProvider>(
                                    builder: (context, authProvider, _) {
                                      final name = authProvider
                                              .user?.displayName
                                              ?.split(' ')
                                              .first ??
                                          'Guest';
                                      return Text(
                                        'Hello, $name',
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            // Notification button with style matching HTML
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.notifications_outlined),
                                onPressed: () => context.push('/notifications'),
                                color: Colors.white,
                                tooltip: 'Notifications',
                                iconSize: 24,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                        // Search bar with improved spacing and visual design matching HTML
                        Container(
                          margin: const EdgeInsets.only(top: 20, bottom: 16),
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: SearchFilterBar(
                            controller: _searchController,
                            onSearchSubmitted: _handleSearch,
                            onFilterTap: _showFilterBottomSheet,
                          ),
                        ),
                        // Filter chips with enhanced styling and spacing to match HTML
                        if (!_isMapView)
                          SizedBox(
                            height: 38,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: 6,
                              itemBuilder: (context, index) {
                                final filters = [
                                  'All',
                                  'For Sale',
                                  'For Rent',
                                  'Furnished',
                                  'Newest',
                                  'Price ↓'
                                ];
                                return _buildFilterChip(filters[index],
                                    _selectedFilter == filters[index]);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(child: _buildMainContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _toggleViewMode(),
        icon: Icon(_isMapView ? Icons.view_list_rounded : Icons.map_rounded),
        label: Text(_isMapView ? 'List' : 'Map'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  // Updated filter chip with styles matching HTML design
  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _updateFilter(label),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primaryColor : Colors.white,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to update filter safely
  void _updateFilter(String filter) {
    if (_selectedFilter != filter) {
      // Log filter change
      DebugLogger.click('HomeScreen', 'Change Filter',
          screen: 'HomeScreen',
          data: {'previousFilter': _selectedFilter, 'newFilter': filter});

      Future.microtask(() {
        setState(() {
          _selectedFilter = filter;
        });

        // Apply the filter to the properties
        _applyFilter(filter);
      });
    }
  }

  // Method to apply filter to properties
  void _applyFilter(String filter) {
    final provider = Provider.of<PropertyProvider>(context, listen: false);

    Map<String, dynamic> filterParams = {};

    switch (filter) {
      case 'All':
        // No filters, just refresh
        provider.resetFilters();
        break;
      case 'For Sale':
        filterParams = {'listingType': 'Sale'};
        break;
      case 'For Rent':
        filterParams = {'listingType': 'Rent'};
        break;
      case 'Furnished':
        // Look for 'Furnished' in amenities array
        filterParams = {
          'amenities': ['Furnished']
        };
        break;
      case 'Newest':
        filterParams = {'sortBy': 'createdAt', 'sortDirection': 'desc'};
        break;
      case 'Price ↓':
        filterParams = {'sortBy': 'price', 'sortDirection': 'desc'};
        break;
    }

    // Apply the filter to the properties through the provider
    if (filter != 'All') {
      debugPrint('Applying filter: $filter with parameters: $filterParams');
      provider.applyFilters(filterParams);
    } else {
      debugPrint('Resetting filters');
      provider.resetFilters();
      _loadProperties(); // Reload all properties when selecting "All"
    }
  }

  Widget _buildMainContent() {
    debugPrint("HomeScreen: Building main content, map view: $_isMapView");
    return _isMapView ? _buildMapView() : _buildListView();
  }

  Widget _buildListView() {
    return Consumer<PropertyProvider>(
      builder: (context, provider, _) {
        debugPrint(
            "HomeScreen: Building list view, isLoading: ${provider.isLoading}");
        debugPrint(
            "HomeScreen: Recent properties: ${provider.recentProperties.length}");
        debugPrint(
            "HomeScreen: Featured properties: ${provider.featuredProperties.length}");

        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.recentProperties.isEmpty) {
          // Show a clean, empty state without any add property button
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Just show a simple message without any action button
                Text(
                  'No properties available',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadProperties,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property List Header with view toggle
                PropertyListHeader(
                  title: 'Recent Properties',
                  isGridView: _isGridView,
                  onViewToggle: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                ),

                // Property Grid/List
                _isGridView
                    ? _buildPropertyGrid(provider.recentProperties)
                    : _buildPropertyList(provider.recentProperties),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPropertyList(List<PropertyModel> properties) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: properties.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final property = properties[index];
        return PropertyCard(
          property: property,
          onTap: () => _navigateToPropertyDetail(property.id),
        );
      },
    );
  }

  Widget _buildPropertyGrid(List<PropertyModel> properties) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        return PropertyCard(
          property: property,
          isGridItem: true,
          onTap: () => _navigateToPropertyDetail(property.id),
        );
      },
    );
  }

  Widget _buildMapView() {
    return Consumer<PropertyProvider>(
      builder: (context, provider, _) {
        final properties = provider.recentProperties;
        final markers = _createMarkers(properties);

        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(34.0837, 74.7973), // Make this const
            initialZoom: 10.0,
            interactionOptions: const InteractionOptions(
              // Use const here
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 120,
                size: const Size(40, 40),
                markers: markers,
                builder: (context, markers) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.lightColorScheme.primary.withAlpha(204),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        markers.length.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<Marker> _createMarkers(List<PropertyModel> properties) {
    return properties.map((property) {
      // Use default location if property doesn't have coordinates
      final LatLng position =
          property.latitude != null && property.longitude != null
              ? LatLng(property.latitude!, property.longitude!)
              : const LatLng(34.0837, 74.7973); // Default to Srinagar, Kashmir
      return Marker(
        width: 50.0,
        height: 50.0,
        point: position,
        child: GestureDetector(
          onTap: () => _showPropertyBottomSheet(property),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.lightColorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(51),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '₹${(property.price / 1000).round()}k', // Changed $ to ₹
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showPropertyBottomSheet(PropertyModel property) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                PropertyCard(
                  property: property,
                  onTap: () => _navigateToPropertyDetail(property.id),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () => _navigateToPropertyDetail(property.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightColorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _toggleViewMode() {
    DebugLogger.click('HomeScreen', 'Toggle View Mode',
        screen: 'HomeScreen',
        data: {
          'previousMode': _isMapView ? 'Map' : 'List',
          'newMode': !_isMapView ? 'Map' : 'List'
        });
    setState(() {
      _isMapView = !_isMapView;
    });
  }

  // Method to show filter bottom sheet
  void _showFilterBottomSheet() {
    DebugLogger.click('HomeScreen', 'Open Filters', screen: 'HomeScreen');
    // Show a temporary snackbar to confirm button press
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening filters...'),
        duration: Duration(milliseconds: 500),
      ),
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent, // Make transparent for proper rounding
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        debugPrint('🔧 HomeScreen: Building filter bottom sheet');
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.8,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder: (context, scrollController) {
              return FixedFilterBottomSheet(
                scrollController: scrollController,
                onApply: (filters) {
                  DebugLogger.click('HomeScreen', 'Apply Filters',
                      screen: 'HomeScreen', data: filters);

                  // Apply the detailed filters from the bottom sheet
                  _applyDetailedFilters(filters);
                },
              );
            },
          ),
        );
      },
    );
  }

  // Method to apply detailed filters from the bottom sheet
  void _applyDetailedFilters(Map<String, dynamic> filters) {
    final provider = Provider.of<PropertyProvider>(context, listen: false);

    // Set selected filter to 'All' since we're applying custom filters
    setState(() {
      _selectedFilter = 'All';
    });

    // Convert the filters to match what the repository expects
    Map<String, dynamic> repositoryFilters = {};

    // Process price range
    if (filters['minPrice'] != null) {
      repositoryFilters['minPrice'] = filters['minPrice'];
    }
    if (filters['maxPrice'] != null) {
      repositoryFilters['maxPrice'] = filters['maxPrice'];
    }

    // Process bedrooms
    if (filters['bedrooms'] != null && filters['bedrooms'] > 0) {
      repositoryFilters['minBedrooms'] = filters['bedrooms'];
    }

    // Process bathrooms
    if (filters['bathrooms'] != null && filters['bathrooms'] > 0) {
      repositoryFilters['minBathrooms'] = filters['bathrooms'];
    }

    // Process property type - only if not "Any"
    if (filters['propertyType'] != null && filters['propertyType'] != 'Any') {
      repositoryFilters['propertyType'] = filters['propertyType'];
    }

    // Process amenities
    List<String> amenities = [];
    if (filters['hasParking'] == true) {
      amenities.add('Parking');
    }
    if (filters['hasPool'] == true) {
      amenities.add('Pool');
    }
    if (filters['hasPets'] == true) {
      amenities.add('PetFriendly');
    }
    if (amenities.isNotEmpty) {
      repositoryFilters['amenities'] = amenities;
    }

    // Apply the detailed filters
    debugPrint('Applying detailed filters: $repositoryFilters');
    provider.applyFilters(repositoryFilters);
  }

  void _handleSearch(String query) {
    // Log search event
    DebugLogger.click('HomeScreen', 'Search',
        screen: 'HomeScreen', data: {'query': query});

    // Handle search functionality
    if (query.isEmpty) return;

    final provider = Provider.of<PropertyProvider>(context, listen: false);
    provider.searchProperties(query);

    // Navigate to search results with query parameter
    context.push('/search?q=$query');
  }

  void _navigateToPropertyDetail(String? id) {
    if (id == null) return;

    // Log navigation click
    DebugLogger.navClick('/home', '/property/$id', params: {'propertyId': id});

    context.push('/property/$id');
  }

  // Add a debug method for validating measurements
  void _logDebugInfo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final size = renderBox.size;
          debugPrint('HomeScreen size: ${size.width} x ${size.height}');
        }

        // Log device info
        debugPrint(
            'Device pixel ratio: ${MediaQuery.of(context).devicePixelRatio}');
        debugPrint(
            'Screen size: ${MediaQuery.of(context).size.width} x ${MediaQuery.of(context).size.height}');
        debugPrint('Padding: ${MediaQuery.of(context).padding}');
        debugPrint('View insets: ${MediaQuery.of(context).viewInsets}');
      } catch (e) {
        debugPrint('Error getting debug info: $e');
      }
    });
  }
}

// Filter Bottom Sheet
class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({Key? key}) : super(key: key);

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  RangeValues _priceRange = const RangeValues(100000, 1000000);
  int _bedrooms = 0;
  int _bathrooms = 0;
  String _propertyType = 'Any';
  bool _hasParking = false;
  bool _hasPool = false;
  bool _hasPets = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Filter Properties',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Price Range
          const Text(
            'Price Range',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 2000000,
            divisions: 20,
            labels: RangeLabels(
              '\$${_priceRange.start.round()}',
              '\$${_priceRange.end.round()}',
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _priceRange = values;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('\$${_priceRange.start.round()}'),
              Text('\$${_priceRange.end.round()}'),
            ],
          ),
          const SizedBox(height: 24),

          // Bedrooms & Bathrooms
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bedrooms',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(5, (index) {
                        return _buildSelectionChip(
                          index.toString(),
                          _bedrooms == index,
                          () {
                            setState(() {
                              _bedrooms = index;
                            });
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bathrooms',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(5, (index) {
                        return _buildSelectionChip(
                          index.toString(),
                          _bathrooms == index,
                          () {
                            setState(() {
                              _bathrooms = index;
                            });
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Property Type
          const Text(
            'Property Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              'Any',
              'House',
              'Apartment',
              'Condo',
              'Townhouse',
              'Land',
              'Commercial'
            ].map((type) {
              return _buildSelectionChip(
                type,
                _propertyType == type,
                () {
                  setState(() {
                    _propertyType = type;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Amenities
          const Text(
            'Amenities',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildCheckboxItem('Parking', _hasParking, (value) {
            setState(() {
              _hasParking = value ?? false;
            });
          }),
          _buildCheckboxItem('Swimming Pool', _hasPool, (value) {
            setState(() {
              _hasPool = value ?? false;
            });
          }),
          _buildCheckboxItem('Pet Friendly', _hasPets, (value) {
            setState(() {
              _hasPets = value ?? false;
            });
          }),
          const SizedBox(height: 24),

          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                final filters = {
                  'minPrice': _priceRange.start,
                  'maxPrice': _priceRange.end,
                  'bedrooms': _bedrooms > 0 ? _bedrooms : null,
                  'bathrooms': _bathrooms > 0 ? _bathrooms : null,
                  'propertyType': _propertyType != 'Any' ? _propertyType : null,
                  'hasParking': _hasParking ? true : null,
                  'hasPool': _hasPool ? true : null,
                  'hasPets': _hasPets ? true : null,
                };
                Navigator.pop(context, filters);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightColorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply Filters'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSelectionChip(
      String label, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.grey[200],
      selectedColor: AppColors.lightColorScheme.primary.withAlpha(51),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.lightColorScheme.primary : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildCheckboxItem(
      String label, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.lightColorScheme.primary,
      contentPadding: EdgeInsets.zero,
    );
  }
}

// New fixed filter bottom sheet class
class FixedFilterBottomSheet extends StatefulWidget {
  final ScrollController scrollController;
  final Function(Map<String, dynamic>)? onApply;

  const FixedFilterBottomSheet({
    Key? key,
    required this.scrollController,
    this.onApply,
  }) : super(key: key);

  @override
  State<FixedFilterBottomSheet> createState() => _FixedFilterBottomSheetState();
}

class _FixedFilterBottomSheetState extends State<FixedFilterBottomSheet> {
  RangeValues _priceRange = const RangeValues(100000, 1000000);
  int _bedrooms = 0;
  int _bathrooms = 0;
  String _propertyType = 'Any';
  bool _hasParking = false;
  bool _hasPool = false;
  bool _hasPets = false;

  @override
  Widget build(BuildContext context) {
    debugPrint('🔍 Building FixedFilterBottomSheet');
    final screenWidth = MediaQuery.of(context).size.width;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.all(20),
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Center(
            child: Text(
              'Filter Properties',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Bedrooms & Bathrooms - Fixed with SizedBox width constraints
          Text(
            'Bedrooms',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                return Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(index.toString()),
                    selected: _bedrooms == index,
                    onSelected: (_) => setState(() => _bedrooms = index),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _bedrooms == index
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodyLarge?.color,
                    ),
                    backgroundColor: isDarkMode
                        ? theme.colorScheme.surfaceVariant
                        : theme.colorScheme.surface,
                    selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),
          Text(
            'Bathrooms',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                return Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(index.toString()),
                    selected: _bathrooms == index,
                    onSelected: (_) => setState(() => _bathrooms = index),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _bathrooms == index
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodyLarge?.color,
                    ),
                    backgroundColor: isDarkMode
                        ? theme.colorScheme.surfaceVariant
                        : theme.colorScheme.surface,
                    selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Property Type
          Text(
            'Property Type',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Any',
              'House',
              'Apartment',
              'Condo',
              'Townhouse',
              'Land',
              'Commercial'
            ]
                .map((type) => SizedBox(
                      width: (screenWidth - 56) /
                          3, // 3 items per row with padding
                      child: FilterChip(
                        label: Text(type),
                        selected: _propertyType == type,
                        onSelected: (_) => setState(() => _propertyType = type),
                        labelStyle: TextStyle(
                          color: _propertyType == type
                              ? theme.colorScheme.primary
                              : theme.textTheme.bodyLarge?.color,
                        ),
                        backgroundColor: isDarkMode
                            ? theme.colorScheme.surfaceVariant
                            : theme.colorScheme.surface,
                        selectedColor:
                            theme.colorScheme.primary.withOpacity(0.2),
                      ),
                    ))
                .toList(),
          ),

          const SizedBox(height: 24),

          // Amenities
          Text(
            'Amenities',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          CheckboxListTile(
            title: Text(
              'Parking Available',
              style: theme.textTheme.bodyLarge,
            ),
            value: _hasParking,
            onChanged: (value) => setState(() => _hasParking = value ?? false),
            activeColor: theme.colorScheme.primary,
            checkColor: isDarkMode ? Colors.black : Colors.white,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            title: Text(
              'Swimming Pool',
              style: theme.textTheme.bodyLarge,
            ),
            value: _hasPool,
            onChanged: (value) => setState(() => _hasPool = value ?? false),
            activeColor: theme.colorScheme.primary,
            checkColor: isDarkMode ? Colors.black : Colors.white,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            title: Text(
              'Pet Friendly',
              style: theme.textTheme.bodyLarge,
            ),
            value: _hasPets,
            onChanged: (value) => setState(() => _hasPets = value ?? false),
            activeColor: theme.colorScheme.primary,
            checkColor: isDarkMode ? Colors.black : Colors.white,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),

          const SizedBox(height: 32),

          // Apply Button
          ElevatedButton(
            onPressed: () {
              debugPrint('🔍 Filter apply button pressed');
              final filters = {
                'minPrice': _priceRange.start,
                'maxPrice': _priceRange.end,
                'bedrooms': _bedrooms,
                'bathrooms': _bathrooms,
                'propertyType': _propertyType,
                'hasParking': _hasParking,
                'hasPool': _hasPool,
                'hasPets': _hasPets,
              };

              if (widget.onApply != null) {
                widget.onApply!(filters);
              }

              Navigator.pop(context, filters);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Apply Filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
