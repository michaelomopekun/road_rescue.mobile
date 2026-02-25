import 'dart:convert';
import 'package:road_rescue/services/api_client.dart';
import 'package:road_rescue/services/token_service.dart';

/// Service for handling authentication API calls
class AuthService {
  /// Register a new user
  ///
  /// Parameters:
  /// - email: User email address
  /// - password: User password (min 8 chars)
  /// - phone: User phone number
  /// - role: User role (DRIVER or PROVIDER)
  static Future<RegisterResponse> register({
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    try {
      final response = await ApiClient.post(
        '/auth/register',
        body: {
          'email': email,
          'password': password,
          'phone': phone,
          'role': role,
        },
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return RegisterResponse.fromJson(data);
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        final messages = error['message'] is List
            ? List<String>.from(
                (error['message'] as List).map((e) => e.toString()),
              )
            : [error['message']?.toString() ?? 'Validation error'];
        throw ValidationException(messages);
      } else {
        throw ApiException('Registration failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Login user with email and password
  ///
  /// Parameters:
  /// - email: User email address
  /// - password: User password
  ///
  /// Returns: LoginResponse with access token and user data
  static Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiClient.post(
        '/auth/login',
        body: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final loginResponse = LoginResponse.fromJson(data);

        // Save token and user data
        await TokenService.saveToken(
          token: loginResponse.accessToken,
          userData: {
            'id': loginResponse.userId,
            'email': loginResponse.email,
            'role': loginResponse.role,
          },
        );

        return loginResponse;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Invalid email or password');
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        final messages = error['message'] is List
            ? List<String>.from(error['message'] as List)
            : [error['message'] as String? ?? 'Validation error'];
        throw ValidationException(messages);
      } else {
        throw ApiException('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Check if email already exists in the system
  ///
  /// Parameters:
  /// - email: Email address to check
  ///
  /// Returns: true if email exists, false otherwise
  static Future<EmailCheckResponse> checkEmailExists(String email) async {
    try {
      final response = await ApiClient.post(
        '/auth/check-email',
        body: {'email': email},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return EmailCheckResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        return EmailCheckResponse(exists: false, email: email, role: null);
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        final messages = error['message'] is List
            ? List<String>.from(error['message'] as List)
            : [error['message'] as String? ?? 'Validation error'];
        throw ValidationException(messages);
      } else {
        throw ApiException('Check email failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Logout user (clear local token)
  static Future<void> logout() async {
    await TokenService.clearToken();
  }

  /// Check if user is currently authenticated
  static Future<bool> isAuthenticated() async {
    return await TokenService.isAuthenticated();
  }
}

/// Response model for registration
class RegisterResponse {
  final String id;
  final String email;
  final String role;
  final bool isActive;
  final String createdAt;

  RegisterResponse({
    required this.id,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

/// Response model for login
class LoginResponse {
  final String accessToken;
  final String userId;
  final String? phone;
  final String email;
  final String role;

  LoginResponse({
    required this.accessToken,
    required this.userId,
    this.phone,
    required this.email,
    required this.role,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      userId: json['userId'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String,
      role: json['role'] as String,
    );
  }
}

class EmailCheckResponse {
  final bool exists;
  final String email;
  final String? role;

  EmailCheckResponse({required this.exists, required this.email, this.role});

  factory EmailCheckResponse.fromJson(Map<String, dynamic> json) {
    return EmailCheckResponse(
      exists: json['exists'] as bool,
      email: json['email'] as String,
      role: json['role'] as String?,
    );
  }
}
