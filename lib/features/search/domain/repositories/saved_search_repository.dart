import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/saved_search.dart';

class SavedSearchRepository {
  static const String _savedSearchesKey = 'saved_searches';

  // Fetch all saved searches
  Future<List<SavedSearch>> getSavedSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSearchesJson = prefs.getStringList(_savedSearchesKey) ?? [];

      final savedSearches = <SavedSearch>[];
      for (final json in savedSearchesJson) {
        try {
          final savedSearch = SavedSearch.fromJson(json);
          savedSearches.add(savedSearch);
        } catch (e) {
          debugPrint('Error parsing saved search: $e');
        }
      }

      // Sort by most recently used
      savedSearches.sort((a, b) =>
          (b.lastUsedAt ?? b.createdAt).compareTo(a.lastUsedAt ?? a.createdAt));
      return savedSearches;
    } catch (e) {
      debugPrint('Failed to load saved searches: $e');
      rethrow;
    }
  }

  // Save all searches to SharedPreferences
  Future<void> _persistSavedSearches(List<SavedSearch> searches) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = searches.map((search) => search.toJson()).toList();
      await prefs.setStringList(_savedSearchesKey, jsonList);
    } catch (e) {
      debugPrint('Failed to persist saved searches: $e');
      rethrow;
    }
  }

  // Save a new search
  Future<SavedSearch> saveSearch(SavedSearch search) async {
    // Get current saved searches
    final savedSearches = await getSavedSearches();

    // Check if a search with the same query and filters already exists
    final existingSearchIndex = savedSearches.indexWhere((existing) =>
        existing.query == search.query &&
        jsonEncode(existing.filters) == jsonEncode(search.filters));

    if (existingSearchIndex != -1) {
      // Update existing search
      SavedSearch updatedSearch = savedSearches[existingSearchIndex].copyWith(
        name: search.name,
        lastUsedAt: DateTime.now(),
        usageCount: savedSearches[existingSearchIndex].usageCount + 1,
      );

      // Replace existing search
      savedSearches[existingSearchIndex] = updatedSearch;
      await _persistSavedSearches(savedSearches);
      return updatedSearch;
    }

    // Create a new search with a generated ID if one isn't provided
    SavedSearch newSearch = search.id.isEmpty
        ? search.copyWith(id: const Uuid().v4(), createdAt: DateTime.now())
        : search;

    // Add to saved searches
    savedSearches.insert(0, newSearch);
    await _persistSavedSearches(savedSearches);
    return newSearch;
  }

  // Delete a saved search
  Future<void> deleteSearch(String id) async {
    final savedSearches = await getSavedSearches();
    savedSearches.removeWhere((search) => search.id == id);
    await _persistSavedSearches(savedSearches);
  }

  // Update notifications for a saved search
  Future<void> updateNotifications(String id, bool enableNotifications) async {
    final savedSearches = await getSavedSearches();
    final index = savedSearches.indexWhere((search) => search.id == id);

    if (index != -1) {
      savedSearches[index] = savedSearches[index].copyWith(
        notificationsEnabled: enableNotifications,
      );
      await _persistSavedSearches(savedSearches);
    }
  }

  // Mark a search as used
  Future<SavedSearch> markSearchAsUsed(String id) async {
    final savedSearches = await getSavedSearches();
    final index = savedSearches.indexWhere((search) => search.id == id);

    if (index == -1) {
      throw Exception('Saved search not found: $id');
    }

    final updatedSearch = savedSearches[index].markAsUsed();
    savedSearches[index] = updatedSearch;

    // Move to top of list
    final search = savedSearches.removeAt(index);
    savedSearches.insert(0, search);

    await _persistSavedSearches(savedSearches);
    return updatedSearch;
  }
}
