import 'dart:convert';
import 'package:road_rescue/services/api_client.dart';
import 'package:road_rescue/services/exceptions.dart';

class DriverService {
  /// Create a service request and get nearby providers
  ///
  /// Calls POST /requests with driver location and issue description.
  /// Returns a [ServiceRequestResponse] containing the created request
  /// and a list of nearby verified providers sorted by distance.
  static Future<ServiceRequestResponse> createServiceRequest({
    required String driverId,
    required String description,
    required String location,
    required double latitude,
    required double longitude,
  }) async {
    try {
      print('[DriverService] Creating service request...');
      print('[DriverService] Location: $location ($latitude, $longitude)');

      final response = await ApiClient.post(
        '/requests',
        body: {
          'driverId': driverId,
          'description': description,
          'location': location,
          'latitude': latitude,
          'longitude': longitude,
        },
        requiresAuth: true,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('[DriverService] Service request created successfully: ${data['id']}');
        print('[DriverService] Found ${(data['nearbyProviders'] as List?)?.length ?? 0} nearby providers');
        return ServiceRequestResponse.fromJson(data);
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        final messages = (data['message'] is List)
            ? (data['message'] as List).cast<String>()
            : [data['message'].toString()];
        throw ValidationException(messages);
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized - invalid or missing token');
      } else if (response.statusCode == 403) {
        throw ApiException('Only DRIVER users can create requests');
      } else {
        throw ApiException(
          'Failed to create service request: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[DriverService] Error creating service request: $e');
      if (e is ApiException || e is ValidationException || e is UnauthorizedException) {
        rethrow;
      }
      throw ApiException('Error creating service request: $e');
    }
  }

  /// Assign a specific provider to a service request
  ///
  /// Calls PUT /requests/:requestId/assign with the selected provider ID.
  /// The backend sets the request status to PENDING and sends FCM to the provider.
  /// Returns the updated service request.
  static Future<Map<String, dynamic>> assignProviderToRequest({
    required String requestId,
    required String providerId,
  }) async {
    try {
      print('[DriverService] Assigning provider $providerId to request $requestId...');

      final response = await ApiClient.put(
        '/requests/$requestId/assign',
        body: {
          'providerId': providerId,
        },
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[DriverService] Provider assigned successfully. Status: ${data['status']}');
        return data;
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        final message = data['message'] is List
            ? (data['message'] as List).join(', ')
            : data['message'].toString();
        throw ApiException(message);
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized - invalid or missing token');
      } else if (response.statusCode == 404) {
        throw ApiException('Request or provider not found');
      } else {
        throw ApiException(
          'Failed to assign provider: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[DriverService] Error assigning provider: $e');
      if (e is ApiException || e is UnauthorizedException) rethrow;
      throw ApiException('Error assigning provider: $e');
    }
  }

  /// Get driver request history (for dashboard - limited to recent activity)
  ///
  /// Calls GET /requests/history?page=1&limit=3 for the home screen widget.
  static Future<List<DriverHistoryRequest>> getRecentRequestHistory({
    int limit = 3,
  }) async {
    try {
      print('[DriverService] Fetching recent request history (limit=$limit)...');

      final response = await ApiClient.get(
        '/requests/history?page=1&limit=$limit',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final requests = (data['data'] as List<dynamic>?)
                ?.map((r) =>
                    DriverHistoryRequest.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [];
        print(
            '[DriverService] Fetched ${requests.length} recent history items');
        return requests;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized - invalid or missing token');
      } else if (response.statusCode == 403) {
        throw ApiException(
            'Only DRIVER users can view their request history');
      } else {
        throw ApiException(
          'Failed to fetch request history: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[DriverService] Error fetching recent history: $e');
      if (e is ApiException || e is UnauthorizedException) rethrow;
      throw ApiException('Error fetching request history: $e');
    }
  }

  /// Get paginated driver request history with filters
  ///
  /// Calls GET /requests/history with page, limit, and optional status filter.
  /// Used for the full history page with infinite scroll and COMPLETED/CANCELLED tabs.
  static Future<DriverRequestHistoryPaginated> getRequestHistoryPaginated({
    int page = 1,
    int limit = 10,
    String status = 'COMPLETED', // COMPLETED or CANCELLED
  }) async {
    try {
      String url = '/requests/history?page=$page&limit=$limit';
      if (status.isNotEmpty) {
        url += '&status=$status';
      }

      print('[DriverService] Fetching request history: $url');

      final response = await ApiClient.get(url, requiresAuth: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(
            '[DriverService] History loaded: page=${data['page']}, total=${data['total']}');
        return DriverRequestHistoryPaginated.fromJson(data);
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Unauthorized - invalid or missing token');
      } else if (response.statusCode == 403) {
        throw ApiException(
            'Only DRIVER users can view their request history');
      } else {
        throw ApiException(
          'Failed to fetch request history: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[DriverService] Error fetching paginated history: $e');
      if (e is ApiException || e is UnauthorizedException) rethrow;
      throw ApiException('Error fetching request history: $e');
    }
  }
}

/// Response model for POST /requests
class ServiceRequestResponse {
  final String id;
  final String driverId;
  final String status;
  final String description;
  final String location;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final List<NearbyProvider> nearbyProviders;

  ServiceRequestResponse({
    required this.id,
    required this.driverId,
    required this.status,
    required this.description,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.nearbyProviders,
  });

  factory ServiceRequestResponse.fromJson(Map<String, dynamic> json) {
    return ServiceRequestResponse(
      id: json['id'] as String,
      driverId: json['driverId'] as String,
      status: json['status'] as String? ?? 'CREATED',
      description: json['description'] as String,
      location: json['location'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      nearbyProviders: (json['nearbyProviders'] as List<dynamic>?)
              ?.map((p) => NearbyProvider.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Model for a nearby provider returned in the service request response
class NearbyProvider {
  final String id;
  final String businessName;
  final String providerType; // INDIVIDUAL or COMPANY
  final String businessPhone;
  final String businessAddress;
  final double baseLatitude;
  final double baseLongitude;
  final double distanceKm;
  final String verificationStatus;

  NearbyProvider({
    required this.id,
    required this.businessName,
    required this.providerType,
    required this.businessPhone,
    required this.businessAddress,
    required this.baseLatitude,
    required this.baseLongitude,
    required this.distanceKm,
    required this.verificationStatus,
  });

  factory NearbyProvider.fromJson(Map<String, dynamic> json) {
    return NearbyProvider(
      id: json['id'] as String,
      businessName: json['businessName'] as String,
      providerType: json['providerType'] as String? ?? 'INDIVIDUAL',
      businessPhone: json['businessPhone'] as String? ?? '',
      businessAddress: json['businessAddress'] as String? ?? '',
      baseLatitude: (json['baseLatitude'] as num).toDouble(),
      baseLongitude: (json['baseLongitude'] as num).toDouble(),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      verificationStatus: json['verificationStatus'] as String? ?? 'APPROVED',
    );
  }
}

/// Paginated driver request history response from GET /requests/history
class DriverRequestHistoryPaginated {
  final List<DriverHistoryRequest> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  DriverRequestHistoryPaginated({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory DriverRequestHistoryPaginated.fromJson(Map<String, dynamic> json) {
    return DriverRequestHistoryPaginated(
      data: (json['data'] as List<dynamic>?)
              ?.map((r) =>
                  DriverHistoryRequest.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 10,
      total: json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }
}

/// Individual driver request history item from GET /requests/history
class DriverHistoryRequest {
  final String id;
  final String serviceType; // FLAT_TIRE, TOW, BATTERY_JUMP, etc.
  final String description;
  final String status; // COMPLETED or CANCELLED
  final String? providerName; // null if no provider was assigned
  final double? amount; // null for cancelled requests
  final String location;
  final DateTime? completedAt; // null for cancelled requests
  final DateTime createdAt;

  DriverHistoryRequest({
    required this.id,
    required this.serviceType,
    required this.description,
    required this.status,
    this.providerName,
    this.amount,
    required this.location,
    this.completedAt,
    required this.createdAt,
  });

  /// Human-readable service type label
  String get serviceTypeLabel {
    switch (serviceType) {
      case 'FLAT_TIRE':
        return 'Flat Tire';
      case 'TOW':
        return 'Tow Request';
      case 'BATTERY_JUMP':
        return 'Battery Jump';
      case 'LOCKOUT':
        return 'Lockout Service';
      case 'FUEL_DELIVERY':
        return 'Fuel Delivery';
      case 'ENGINE':
        return 'Engine Check';
      default:
        return serviceType.replaceAll('_', ' ').toLowerCase().split(' ').map(
            (w) => w.isNotEmpty
                ? '${w[0].toUpperCase()}${w.substring(1)}'
                : w).join(' ');
    }
  }

  factory DriverHistoryRequest.fromJson(Map<String, dynamic> json) {
    return DriverHistoryRequest(
      id: json['id'] as String,
      serviceType: json['serviceType'] as String? ?? 'GENERAL',
      description: json['description'] as String? ?? '',
      status: json['status'] as String,
      providerName: json['providerName'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      location: json['location'] as String? ?? '',
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
