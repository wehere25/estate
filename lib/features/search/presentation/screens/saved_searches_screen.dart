import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../domain/providers/saved_search_provider.dart';
import '../../domain/models/saved_search.dart';
import '../widgets/saved_search_tile.dart';

class SavedSearchesScreen extends StatefulWidget {
  const SavedSearchesScreen({Key? key}) : super(key: key);

  @override
  State<SavedSearchesScreen> createState() => _SavedSearchesScreenState();
}

class _SavedSearchesScreenState extends State<SavedSearchesScreen> {
  @override
  void initState() {
    super.initState();
    // Load saved searches when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SavedSearchProvider>(context, listen: false)
          .loadSavedSearches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Searches'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<SavedSearchProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    provider.error ?? 'Unknown error',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: provider.loadSavedSearches,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!provider.hasSavedSearches) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: isDarkMode ? Colors.white60 : Colors.black38,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved searches yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'When you save searches, they will appear here for quick access',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/search'),
                    icon: const Icon(Icons.search),
                    label: const Text('Start Searching'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.savedSearches.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final savedSearch = provider.savedSearches[index];
              return SavedSearchTile(
                savedSearch: savedSearch,
                onTap: () {
                  // Use push instead of go to maintain navigation history
                  context.push(
                    '/search_results',
                    extra: {
                      'query': savedSearch.query,
                      'filters': savedSearch.filters
                    },
                  );
                },
                onDelete: () async {
                  final confirmed = await _confirmDelete(context);
                  if (confirmed) {
                    provider.deleteSearch(savedSearch.id);
                  }
                },
                onToggleNotifications: (enabled) {
                  provider.updateNotifications(savedSearch.id, enabled);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/search'),
        tooltip: 'New Search',
        child: const Icon(Icons.search),
      ),
    );
  }

  // Show confirmation dialog before deleting a saved search
  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Saved Search'),
            content: const Text(
                'Are you sure you want to delete this saved search? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
