import 'package:flutter/material.dart';

/// Provider to handle authentication state and session management.
class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = true; // Defaulted to true for demo purposes
  bool _isLoading = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  /// Performs logout by clearing session data and notifying listeners.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    // Simulate network/storage delay for clearing session
    await Future.delayed(const Duration(milliseconds: 800));

    // Clear session logic would go here (e.g. SharedPreferences.clear())
    _isAuthenticated = false;
    _isLoading = false;
    
    notifyListeners();
  }
}
