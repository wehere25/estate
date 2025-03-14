import 'package:flutter/material.dart';
import '../../../core/utils/logger.dart';
import '../../../features/auth/data/auth_service.dart';

class AdminProvider extends ChangeNotifier {
  static const String _tag = 'AdminProvider';
  final AuthService _authService = AuthService();
  
  bool _isAdmin = false;
  bool _isLoading = false;
  String? _error;
  
  bool get isAdmin => _isAdmin;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  AdminProvider() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Fix: Call the method directly instead of returning it
      _isAdmin = await checkAdminStatus();
    } catch (e) {
      AppLogger.e(_tag, 'Error initializing admin status', e);
      _error = 'Failed to check admin privileges';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Fix: Return a bool directly instead of a function
  Future<bool> checkAdminStatus() async {
    try {
      return await _authService.isAdmin();
    } catch (e) {
      AppLogger.e(_tag, 'Error checking admin status', e);
      return false;
    }
  }
}
