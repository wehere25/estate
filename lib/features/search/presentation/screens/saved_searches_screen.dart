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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Searches'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<SavedSearchProvider>(
        builder: (context, provider, child) {
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
                    'Error: ${provider.error ?? "An error occurred"}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadSavedSearches(),
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
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No Saved Searches',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Save your searches to get notified about new properties that match your criteria.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text('Search Properties'),
                    onPressed: () => context.go('/search'),
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
                  // Navigate to search results with this saved search
                  context.go(
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

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Saved Search'),
            content: const Text(
              'Are you sure you want to delete this saved search? This action cannot be undone.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('DELETE'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
