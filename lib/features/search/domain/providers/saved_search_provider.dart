import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/saved_search.dart';
import '../repositories/saved_search_repository.dart';

class SavedSearchProvider extends ChangeNotifier {
  final SavedSearchRepository _repository = SavedSearchRepository();
  List<SavedSearch> _savedSearches = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  UnmodifiableListView<SavedSearch> get savedSearches =>
      UnmodifiableListView(_savedSearches);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get hasSavedSearches => _savedSearches.isNotEmpty;

  // Initialize and load saved searches
  Future<void> loadSavedSearches() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _savedSearches = await _repository.getSavedSearches();
    } catch (e) {
      _error = 'Failed to load saved searches: ${e.toString()}';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save a new search
  Future<void> saveSearch(SavedSearch search) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final savedSearch = await _repository.saveSearch(search);
      _savedSearches.add(savedSearch);
    } catch (e) {
      _error = 'Failed to save search: ${e.toString()}';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a saved search
  Future<void> deleteSearch(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.deleteSearch(id);
      _savedSearches.removeWhere((search) => search.id == id);
    } catch (e) {
      _error = 'Failed to delete search: ${e.toString()}';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update the notification settings for a saved search
  Future<void> updateNotifications(String id, bool enableNotifications) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.updateNotifications(id, enableNotifications);
      final index = _savedSearches.indexWhere((search) => search.id == id);
      if (index != -1) {
        _savedSearches[index] = _savedSearches[index].copyWith(
          notificationsEnabled: enableNotifications,
        );
      }
    } catch (e) {
      _error = 'Failed to update notifications: ${e.toString()}';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear any errors
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
