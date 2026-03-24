import 'package:flutter/material.dart';
import 'package:road_rescue/services/token_service.dart';
import 'package:road_rescue/services/mechanic_service.dart';
import 'package:road_rescue/services/toast_service.dart';
import 'package:road_rescue/shared/widgets/stats_card.dart';
import 'package:road_rescue/shared/widgets/request_list_item.dart';
import 'package:road_rescue/features/mechanic/widgets/dashboard_bottom_nav_bar.dart';
import 'package:road_rescue/theme/app_colors.dart';
import 'package:road_rescue/services/request_state_manager.dart';
import 'package:road_rescue/features/mechanic/pages/active_job_page.dart';
import 'package:road_rescue/features/mechanic/widgets/incoming_job_bottom_sheet.dart';
import 'package:road_rescue/models/service_request.dart';
import 'package:road_rescue/models/request_status.dart';

class MechanicDashboard extends StatefulWidget {
  const MechanicDashboard({super.key});

  @override
  State<MechanicDashboard> createState() => _MechanicDashboardState();
}

class _MechanicDashboardState extends State<MechanicDashboard> {
  int _selectedNavIndex = 0;
  bool _isLoading = true;
  bool _isAvailable = false;
  double _currentEarnings = 0.0;
  int _currentJobCount = 0;
  List<RecentJob> _recentJobs = [];
  String? _mechanicName;
  bool _disposed = false;
  bool _isShowingBottomSheet = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    RequestStateManager().addListener(_onRequestStateChanged);
    _onRequestStateChanged(); // Check immediately
  }

  void _onRequestStateChanged() {
    if (_disposed || !mounted) return;

    final state = RequestStateManager();

    // Always rebuild to reflect latest state (active request or not)
    setState(() {});

    if (state.pendingRequests.isNotEmpty && !_isShowingBottomSheet) {
      _showIncomingJob(state.pendingRequests.first);
    }
  }

  void _navigateToActiveJob() async {
    RequestStateManager().removeListener(_onRequestStateChanged);
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ActiveJobPage()));
    // On return, re-attach listener and refresh
    if (!_disposed && mounted) {
      RequestStateManager().addListener(_onRequestStateChanged);
      await RequestStateManager().loadActiveRequest();
      setState(() {});
    }
  }

  Future<void> _showIncomingJob(covariant ServiceRequest request) async {
    _isShowingBottomSheet = true;
    final accepted = await IncomingJobBottomSheet.show(
      context,
      requestId: request.id,
      driverName: request.driverName,
      issueDescription: request.description,
      location: request.location,
      distanceKm: request.distanceKm ?? 0.0,
      driverPhone: request.driverPhone,
    );
    _isShowingBottomSheet = false;

    if (accepted == true) {
      try {
        final success = await MechanicService.acceptRequest(request.id);
        if (success) {
          await RequestStateManager()
              .loadActiveRequest(); // Will trigger navigation
        }
      } catch (e) {
        if (mounted) ToastService.showError(context, e.toString());
      }
    } else if (accepted == false) {
      RequestStateManager().removePendingRequest(request.id);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    RequestStateManager().removeListener(_onRequestStateChanged);
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    if (_disposed) return;

    try {
      final userId = await TokenService.getUserId();
      final userData = await TokenService.getUserData();
      final providerId = await TokenService.getProviderId() ?? userId;

      if (providerId != null && !_disposed) {
        // Set mechanic name early
        if (!_disposed && mounted) {
          setState(() {
            _mechanicName = userData?['name'] as String? ?? '';
          });
        }

        // Load all dashboard data using aggregated endpoint
        try {
          print('[MechanicDashboard] Starting dashboard data load...');
          // No need to pass providerId - endpoint uses authenticated user (/providers/me/dashboard)
          final dashboardData = await MechanicService.getProviderDashboardData(
            providerId,
          );

          if (!_disposed && mounted) {
            setState(() {
              // Update UI with all fetched data
              _recentJobs = dashboardData.recentJobs;
              _currentJobCount = dashboardData.jobCount;
              _currentEarnings = dashboardData.totalEarnings;
              _isAvailable = dashboardData.isAvailable;
              _mechanicName = dashboardData.businessName.substring(0, 5);
            });
            print('[MechanicDashboard] Dashboard data loaded successfully');
          }
        } catch (e) {
          print('[MechanicDashboard] Error loading dashboard data: $e');
          // Fallback to mock data on error
          if (!_disposed && mounted) {
            _loadMockData();
          }
        }
      }
    } catch (e) {
      print('[MechanicDashboard] Error loading mechanic ID: $e');
    } finally {
      if (!_disposed && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _loadMockData() {
    _isAvailable = true;
    _currentEarnings = 1200.0;
    _currentJobCount = 24;
    _recentJobs = [
      RecentJob(
        id: '1',
        customerId: 'cust1',
        customerName: 'Marcus Wright',
        serviceType: 'Tire Replacement',
        amount: 85.00,
        status: 'Completed',
        completedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      RecentJob(
        id: '2',
        customerId: 'cust2',
        customerName: 'Sarah Chen',
        serviceType: 'Battery Jumpstart',
        amount: 45.00,
        status: 'Completed',
        completedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      RecentJob(
        id: '3',
        customerId: 'cust3',
        customerName: 'David Miller',
        serviceType: 'Engine Check',
        amount: 120.00,
        status: 'Completed',
        completedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }

  Future<void> _toggleAvailability(bool value) async {
    if (_disposed || !mounted) return;

    try {
      // Optimistic update
      setState(() {
        _isAvailable = value;
      });

      // Update on backend
      await MechanicService.updateAvailabilityStatus(value);
      if (!_disposed && mounted) {
        ToastService.showSuccess(
          context,
          value ? 'You are now accepting jobs' : 'You are now offline',
        );
      }
    } catch (e) {
      // Revert on error
      if (!_disposed && mounted) {
        setState(() {
          _isAvailable = !value;
        });
        ToastService.showError(context, 'Failed to update availability');
      }
    }
  }

  Future<void> _refreshDashboard() async {
    await _loadDashboardData();
  }

  void _handleNavigation(int index) {
    if (_disposed || !mounted) return;

    setState(() {
      _selectedNavIndex = index;
    });

    switch (index) {
      case 0:
        // Home - already on dashboard
        break;
      case 1:
        // Wallet
        Navigator.of(context).pushNamed('/mechanic/wallet');
        break;
      case 2:
        // Map
        Navigator.of(context).pushNamed('/mechanic/map');
        break;
      case 3:
        // History
        Navigator.of(context).pushNamed('/mechanic/history');
        break;
      case 4:
        // Profile
        Navigator.of(context).pushNamed('/mechanic/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed('/mechanic/profile');
          },
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
            ),
            child: Icon(Icons.person, color: Colors.grey[600]),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () {
              // TODO: Open search
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              // TODO: Open notifications
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, $_mechanicName 👋',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),

              // Online Status Card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _isAvailable
                                    ? Colors.green
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Online Status',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isAvailable ? 'Accepting jobs' : 'Offline',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isAvailable,
                      onChanged: _toggleAvailability,
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Active Request / New Requests Section
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  RequestStateManager().activeRequest != null
                      ? 'Active Request'
                      : 'New Requests',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _buildRequestSection(),

              const SizedBox(height: 28),

              // Earnings Summary Section
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  'Earnings Summary',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: StatsCard(
                      icon: Icons.savings,
                      value: '₦${_currentEarnings.toStringAsFixed(0)}',
                      label: 'Earnings',
                      subtitle: 'This month',
                      onTap: () {
                        Navigator.of(context).pushNamed('/mechanic/wallet');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatsCard(
                      icon: Icons.work,
                      value: '$_currentJobCount',
                      label: 'Jobs',
                      subtitle: 'This month',
                      onTap: () {
                        Navigator.of(context).pushNamed('/mechanic/history');
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Recent History Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      'Recent History',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed('/mechanic/history');
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  children: _recentJobs.isEmpty
                      ? [
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              'No completed jobs yet',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ]
                      : _recentJobs.map((job) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: RequestListItem(
                              customerName: job.customerName,
                              serviceType: job.serviceType,
                              amount: '₦${job.amount.toStringAsFixed(2)}',
                              status: job.status,
                              avatarIcon: Icons.person,
                              onTap: () {
                                // TODO: Navigate to job details
                              },
                            ),
                          );
                        }).toList(),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DashboardBottomNavBar(
        selectedIndex: _selectedNavIndex,
        onTabChanged: _handleNavigation,
        variant: DashboardNavVariant.fullDashboard,
      ),
    );
  }

  Widget _buildRequestSection() {
    final activeRequest = RequestStateManager().activeRequest;
    print(
      '[MechanicDashboard] _buildRequestSection: activeRequest=${activeRequest != null ? 'id=${activeRequest.id}, status=${activeRequest.status}' : 'null'}',
    );

    if (activeRequest == null ||
        activeRequest.status == RequestStatus.NO_PROVIDER_FOUND ||
        activeRequest.status == RequestStatus.CANCELLED ||
        activeRequest.providerId == null) {
      // No active request — show waiting placeholder
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              'Waiting for new requests...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Active request exists — show card
    return GestureDetector(
      onTap: _navigateToActiveJob,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _statusColor(activeRequest.status),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(
                      activeRequest.status,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _statusColor(activeRequest.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _statusLabel(activeRequest.status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _statusColor(activeRequest.status),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              activeRequest.description.isNotEmpty
                  ? activeRequest.description
                  : 'Service request',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Location
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    activeRequest.location.isNotEmpty
                        ? activeRequest.location
                        : 'Location not available',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Driver info
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  activeRequest.driverName.isNotEmpty &&
                          activeRequest.driverName != 'Unknown Driver'
                      ? activeRequest.driverName
                      : 'Driver',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (activeRequest.distanceKm != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.straighten,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${activeRequest.distanceKm!.toStringAsFixed(1)} km',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Tap to view
            Center(
              child: Text(
                'Tap to view details',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.PENDING:
        return Colors.orange;
      case RequestStatus.ACCEPTED:
        return Colors.blue;
      case RequestStatus.ARRIVED:
        return Colors.teal;
      case RequestStatus.QUOTED:
        return Colors.purple;
      case RequestStatus.IN_PROGRESS:
        return Colors.deepOrange;
      case RequestStatus.COMPLETED:
        return Colors.green;
      case RequestStatus.PAID:
        return Colors.green;
      case RequestStatus.CANCELLED:
        return Colors.red;
      case RequestStatus.NO_PROVIDER_FOUND:
        return Colors.grey;
    }
  }

  String _statusLabel(RequestStatus status) {
    switch (status) {
      case RequestStatus.PENDING:
        return 'Pending';
      case RequestStatus.ACCEPTED:
        return 'Accepted — Head to driver';
      case RequestStatus.ARRIVED:
        return 'Arrived — Inspect vehicle';
      case RequestStatus.QUOTED:
        return 'Quoted — Awaiting approval';
      case RequestStatus.IN_PROGRESS:
        return 'In Progress';
      case RequestStatus.COMPLETED:
        return 'Completed — Awaiting payment';
      case RequestStatus.PAID:
        return 'Paid';
      case RequestStatus.CANCELLED:
        return 'Cancelled';
      case RequestStatus.NO_PROVIDER_FOUND:
        return 'Missed Request';
    }
  }
}
