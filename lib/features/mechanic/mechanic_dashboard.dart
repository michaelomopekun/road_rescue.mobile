import 'package:flutter/material.dart';
import 'package:road_rescue/services/token_service.dart';
import 'package:road_rescue/services/mechanic_service.dart';
import 'package:road_rescue/services/toast_service.dart';
import 'package:road_rescue/shared/widgets/stats_card.dart';
import 'package:road_rescue/shared/widgets/request_list_item.dart';
import 'package:road_rescue/features/mechanic/widgets/dashboard_bottom_nav_bar.dart';
import 'package:road_rescue/theme/app_colors.dart';

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
  String? _mechanicId;
  String? _mechanicName;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final userId = await TokenService.getUserId();
      final userData = await TokenService.getUserData();
      final providerId = await TokenService.getProviderId() ?? userId;

      if (providerId != null) {
        setState(() {
          _mechanicId = providerId;
          _mechanicName = userData?['name'] as String? ?? 'Mechanic';
        });

        // Fetch dashboard data - using mock data for now
        _loadMockData();

        // TODO: Uncomment when backend is ready
        /*
        try {
          final dashboardData =
              await MechanicService.getDashboardData(providerId);
          setState(() {
            _isAvailable = dashboardData.isAvailable;
            _currentEarnings = dashboardData.currentMonthEarnings;
            _currentJobCount = dashboardData.currentMonthJobCount;
            _recentJobs = dashboardData.recentJobs;
          });
        } catch (e) {
          print('Error loading dashboard data: $e');
          _loadMockData();
        }
        */
      }
    } catch (e) {
      print('Error loading mechanic ID: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
    try {
      setState(() {
        _isAvailable = value;
      });

      if (_mechanicId != null) {
        // TODO: Uncomment when backend is ready
        // await MechanicService.updateAvailabilityStatus(_mechanicId!, value);
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _isAvailable = !value;
      });
      if (mounted) {
        ToastService.showError(context, 'Failed to update availability');
      }
    }
  }

  Future<void> _refreshDashboard() async {
    await _loadDashboardData();
  }

  void _handleNavigation(int index) {
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
                      'Good day, $_mechanicName 👋',
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

              // New Requests Section
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  'New Requests',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
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
                    Icon(Icons.mail_outline, size: 48, color: AppColors.border),
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
              ),

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
                      value: '\$${_currentEarnings.toStringAsFixed(0)}',
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
                              amount: '\$${job.amount.toStringAsFixed(2)}',
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
}
