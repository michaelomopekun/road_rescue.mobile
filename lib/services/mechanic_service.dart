import 'dart:convert';
import 'package:road_rescue/services/api_client.dart';
import 'package:road_rescue/services/exceptions.dart';
import 'package:road_rescue/models/service_request.dart';
import 'package:road_rescue/models/quotation.dart';

class MechanicService {
  /// Get provider's active request
  static Future<ServiceRequest?> getActiveRequest() async {
    try {
      final response = await ApiClient.get('/requests/active', requiresAuth: true);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data == null || (data is Map && data.isEmpty)) return null;
        return ServiceRequest.fromJson(data);
      } else if (response.statusCode == 404) {
        return null; // No active request
      }
      return null;
    } catch (e) {
      print('[MechanicService] Error getting active request: $e');
      return null;
    }
  }

  /// Accept incoming request
  static Future<bool> acceptRequest(String requestId) async {
    try {
      // Backend validates if already taken, returns 409 if conflict
      final response = await ApiClient.post('/requests/$requestId/accept', body: {}, requiresAuth: true);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('[MechanicService] Error accepting request: $e');
      return false;
    }
  }

  /// Mark request as arrived
  static Future<bool> markArrived(String requestId) async {
    try {
      final response = await ApiClient.post('/requests/$requestId/arrived', body: {}, requiresAuth: true);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('[MechanicService] Error marking arrived: $e');
      return false;
    }
  }

  /// Submit quotation
  static Future<bool> submitQuotation(String requestId, Quotation quotation) async {
    try {
      final body = quotation.toJson();
      body['requestId'] = requestId;
      
      final response = await ApiClient.post('/quotations', body: body, requiresAuth: true);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('[MechanicService] Error submitting quotation: $e');
      return false;
    }
  }

  /// Mark request as completed
  static Future<bool> markCompleted(String requestId) async {
    try {
      final response = await ApiClient.post('/requests/$requestId/complete', body: {}, requiresAuth: true);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('[MechanicService] Error marking completed: $e');
      return false;
    }
  }

  /// Get provider verification status
  static Future<ProviderVerificationStatus> getVerificationStatus(
    String providerId,
  ) async {
    try {
      final response = await ApiClient.get(
        '/providers/$providerId/verification-status',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ProviderVerificationStatus.fromJson(data);
      } else if (response.statusCode == 404) {
        throw ApiException('Provider not found');
      } else {
        throw ApiException(
          'Failed to fetch verification status: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error fetching verification status: $e');
    }
  }

  /// Get provider request history (for dashboard - limited)
  static Future<List<RecentJob>> getRequestHistory({int limit = 5}) async {
    try {
      final response = await ApiClient.get(
        '/providers/me/request-history?page=1&limit=$limit&status=COMPLETED',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final jobs =
            (data['data'] as List<dynamic>?)
                ?.map((job) => RecentJob.fromJson(job as Map<String, dynamic>))
                .toList() ??
            [];
        return jobs;
      } else {
        throw ApiException(
          'Failed to fetch request history: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error fetching request history: $e');
    }
  }

  /// Get paginated request history with filters
  /// Used for the history page to display all jobs with pagination
  static Future<RequestHistoryPaginated> getRequestHistoryPaginated({
    int page = 1,
    int limit = 10,
    String status = 'COMPLETED', // ASSIGNED, COMPLETED, or null for all
  }) async {
    try {
      String url = '/providers/me/request-history?page=$page&limit=$limit';
      if (status.isNotEmpty) {
        url += '&status=$status';
      }

      final response = await ApiClient.get(url, requiresAuth: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RequestHistoryPaginated.fromJson(data);
      } else if (response.statusCode == 401) {
        throw ApiException('Unauthorized - invalid or missing token');
      } else {
        throw ApiException(
          'Failed to fetch request history: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error fetching request history: $e');
    }
  }

  /// Update provider availability status (uses /providers/me/availability)
  static Future<ProviderVerificationStatus> updateAvailabilityStatus(
    bool isAvailable,
  ) async {
    try {
      final response = await ApiClient.put(
        '/providers/me/availability',
        body: {'availabilityStatus': isAvailable ? 'AVAILABLE' : 'OFFLINE'},
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(
          '============== successfully Updated availability status: ${data['availabilityStatus']}==============',
        );
        return ProviderVerificationStatus.fromJson(data);
      } else {
        print(
          '==============Failed to update availability: ${response.statusCode} - ${response.body}==============',
        );
        throw ApiException(
          'Failed to update availability: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      print('==============Error updating availability: $e==============');
      throw ApiException('Error updating availability: $e');
    }
  }

  /// Get current month earnings for mechanic (legacy endpoint - may need update)
  static Future<double> getCurrentMonthEarnings(String mechanicId) async {
    try {
      final response = await ApiClient.get(
        '/mechanics/$mechanicId/earnings',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['earnings'] as num?)?.toDouble() ?? 0.0;
      } else {
        throw ApiException('Failed to fetch earnings: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error fetching earnings: $e');
    }
  }

  /// Get current month job count for mechanic (legacy endpoint - may need update)
  static Future<int> getCurrentMonthJobCount(String mechanicId) async {
    try {
      final response = await ApiClient.get(
        '/mechanics/$mechanicId/job-count',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['jobCount'] as int?) ?? 0;
      } else {
        throw ApiException('Failed to fetch job count: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error fetching job count: $e');
    }
  }

  /// Get recent completed jobs for mechanic (legacy endpoint - may need update)
  static Future<List<RecentJob>> getRecentJobs(
    String mechanicId, {
    int limit = 5,
  }) async {
    try {
      final response = await ApiClient.get(
        '/mechanics/$mechanicId/recent-jobs?limit=$limit',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final jobs =
            (data['jobs'] as List<dynamic>?)
                ?.map((job) => RecentJob.fromJson(job as Map<String, dynamic>))
                .toList() ??
            [];
        return jobs;
      } else {
        throw ApiException(
          'Failed to fetch recent jobs: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error fetching recent jobs: $e');
    }
  }

  /// Get mechanic dashboard data (combined call)
  static Future<MechanicDashboardData> getDashboardData(
    String mechanicId,
  ) async {
    try {
      final response = await ApiClient.get(
        '/mechanics/$mechanicId/dashboard',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MechanicDashboardData.fromJson(data);
      } else {
        throw ApiException(
          'Failed to fetch dashboard data: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error fetching dashboard data: $e');
    }
  }

  /// Get provider dashboard data (SINGLE AGGREGATED ENDPOINT)
  /// Fetches all dashboard data in one request: profile, verification, earnings, recent jobs
  /// This is the most efficient approach (~1 request instead of 3)
  static Future<ProviderDashboardData> getProviderDashboardData(
    String providerId,
  ) async {
    try {
      print(
        '[MechanicService] Loading provider dashboard from aggregated endpoint...',
      );

      // Single unified request to backend endpoint
      final response = await ApiClient.get(
        '/providers/me/dashboard',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dashboardResponse = DashboardResponse.fromJson(data);

        print('[MechanicService] Dashboard data loaded successfully');

        // Convert response to ProviderDashboardData for UI consumption
        return ProviderDashboardData(
          businessName: dashboardResponse.profile.businessName,
          verificationStatus: dashboardResponse.verificationStatus.status,
          isAvailable:
              dashboardResponse.availabilityStatus.status == 'AVAILABLE',
          monthlyEarnings: dashboardResponse.earnings.monthlyEarnings,
          recentJobs: dashboardResponse.recentJobs
              .map(
                (job) => RecentJob(
                  id: job.id,
                  customerId: job.driverId,
                  customerName: job.driverName,
                  serviceType: job.description,
                  amount: (job.amount as num).toDouble(),
                  status: job.status,
                  completedAt: job.completedAt ?? job.assignedAt,
                  avatarUrl: null,
                ),
              )
              .toList(),
        );
      } else if (response.statusCode == 401) {
        throw ApiException('Unauthorized - invalid or missing token');
      } else if (response.statusCode == 404) {
        throw ApiException('Provider profile not found');
      } else {
        throw ApiException(
          'Failed to fetch dashboard data: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[MechanicService] Error loading provider dashboard: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Error loading provider dashboard: $e');
    }
  }
}

/// Model for provider verification status
class ProviderVerificationStatus {
  final String id;
  final String businessName;
  final String verificationStatus; // PENDING, APPROVED, REJECTED
  final String? availabilityStatus; // AVAILABLE, OFFLINE
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProviderVerificationStatus({
    required this.id,
    required this.businessName,
    required this.verificationStatus,
    this.availabilityStatus,
    this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProviderVerificationStatus.fromJson(Map<String, dynamic> json) {
    return ProviderVerificationStatus(
      id: json['id'] as String,
      businessName: json['businessName'] as String,
      verificationStatus: json['verificationStatus'] as String,
      availabilityStatus: json['availabilityStatus'] as String?,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Model for recent job
class RecentJob {
  final String id;
  final String customerId;
  final String customerName;
  final String serviceType;
  final double amount;
  final String status;
  final DateTime completedAt;
  final String? avatarUrl;

  RecentJob({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.serviceType,
    required this.amount,
    required this.status,
    required this.completedAt,
    this.avatarUrl,
  });

  factory RecentJob.fromJson(Map<String, dynamic> json) {
    return RecentJob(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      serviceType: json['serviceType'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String? ?? 'Completed',
      completedAt: DateTime.parse(json['completedAt'] as String),
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

/// Model for mechanic dashboard data
class MechanicDashboardData {
  final double currentMonthEarnings;
  final int currentMonthJobCount;
  final List<RecentJob> recentJobs;
  final bool isAvailable;

  MechanicDashboardData({
    required this.currentMonthEarnings,
    required this.currentMonthJobCount,
    required this.recentJobs,
    required this.isAvailable,
  });

  factory MechanicDashboardData.fromJson(Map<String, dynamic> json) {
    return MechanicDashboardData(
      currentMonthEarnings:
          (json['currentMonthEarnings'] as num?)?.toDouble() ?? 0.0,
      currentMonthJobCount: (json['currentMonthJobCount'] as int?) ?? 0,
      recentJobs:
          (json['recentJobs'] as List<dynamic>?)
              ?.map((job) => RecentJob.fromJson(job as Map<String, dynamic>))
              .toList() ??
          [],
      isAvailable: (json['isAvailable'] as bool?) ?? false,
    );
  }
}

/// Dashboard response from /providers/me/dashboard endpoint
class DashboardResponse {
  final DashboardProfile profile;
  final DashboardVerificationStatus verificationStatus;
  final DashboardAvailabilityStatus availabilityStatus;
  final DashboardEarnings earnings;
  final List<DashboardJob> recentJobs;

  DashboardResponse({
    required this.profile,
    required this.verificationStatus,
    required this.availabilityStatus,
    required this.earnings,
    required this.recentJobs,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      profile: DashboardProfile.fromJson(
        json['profile'] as Map<String, dynamic>,
      ),
      verificationStatus: DashboardVerificationStatus.fromJson(
        json['verificationStatus'] as Map<String, dynamic>,
      ),
      availabilityStatus: DashboardAvailabilityStatus.fromJson(
        json['availabilityStatus'] as Map<String, dynamic>,
      ),
      earnings: DashboardEarnings.fromJson(
        json['earnings'] as Map<String, dynamic>,
      ),
      recentJobs:
          (json['recentJobs'] as List<dynamic>?)
              ?.map((job) => DashboardJob.fromJson(job as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Provider profile information
class DashboardProfile {
  final String id;
  final String userId;
  final String businessName;
  final String businessPhone;
  final String businessAddress;
  final String providerType; // INDIVIDUAL or COMPANY

  DashboardProfile({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.businessPhone,
    required this.businessAddress,
    required this.providerType,
  });

  factory DashboardProfile.fromJson(Map<String, dynamic> json) {
    return DashboardProfile(
      id: json['id'] as String,
      userId: json['userId'] as String,
      businessName: json['businessName'] as String,
      businessPhone: json['businessPhone'] as String,
      businessAddress: json['businessAddress'] as String,
      providerType: json['providerType'] as String,
    );
  }
}

/// Verification status information
class DashboardVerificationStatus {
  final String status; // APPROVED, PENDING, REJECTED
  final DateTime? verifiedAt;

  DashboardVerificationStatus({required this.status, this.verifiedAt});

  factory DashboardVerificationStatus.fromJson(Map<String, dynamic> json) {
    return DashboardVerificationStatus(
      status: json['status'] as String,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'] as String)
          : null,
    );
  }
}

/// Availability status information
class DashboardAvailabilityStatus {
  final String status; // AVAILABLE, OFFLINE
  final DateTime updatedAt;

  DashboardAvailabilityStatus({required this.status, required this.updatedAt});

  factory DashboardAvailabilityStatus.fromJson(Map<String, dynamic> json) {
    return DashboardAvailabilityStatus(
      status: json['status'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Earnings information
class DashboardEarnings {
  final double monthlyEarnings;
  final String currency; // NGN, USD, etc.
  final String period; // "February 2026"
  final DateTime lastUpdated;

  DashboardEarnings({
    required this.monthlyEarnings,
    required this.currency,
    required this.period,
    required this.lastUpdated,
  });

  factory DashboardEarnings.fromJson(Map<String, dynamic> json) {
    return DashboardEarnings(
      monthlyEarnings: (json['monthlyEarnings'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String,
      period: json['period'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
}

/// Job information from dashboard
class DashboardJob {
  final String id;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String description;
  final String location;
  final String status; // COMPLETED, ASSIGNED, etc.
  final int amount;
  final DateTime assignedAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  DashboardJob({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.description,
    required this.location,
    required this.status,
    required this.amount,
    required this.assignedAt,
    this.completedAt,
    required this.createdAt,
  });

  factory DashboardJob.fromJson(Map<String, dynamic> json) {
    return DashboardJob(
      id: json['id'] as String,
      driverId: json['driverId'] as String,
      driverName: json['driverName'] as String,
      driverPhone: json['driverPhone'] as String,
      description: json['description'] as String,
      location: json['location'] as String,
      status: json['status'] as String,
      amount: json['amount'] as int,
      assignedAt: DateTime.parse(json['assignedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Paginated request history response
class RequestHistoryPaginated {
  final List<HistoryJob> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  RequestHistoryPaginated({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory RequestHistoryPaginated.fromJson(Map<String, dynamic> json) {
    return RequestHistoryPaginated(
      data:
          (json['data'] as List<dynamic>?)
              ?.map((job) => HistoryJob.fromJson(job as Map<String, dynamic>))
              .toList() ??
          [],
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 10,
      total: json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }
}

/// Job from history endpoint (more detailed than RecentJob)
class HistoryJob {
  final String id;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String description;
  final String location;
  final double? latitude;
  final double? longitude;
  final String status; // ASSIGNED, COMPLETED
  final double amount;
  final DateTime assignedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  HistoryJob({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.description,
    required this.location,
    this.latitude,
    this.longitude,
    required this.status,
    this.amount = 0.0,
    required this.assignedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert to RecentJob for compatibility
  RecentJob toRecentJob() {
    return RecentJob(
      id: id,
      customerId: driverId,
      customerName: driverName,
      serviceType: description,
      amount: amount,
      status: status,
      completedAt: completedAt ?? assignedAt,
      avatarUrl: null,
    );
  }

  factory HistoryJob.fromJson(Map<String, dynamic> json) {
    return HistoryJob(
      id: json['id'] as String,
      driverId: json['driverId'] as String,
      driverName: json['driverName'] as String,
      driverPhone: json['driverPhone'] as String,
      description: json['description'] as String,
      location: json['location'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      status: json['status'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      assignedAt: DateTime.parse(json['assignedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Aggregated dashboard data for the mechanic dashboard UI
/// Contains all necessary information from the backend dashboard endpoint
class ProviderDashboardData {
  final String businessName;
  final String verificationStatus; // APPROVED, PENDING, REJECTED
  final bool isAvailable;
  final double monthlyEarnings;
  final List<RecentJob> recentJobs;

  ProviderDashboardData({
    required this.businessName,
    required this.verificationStatus,
    required this.isAvailable,
    required this.monthlyEarnings,
    required this.recentJobs,
  });

  /// Calculate job count from recent jobs list
  int get jobCount => recentJobs.length;

  /// Get total earnings (from monthly earnings data)
  double get totalEarnings => monthlyEarnings;
}
