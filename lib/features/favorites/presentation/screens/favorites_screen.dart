import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart'; // Add this import for go_router
import '/core/constants/app_colors.dart';
import '/features/favorites/providers/favorites_provider.dart';
import '/features/property/presentation/widgets/property_card.dart';
import '../../../property/domain/models/property_model.dart';
import '../../../../core/navigation/app_bottom_nav.dart';
import '../../../../core/navigation/app_scaffold.dart';

class FavoritesScreen extends StatefulWidget {
  final bool showNavBar;

  const FavoritesScreen({Key? key, this.showNavBar = true}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  // Not making this final because it might need to be mutable
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    // Refresh favorites when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<FavoritesProvider>(context, listen: false)
            .refreshFavorites();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Add debug logging to track FavoritesScreen building and navbar visibility
    debugPrint(
        'NAVBAR DEBUG: FavoritesScreen building with showNavBar=${widget.showNavBar}');

    return AppScaffold(
      currentIndex: 2, // Explicitly set index for Favorites
      showNavBar: widget.showNavBar,
      customAppBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 4,
        title: const Text(
          'Favorites',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Add saved searches button
          IconButton(
            icon: const Icon(Icons.saved_search, color: Colors.white),
            tooltip: 'Saved Searches',
            onPressed: () => context.push('/saved_searches'),
          ),
          // Toggle view button
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view,
                color: Colors.white),
            tooltip: _isGridView ? 'List View' : 'Grid View',
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: Consumer<FavoritesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(provider.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refreshFavorites(),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          if (provider.favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No favorites yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Properties you like will appear here',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go(
                        '/home'), // Changed from Navigator.pushReplacementNamed
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightColorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Browse Properties'),
                  ),
                ],
              ),
            );
          }

          return _isGridView
              ? _buildGrid(provider.favorites)
              : _buildList(provider.favorites);
        },
      ),
    );
  }

  Widget _buildList(List<PropertyModel> properties) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        return Dismissible(
          key: Key(property.id!),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            Provider.of<FavoritesProvider>(context, listen: false)
                .toggleFavorite(property);
          },
          child: PropertyCard(
            property: property,
            onTap: () => _navigateToDetail(property.id),
          ),
        );
      },
    );
  }

  Widget _buildGrid(List<PropertyModel> properties) {
    return GridView.builder(
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
          onTap: () => _navigateToDetail(property.id),
        );
      },
    );
  }

  void _navigateToDetail(String? id) {
    if (id == null) return;
    GoRouter.of(context).push('/property/$id'); // Fixed the method call
  }
}
