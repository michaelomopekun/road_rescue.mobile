import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:road_rescue/services/api_client.dart';
import 'package:road_rescue/services/token_service.dart';
import 'package:road_rescue/services/exceptions.dart';
import 'package:road_rescue/services/auth_notifier.dart';
import 'package:road_rescue/services/fcm_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Service for handling authentication API calls
class AuthService {
  /// Register a new user
  ///
  /// Parameters:
  /// - fullName: User full name
  /// - email: User email address
  /// - password: User password (min 8 chars)
  /// - phone: User phone number
  /// - role: User role (DRIVER or PROVIDER)
  static Future<RegisterResponse> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String role,
    String? plateNumber,
  }) async {
    try {
      final response = await ApiClient.post(
        '/auth/register',
        body: {
          'fullName': fullName,
          'email': email,
          'password': password,
          'phone': phone,
          'role': role,
          if (plateNumber != null) 'plateNumber': plateNumber,
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

        // If provider/mechanic, fetch verification status FIRST before saving token
        String? verificationStatus;
        if (loginResponse.role == 'PROVIDER' ||
            loginResponse.role == 'mechanic') {
          try {
            // Make direct HTTP call with fresh token (don't use stored token yet)
            final uri = Uri.parse(
              '${ApiClient.baseUrl}/providers/${loginResponse.userId}/verification-status',
            );
            final verifyResponse = await http
                .get(
                  uri,
                  headers: {
                    'Authorization': 'Bearer ${loginResponse.accessToken}',
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                  },
                )
                .timeout(const Duration(seconds: 30));

            if (verifyResponse.statusCode == 200) {
              final statusData =
                  jsonDecode(verifyResponse.body) as Map<String, dynamic>;
              verificationStatus =
                  statusData['verificationStatus'] as String? ?? 'NOT_VERIFIED';
            } else {
              verificationStatus = 'NOT_VERIFIED';
            }
          } catch (e) {
            // If status check fails, assume NOT_VERIFIED for new mechanics
            print('Error fetching verification status during login: $e');
            verificationStatus = 'NOT_VERIFIED';
          }
        }

        // Now save verification status first (doesn't trigger rebuild)
        if (verificationStatus != null) {
          await TokenService.saveVerificationStatus(verificationStatus);
          print('[AuthService] Verification status saved: $verificationStatus');
        }

        // Then save token and user data (this triggers main.dart rebuild)
        // By now, verification status is already in SharedPreferences
        print(
          '[AuthService] Saving token: ${loginResponse.accessToken.substring(0, 20)}...',
        );
        print(
          '[AuthService] User data - ID: ${loginResponse.userId}, Role: ${loginResponse.role}',
        );
        await TokenService.saveToken(
          token: loginResponse.accessToken,
          userData: {
            'id': loginResponse.userId,
            'email': loginResponse.email,
            'role': loginResponse.role,
          },
        );
        print('[AuthService] Token saved successfully');

        // Verify token was saved
        final savedToken = await TokenService.getToken();
        final savedRole = await TokenService.getUserRole();
        print(
          '[AuthService] Verification - Token exists: ${savedToken != null}, Role: $savedRole',
        );

        // Notify listeners that auth state has changed
        authNotifier.notifyAuthStateChanged();
        print('[AuthService] Auth notifier triggered');

        try {
          // Register device for push notifications
          final fcmToken = await FirebaseMessaging.instance.getToken();
          await FcmService.registerDevice(fcmToken);
        } catch (e) {
          print('Failed to register FCM during login: $e');
        }

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
    // Attempt to unregister FCM token before logging out locally
    try {
      await FcmService.registerDevice(null);
    } catch (e) {
      print('Failed to unregister FCM token during logout: $e');
    }

    await TokenService.clearToken();
    authNotifier.notifyAuthStateChanged();
  }

  /// Check if user is currently authenticated
  static Future<bool> isAuthenticated() async {
    return await TokenService.isAuthenticated();
  }

  /// Create provider profile with business information
  ///
  /// Parameters:
  /// - userId: User ID from TokenService
  /// - businessName: Name of the business/workshop
  /// - businessPhone: Phone number of the business
  /// - businessAddress: Full address of the business
  /// - baseLatitude: Latitude from place API
  /// - baseLongitude: Longitude from place API
  ///
  /// Returns: CreateProviderResponse with service provider ID
  static Future<CreateProviderResponse> createProviderProfile({
    required String userId,
    required String businessName,
    required String businessPhone,
    required String businessAddress,
    String providerType = 'INDIVIDUAL',
    required double baseLatitude,
    required double baseLongitude,
  }) async {
    try {
      final response = await ApiClient.post(
        '/providers/profile',
        body: {
          'userId': userId,
          'businessName': businessName,
          'businessPhone': businessPhone,
          'businessAddress': businessAddress,
          'providerType': providerType,
          'baseLatitude': baseLatitude,
          'baseLongitude': baseLongitude,
        },
        requiresAuth: true,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return CreateProviderResponse.fromJson(data);
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        final messages = error['message'] is List
            ? List<String>.from(
                (error['message'] as List).map((e) => e.toString()),
              )
            : [error['message']?.toString() ?? 'Validation error'];
        throw ValidationException(messages);
      } else if (response.statusCode == 403) {
        throw UnauthorizedException('Only PROVIDER users can create a profile');
      } else {
        throw ApiException(
          'Create provider profile failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Upload verification document for provider
  ///
  /// Parameters:
  /// - serviceProviderId: ID of the service provider (from createProviderProfile)
  /// - documentType: Type of document (e.g., 'RC', 'CERTIFICATION', 'ID')
  /// - documentNumber: Document number/reference
  /// - fileBytes: File contents as bytes
  /// - fileName: Name of the file
  ///
  /// Returns: UploadDocumentResponse with document URL
  static Future<UploadDocumentResponse> uploadVerificationDocument({
    required String serviceProviderId,
    required String documentType,
    required String documentNumber,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      final response = await ApiClient.postMultipart(
        '/providers/documents',
        fields: {
          'serviceProviderId': serviceProviderId,
          'documentType': documentType,
          'documentNumber': documentNumber,
        },
        files: {'file': (fileName, fileBytes)},
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return UploadDocumentResponse.fromJson(data);
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        final messages = error['message'] is List
            ? List<String>.from(
                (error['message'] as List).map((e) => e.toString()),
              )
            : [error['message']?.toString() ?? 'Validation error'];
        print('Upload document validation error: $messages');
        throw ValidationException(messages);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Provider not found');
      } else {
        throw ApiException('Upload document failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get verification status for a provider
  ///
  /// Parameters:
  /// - providerId: Service provider ID (or user ID if no provider exists)
  ///
  /// Returns: GetVerificationStatusResponse with current verification status
  static Future<GetVerificationStatusResponse> getVerificationStatus({
    required String providerId,
  }) async {
    try {
      final response = await ApiClient.get(
        '/providers/$providerId/verification-status',
        requiresAuth: true,
      );

      print(
        'Get verification status response: ${response.statusCode} ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return GetVerificationStatusResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Provider not found');
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        final messages = error['message'] is List
            ? List<String>.from(
                (error['message'] as List).map((e) => e.toString()),
              )
            : [error['message']?.toString() ?? 'Validation error'];
        throw ValidationException(messages);
      } else {
        throw ApiException(
          'Get verification status failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
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

/// Response model for creating provider profile
class CreateProviderResponse {
  final String id;
  final String userId;
  final String providerType;
  final String businessName;
  final String verificationStatus;
  final String createdAt;

  CreateProviderResponse({
    required this.id,
    required this.userId,
    required this.providerType,
    required this.businessName,
    required this.verificationStatus,
    required this.createdAt,
  });

  factory CreateProviderResponse.fromJson(Map<String, dynamic> json) {
    return CreateProviderResponse(
      id: json['id'] as String,
      userId: json['userId'] as String,
      providerType: json['providerType'] as String,
      businessName: json['businessName'] as String,
      verificationStatus: json['verificationStatus'] as String,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

/// Response model for uploading verification document
class UploadDocumentResponse {
  final String id;
  final String serviceProviderId;
  final String documentType;
  final String documentNumber;
  final String documentUrl;
  final String uploadedAt;

  UploadDocumentResponse({
    required this.id,
    required this.serviceProviderId,
    required this.documentType,
    required this.documentNumber,
    required this.documentUrl,
    required this.uploadedAt,
  });

  factory UploadDocumentResponse.fromJson(Map<String, dynamic> json) {
    return UploadDocumentResponse(
      id: json['id'] as String,
      serviceProviderId: json['serviceProviderId'] as String,
      documentType: json['documentType'] as String,
      documentNumber: json['documentNumber'] as String,
      documentUrl: json['documentUrl'] as String,
      uploadedAt: json['uploadedAt'] as String? ?? '',
    );
  }
}

/// Response model for getting verification status
class GetVerificationStatusResponse {
  final String id;
  final String businessName;
  final String verificationStatus;
  final String? verifiedAt;
  final String createdAt;
  final String updatedAt;

  GetVerificationStatusResponse({
    required this.id,
    required this.businessName,
    required this.verificationStatus,
    this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GetVerificationStatusResponse.fromJson(Map<String, dynamic> json) {
    return GetVerificationStatusResponse(
      id: json['id'] as String,
      businessName: json['businessName'] as String,
      verificationStatus: json['verificationStatus'] as String,
      verifiedAt: json['verifiedAt'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}
