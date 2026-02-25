import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for managing authentication tokens and user session
class TokenService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _expiryKey = 'token_expiry';
  static const String _providerIdKey = 'provider_id';
  static const String _verificationStatusKey = 'verification_status';

  /// Save token and user data after successful login/signup
  static Future<void> saveToken({
    required String token,
    required Map<String, dynamic> userData,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Save token
    await prefs.setString(_tokenKey, token);

    // Save user data
    await prefs.setString(_userKey, jsonEncode(userData));

    // Calculate and save expiry (12 hours from now)
    final expiryTime = DateTime.now()
        .add(const Duration(hours: 12))
        .millisecondsSinceEpoch;
    await prefs.setInt(_expiryKey, expiryTime);
  }

  /// Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    // Check if token is expired
    if (token != null) {
      final isValid = await isTokenValid();
      if (!isValid) {
        await clearToken();
        return null;
      }
    }

    return token;
  }

  /// Get stored user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);

    if (userData == null) return null;

    try {
      return jsonDecode(userData) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Check if token is valid and not expired
  static Future<bool> isTokenValid() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token == null) {
      return false;
    }

    final expiryTime = prefs.getInt(_expiryKey);
    if (expiryTime == null) {
      return false;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    return now < expiryTime;
  }

  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Get user ID from stored data
  static Future<String?> getUserId() async {
    final userData = await getUserData();
    return userData?['id'] as String?;
  }

  /// Get user role from stored data
  static Future<String?> getUserRole() async {
    final userData = await getUserData();
    return userData?['role'] as String?;
  }

  /// Get user email from stored data
  static Future<String?> getUserEmail() async {
    final userData = await getUserData();
    return userData?['email'] as String?;
  }

  /// Clear token and user data (logout)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_expiryKey);
    await clearProviderData();
  }

  /// Refresh token validity (extend session)
  static Future<void> refreshTokenExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token != null) {
      final expiryTime = DateTime.now()
          .add(const Duration(hours: 12))
          .millisecondsSinceEpoch;
      await prefs.setInt(_expiryKey, expiryTime);
    }
  }

  /// Save provider ID after provider profile creation
  static Future<void> saveProviderId(String providerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerIdKey, providerId);
  }

  /// Get stored provider ID
  static Future<String?> getProviderId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_providerIdKey);
  }

  /// Save verification status
  static Future<void> saveVerificationStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_verificationStatusKey, status);
  }

  /// Get stored verification status
  static Future<String?> getVerificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_verificationStatusKey);
  }

  /// Clear provider-related data (for logout)
  static Future<void> clearProviderData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_providerIdKey);
    await prefs.remove(_verificationStatusKey);
  }
}
