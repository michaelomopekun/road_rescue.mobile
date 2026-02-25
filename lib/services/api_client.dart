import 'package:http/http.dart' as http;
import 'package:road_rescue/services/token_service.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class ApiClient {
  static String baseUrl = "http://10.53.234.3:3438";
  // dotenv.env['BASE_URL'] ??

  /// Performs a POST request with token injection
  static Future<http.Response> post(
    String endpoint, {
    required Map<String, dynamic> body,
    bool requiresAuth = false,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requiresAuth);

    try {
      final response = await http
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// Performs a GET request with token injection
  static Future<http.Response> get(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requiresAuth);

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// Performs a PUT request with token injection
  static Future<http.Response> put(
    String endpoint, {
    required Map<String, dynamic> body,
    bool requiresAuth = false,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requiresAuth);

    try {
      final response = await http
          .put(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// Performs a DELETE request with token injection
  static Future<http.Response> delete(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders(requiresAuth);

    try {
      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      return response;
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// Get headers with optional authorization
  static Future<Map<String, String>> _getHeaders(bool requiresAuth) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await TokenService.getToken();
      if (token == null) {
        throw UnauthorizedException('No token found. Please login again.');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}

/// Exception for unauthorized access
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// Exception for validation errors
class ValidationException implements Exception {
  final List<String> errors;
  ValidationException(this.errors);

  @override
  String toString() => 'ValidationException: ${errors.join(', ')}';
}
