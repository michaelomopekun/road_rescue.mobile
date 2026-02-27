import 'dart:convert';
import 'package:road_rescue/services/api_client.dart';
import 'package:road_rescue/services/exceptions.dart';

class MechanicService {
  /// Get current month earnings for mechanic
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

  /// Get current month job count for mechanic
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

  /// Get recent completed jobs for mechanic
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

  /// Update mechanic availability status
  static Future<void> updateAvailabilityStatus(
    String mechanicId,
    bool isAvailable,
  ) async {
    try {
      final response = await ApiClient.put(
        '/mechanics/$mechanicId/availability',
        body: {'isAvailable': isAvailable},
        requiresAuth: true,
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to update availability: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error updating availability: $e');
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
