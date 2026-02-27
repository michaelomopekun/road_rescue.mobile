import 'package:flutter/material.dart';
import 'token_service.dart';

/// Global notifier for auth state changes
/// Used to notify the main app when user logs in/out
class AuthNotifier extends ChangeNotifier {
  static final AuthNotifier _instance = AuthNotifier._internal();

  factory AuthNotifier() {
    return _instance;
  }

  AuthNotifier._internal();

  /// Notify listeners that auth state has changed
  /// This is called when user logs in/out
  void notifyAuthStateChanged() {
    print('[AuthNotifier] Auth state changed, notifying listeners');
    notifyListeners();
  }

  /// Get current auth data
  Future<AuthData?> getAuthData() async {
    return TokenService.getAuthData();
  }
}

// Global instance
final authNotifier = AuthNotifier();
