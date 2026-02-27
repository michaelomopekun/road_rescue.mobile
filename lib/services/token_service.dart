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
    await clearAuthData();
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

  /// Atomically save authentication data (token + user data + role)
  /// This ensures token and role are always in sync
  static Future<void> saveAuthData({
    required String token,
    required Map<String, dynamic> userData,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Save both or nothing - atomic operation
    await Future.wait([
      prefs.setString(_tokenKey, token),
      prefs.setString(_userKey, jsonEncode(userData)),
      prefs.setInt(
        _expiryKey,
        DateTime.now().add(const Duration(hours: 12)).millisecondsSinceEpoch,
      ),
    ]);
  }

  /// Atomically clear all authentication data (token + user data + role)
  /// This ensures token and role are always cleared together
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();

    // Remove all or nothing - atomic operation
    await Future.wait([
      prefs.remove(_tokenKey),
      prefs.remove(_userKey),
      prefs.remove(_expiryKey),
      prefs.remove(_providerIdKey),
      prefs.remove(_verificationStatusKey),
    ]);
  }

  /// Retrieve auth data with defensive check
  /// Returns null if token exists but role doesn't (or vice versa)
  /// This prevents mismatched states during app reload
  static Future<AuthData?> getAuthData() async {
    print('[TokenService] getAuthData() called');
    final token = await getToken();
    print(
      '[TokenService] getToken() returned: ${token != null ? '${token.substring(0, 20)}...' : 'null'}',
    );

    final role = await getUserRole();
    print('[TokenService] getUserRole() returned: $role');

    // If one exists but not the other, something is wrong - clear both
    if ((token != null && role == null) || (token == null && role != null)) {
      // Mismatch detected - clear everything to recover
      print(
        '[TokenService] MISMATCH DETECTED! token!=null: ${token != null}, role!=null: ${role != null}',
      );
      await clearAuthData();
      return null;
    }

    // Both exist or both are null - state is consistent
    if (token != null && role != null) {
      print('[TokenService] SUCCESS: Returning AuthData with role=$role');
      return AuthData(token: token, role: role);
    }

    print('[TokenService] Both token and role are null, returning null');
    return null;
  }
}

/// Model for atomic auth data retrieval
class AuthData {
  final String token;
  final String role;

  AuthData({required this.token, required this.role});
}
