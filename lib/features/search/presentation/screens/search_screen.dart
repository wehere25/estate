import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '/features/property/domain/models/property_model.dart';
import '/features/property/presentation/providers/property_provider.dart';
import '/features/property/presentation/widgets/property_card.dart';
import '/core/constants/app_colors.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../domain/providers/saved_search_provider.dart';
import '../../domain/models/saved_search.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  final bool showNavBar;

  const SearchScreen({Key? key, this.initialQuery, this.showNavBar = true})
      : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = false;
  bool _isSearching = false;
  String _currentQuery = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Recent searches
  List<String> _recentSearches = [];
  final int _maxRecentSearches = 5;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery ?? '';
    _currentQuery = widget.initialQuery ?? '';

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Load recent searches
    _loadRecentSearches();

    if (widget.initialQuery != null) {
      _performSearch(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Load recent searches from SharedPreferences
  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  // Save recent searches to SharedPreferences
  Future<void> _saveRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_searches', _recentSearches);
  }

  // Add search to recent searches
  void _addToRecentSearches(String query) {
    if (query.isEmpty) return;

    setState(() {
      // Remove if already exists to avoid duplicates
      _recentSearches.remove(query);

      // Add to beginning of list
      _recentSearches.insert(0, query);

      // Keep only the most recent searches
      if (_recentSearches.length > _maxRecentSearches) {
        _recentSearches = _recentSearches.sublist(0, _maxRecentSearches);
      }
    });

    _saveRecentSearches();
  }

  // Remove a recent search
  void _removeRecentSearch(String query) {
    setState(() {
      _recentSearches.remove(query);
    });
    _saveRecentSearches();
  }

  // Clear all recent searches
  void _clearAllRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
    _saveRecentSearches();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _currentQuery = query;
    });

    // Add to recent searches
    _addToRecentSearches(query);

    final provider = Provider.of<PropertyProvider>(context, listen: false);
    await provider.searchProperties(query);

    setState(() {
      _isSearching = false;
    });
  }

  Future<void> _saveCurrentSearch() async {
    if (_currentQuery.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please perform a search first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show dialog to name the search
    final searchName = await showDialog<String>(
      context: context,
      builder: (context) => _buildSaveSearchDialog(context),
    );

    if (searchName == null || searchName.isEmpty) return;

    try {
      final savedSearchProvider =
          Provider.of<SavedSearchProvider>(context, listen: false);
      await savedSearchProvider.saveSearch(SavedSearch(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: searchName,
        query: _currentQuery,
        filters: {}, // Currently no filters are implemented
        createdAt: DateTime.now(),
      ));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved search: $searchName'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'View All',
            onPressed: () => context.push('/saved_searches'),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save search: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Clear the search field
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _currentQuery = '';
    });
  }

  Widget _buildSaveSearchDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.bookmark_add, color: AppColors.primaryColor, size: 24),
          const SizedBox(width: 8),
          const Text('Save Search'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Save "$_currentQuery" to your searches',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Name this search',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primaryColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primaryColor,
                  width: 2,
                ),
              ),
              prefixIcon: const Icon(Icons.edit),
              hintText: 'e.g. Downtown Apartments',
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style:
                TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, nameController.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _navigateToPropertyDetail(String? id) {
    if (id != null) {
      context.push('/property/$id');
    }
  }

  // Build recent search chips
  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) return const SizedBox.shrink();

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              if (_recentSearches.isNotEmpty)
                TextButton(
                  onPressed: _clearAllRecentSearches,
                  child: Text(
                    'Clear All',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: _recentSearches.map((query) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InputChip(
                  label: Text(query),
                  onPressed: () => _performSearch(query),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeRecentSearch(query),
                  backgroundColor: isDarkMode
                      ? AppColors.darkColorScheme.surfaceVariant
                      : AppColors.lightGrayColor,
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 13,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide.none,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      currentIndex: 1, // Search is index 1
      title: 'Property Search',
      showNavBar: widget.showNavBar,
      actions: [
        if (_currentQuery.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'Save this search',
            onPressed: _saveCurrentSearch,
          ),
        IconButton(
          icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
          tooltip: _isGridView ? 'Switch to list view' : 'Switch to grid view',
          onPressed: () {
            setState(() {
              _isGridView = !_isGridView;
            });
          },
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppColors.darkColorScheme.surface
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by location, name, or features...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.primaryColor,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearSearch,
                          tooltip: 'Clear search',
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  filled: true,
                  fillColor: isDarkMode
                      ? AppColors.darkColorScheme.surface
                      : Colors.white,
                ),
                onSubmitted: _performSearch,
                onChanged: (value) {
                  setState(() {
                    // This ensures the clear button shows/hides as text is typed
                  });
                },
                textInputAction: TextInputAction.search,
              ),
            ),
          ),

          // Recent searches section
          if (_currentQuery.isEmpty) _buildRecentSearches(),

          Expanded(
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Consumer<PropertyProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (_currentQuery.isEmpty &&
                          provider.searchResults.isEmpty) {
                        // Initial state
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.search,
                                    size: 60,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Search for Properties',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32),
                                  child: Text(
                                    'Enter a location, property type, or any feature to find your perfect property',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.black54,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else if (_currentQuery.isNotEmpty &&
                          provider.searchResults.isEmpty) {
                        // Search with no results
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightGrayColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: AppColors.grayColor,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'No properties found',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40),
                                  child: Text(
                                    'No properties match "$_currentQuery". Try different keywords or filters.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.black54,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _currentQuery = '';
                                    });
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reset Search'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isGridView
                            ? _buildSearchResultsGrid(provider.searchResults)
                            : _buildSearchResultsList(provider.searchResults),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsList(List<PropertyModel> properties) {
    return ListView.builder(
      key: const ValueKey<String>('list_view'),
      padding: const EdgeInsets.all(16),
      itemCount: properties.length + 1, // +1 for the header
      itemBuilder: (context, index) {
        if (index == 0) {
          // Header with result count
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Found ${properties.length} ${properties.length == 1 ? 'property' : 'properties'} for "$_currentQuery"',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          );
        }

        final property = properties[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PropertyCard(
            property: property,
            onTap: () => _navigateToPropertyDetail(property.id),
          ),
        );
      },
    );
  }

  Widget _buildSearchResultsGrid(List<PropertyModel> properties) {
    return CustomScrollView(
      key: const ValueKey<String>('grid_view'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Found ${properties.length} ${properties.length == 1 ? 'property' : 'properties'} for "$_currentQuery"',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final property = properties[index];
                return PropertyCard(
                  property: property,
                  isGridItem: true,
                  onTap: () => _navigateToPropertyDetail(property.id),
                );
              },
              childCount: properties.length,
            ),
          ),
        ),
      ],
    );
  }
}
