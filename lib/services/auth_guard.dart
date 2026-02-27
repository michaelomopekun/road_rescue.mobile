import 'package:flutter/material.dart';
import 'package:road_rescue/services/token_service.dart';
import 'package:road_rescue/services/auth_notifier.dart';

/// Auth middleware/guard for protecting routes
/// This widget checks if the user is authenticated and either shows the protected widget
/// or navigates to the login screen
class AuthGuard extends StatefulWidget {
  final Widget child;
  final String loginRouteName;

  const AuthGuard({
    super.key,
    required this.child,
    this.loginRouteName = '/login',
  });

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  late Future<bool> _authFuture;

  @override
  void initState() {
    super.initState();
    _authFuture = TokenService.isAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _authFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final isAuthenticated = snapshot.data ?? false;

        if (!isAuthenticated) {
          // Navigate to login and remove previous routes
          Future.microtask(() {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(widget.loginRouteName, (route) => false);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return widget.child;
      },
    );
  }
}

/// Helper class for authentication checks
class AuthUtils {
  /// Check if user is authenticated and has valid token
  static Future<bool> isUserAuthenticated() async {
    return await TokenService.isAuthenticated();
  }

  /// Get current user role
  static Future<String?> getCurrentUserRole() async {
    return await TokenService.getUserRole();
  }

  /// Get current user ID
  static Future<String?> getCurrentUserId() async {
    return await TokenService.getUserId();
  }

  /// Get current user email
  static Future<String?> getCurrentUserEmail() async {
    return await TokenService.getUserEmail();
  }

  /// Logout user
  static Future<void> logout() async {
    await TokenService.clearToken();
    authNotifier.notifyAuthStateChanged();
  }

  /// Check if token is about to expire (within 1 hour)
  static Future<bool> isTokenExpiringSoon() async {
    // This would require storing expiry time and checking if it's within 1 hour
    return false;
  }

  /// Refresh user session
  static Future<void> refreshSession() async {
    await TokenService.refreshTokenExpiry();
  }
}
