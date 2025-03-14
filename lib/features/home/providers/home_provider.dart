import 'package:flutter/material.dart';

enum HomeLoadingState { initial, loading, loaded, error }

class HomeProvider extends ChangeNotifier {
  HomeLoadingState _state = HomeLoadingState.initial;
  String _error = '';
  Map<String, dynamic> _data = {};

  HomeLoadingState get state => _state;
  String get error => _error;
  Map<String, dynamic> get data => _data;

  Future<void> loadInitialData() async {
    try {
      _state = HomeLoadingState.loading;
      notifyListeners();

      // Add your data loading logic here
      await Future.delayed(const Duration(seconds: 2)); // Simulate loading
      _data = {'message': 'Home data loaded'};
      
      _state = HomeLoadingState.loaded;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _state = HomeLoadingState.error;
      notifyListeners();
    }
  }
}
