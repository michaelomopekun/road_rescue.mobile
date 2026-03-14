import 'package:http/http.dart' as http;
import 'package:road_rescue/services/token_service.dart';
import 'package:road_rescue/services/exceptions.dart';
import 'package:road_rescue/main.dart' show navigatorKey;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class ApiClient {
  static String get baseUrl =>
      // "http://10.194.220.3:3438";
      // "http://10.0.2.2:3438";
      // "localhost:3438";
      dotenv.env['BASE_URL'] ?? '';

  // envProperties.getProperty("GOOGLE_MAPS_API_KEY", "")
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
    print('GET $endpoint (requiresAuth: $requiresAuth)');
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

  /// Performs a multipart POST request with file upload
  ///
  /// Parameters:
  /// - endpoint: API endpoint
  /// - fields: Map of field names to string values
  /// - files: Map of field names to (fileName, fileBytes) tuples
  /// - requiresAuth: Whether to include authentication token
  static Future<http.Response> postMultipart(
    String endpoint, {
    required Map<String, String> fields,
    required Map<String, (String, List<int>)> files,
    bool requiresAuth = true,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final token = requiresAuth ? await TokenService.getToken() : null;

    if (token == null && requiresAuth) {
      throw UnauthorizedException('No token found. Please login again.');
    }

    try {
      final request = http.MultipartRequest('POST', url);

      // Add fields
      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      // Add files with proper content type
      files.forEach((key, fileData) {
        final (fileName, fileBytes) = fileData;

        // Determine content type based on file extension
        String contentType = 'application/octet-stream';
        if (fileName.endsWith('.pdf')) {
          contentType = 'application/pdf';
        } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
          contentType = 'image/jpeg';
        } else if (fileName.endsWith('.png')) {
          contentType = 'image/png';
        } else if (fileName.endsWith('.doc')) {
          contentType = 'application/msword';
        } else if (fileName.endsWith('.docx')) {
          contentType =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        }

        print(
          'Adding file: $key = $fileName (${fileBytes.length} bytes, type: $contentType)',
        );

        request.files.add(
          http.MultipartFile.fromBytes(
            key,
            fileBytes,
            filename: fileName,
            contentType: http.MediaType.parse(contentType),
          ),
        );
      });

      // Add authorization header
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final response = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final responseBody = await http.Response.fromStream(response);
      print('Multipart response status: ${responseBody.statusCode}');
      print('Multipart response body: ${responseBody.body}');

      return responseBody;
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
        _handleUnauthorized();
        throw UnauthorizedException('No token found. Please login again.');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Centralized handler for 401 Unauthorized API responses
  static void _handleUnauthorized() {
    TokenService.clearAuthData();

    // Defer the UI action out of the current build cycle
    Future.microtask(() {
      try {
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      } catch (e) {
        print('[ApiClient] Could not invoke navigator override: $e');
      }
    });
  }
}
