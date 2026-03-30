import 'package:flutter/material.dart';
import 'package:road_rescue/theme/app_colors.dart';
import 'package:road_rescue/services/token_service.dart';
import 'package:road_rescue/services/driver_service.dart';
import 'package:road_rescue/features/driver/widgets/quick_action_button.dart';
import 'package:road_rescue/features/driver/widgets/recent_activity_card.dart';
import 'package:road_rescue/features/mechanic/widgets/dashboard_bottom_nav_bar.dart';
import 'package:road_rescue/features/driver/pages/searching_mechanic_page.dart';
import 'package:road_rescue/models/request_status.dart';
import 'package:road_rescue/services/request_state_manager.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  String _driverName = '';
  int _selectedNavIndex = 0;
  List<DriverHistoryRequest> _recentActivity = [];
  bool _isLoadingActivity = true;

  @override
  void initState() {
    super.initState();
    _loadDriverInfo();
    _loadRecentActivity();
    RequestStateManager().addListener(_onRequestStateChanged);
  }

  @override
  void dispose() {
    RequestStateManager().removeListener(_onRequestStateChanged);
    super.dispose();
  }

  void _onRequestStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadDriverInfo() async {
    final userData = await TokenService.getUserData();
    if (mounted) {
      setState(() {
        _driverName = userData?['name'] as String? ?? '';
        // Extract first name
        if (_driverName.contains(' ')) {
          _driverName = _driverName.split(' ').first;
        }
      });
    }
  }

  Future<void> _loadRecentActivity() async {
    try {
      final history = await DriverService.getRecentRequestHistory(limit: 3);
      if (mounted) {
        setState(() {
          _recentActivity = history;
          _isLoadingActivity = false;
        });
      }
    } catch (e) {
      print('[DriverDashboard] Error loading recent activity: $e');
      if (mounted) {
        setState(() {
          _isLoadingActivity = false;
        });
      }
    }
  }

  IconData _getServiceIcon(String serviceType) {
    switch (serviceType.toUpperCase()) {
      case 'FLAT_TIRE':
        return Icons.tire_repair;
      case 'BATTERY_JUMP':
        return Icons.battery_charging_full;
      case 'TOW':
        return Icons.directions_car;
      case 'ENGINE':
        return Icons.car_repair;
      case 'LOCKOUT':
        return Icons.vpn_key;
      case 'FUEL_DELIVERY':
        return Icons.local_gas_station_outlined;
      default:
        return Icons.handyman;
    }
  }

  Color _getServiceIconBgColor(String serviceType) {
    switch (serviceType.toUpperCase()) {
      case 'FLAT_TIRE':
        return const Color(0xFFE0E7FF);
      case 'BATTERY_JUMP':
        return const Color(0xFFFFF0E6);
      case 'TOW':
        return const Color(0xFFF1F5F9);
      case 'ENGINE':
        return const Color(0xFFFFE4E6);
      case 'LOCKOUT':
        return const Color(0xFFF3E8FF);
      case 'FUEL_DELIVERY':
        return const Color(0xFFE6F9F3);
      default:
        return const Color(0xFFDFEAF4);
    }
  }

  Color _getServiceIconColor(String serviceType) {
    switch (serviceType.toUpperCase()) {
      case 'FLAT_TIRE':
        return const Color(0xFF4F46E5);
      case 'BATTERY_JUMP':
        return const Color(0xFFF97316);
      case 'TOW':
        return const Color(0xFF94A3B8);
      case 'ENGINE':
        return const Color(0xFFE11D48);
      case 'LOCKOUT':
        return const Color(0xFF9333EA);
      case 'FUEL_DELIVERY':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF5A789A);
    }
  }

  String _formatDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    String weekday = weekdays[date.weekday - 1];
    String day = date.day.toString().padLeft(2, '0');
    String month = months[date.month - 1];
    int hour = date.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    String minute = date.minute.toString().padLeft(2, '0');
    return '$weekday, $day $month \u2022 $hour:$minute $period';
  }

  void _handleNavigation(int index) {
    setState(() {
      _selectedNavIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/driver/dashboard');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/driver/wallet');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/driver/history');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/driver/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi $_driverName 👋',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Everything looks good\ntoday.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.notifications_none,
                        color: AppColors.error,
                      ),
                      onPressed: () {
                        // TODO: Handle notifications
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Help Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Need Help Now?',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Mechanics are nearby & ready.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SearchingMechanicPage(
                                issueType: 'General Repair',
                                issueIcon: Icons.handyman,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.build, color: AppColors.primary),
                        label: const Text(
                          'Request Mechanic',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Quick Issue Types
              const Text(
                'Quick Issue Types',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  QuickActionButton(
                    icon: Icons.battery_charging_full,
                    label: 'Battery',
                    backgroundColor: const Color(0xFFFFF0E6),
                    iconColor: const Color(0xFFF97316),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SearchingMechanicPage(
                            issueType: 'Battery Issue',
                            issueIcon: Icons.battery_charging_full,
                          ),
                        ),
                      );
                    },
                  ),
                  QuickActionButton(
                    icon: Icons.tire_repair,
                    label: 'Flat Tire',
                    backgroundColor: const Color(0xFFE0E7FF),
                    iconColor: const Color(0xFF4F46E5),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SearchingMechanicPage(
                            issueType: 'Flat Tire',
                            issueIcon: Icons.tire_repair,
                          ),
                        ),
                      );
                    },
                  ),
                  QuickActionButton(
                    icon: Icons.car_repair,
                    label: 'Engine',
                    backgroundColor: const Color(0xFFFFE4E6),
                    iconColor: const Color(0xFFE11D48),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SearchingMechanicPage(
                            issueType: 'Engine Issue',
                            issueIcon: Icons.car_repair,
                          ),
                        ),
                      );
                    },
                  ),
                  QuickActionButton(
                    icon: Icons.rv_hookup,
                    label: 'Tow',
                    backgroundColor: Colors.white,
                    iconColor: AppColors.primary,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SearchingMechanicPage(
                            issueType: 'Tow Request',
                            issueIcon: Icons.rv_hookup,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              _buildActiveRequestSection(),

              // Recent Activity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushReplacementNamed('/driver/history');
                    },
                    child: const Text(
                      'View History',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildRecentActivitySection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DashboardBottomNavBar(
        selectedIndex: _selectedNavIndex,
        onTabChanged: _handleNavigation,
        variant: DashboardNavVariant.driverDashboard,
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    if (_isLoadingActivity) {
      return Column(
        children: List.generate(3, (index) => _buildActivityShimmer()),
      );
    }

    if (_recentActivity.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.history, size: 40, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'No recent activity yet',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _recentActivity.map((request) {
        final isCancelled = request.status.toUpperCase() == 'CANCELLED';
        return RecentActivityCard(
          icon: _getServiceIcon(request.serviceType),
          serviceName: request.serviceTypeLabel,
          date: _formatDate(request.completedAt ?? request.createdAt),
          amount: isCancelled
              ? 'Cancelled'
              : '₦${request.amount?.toStringAsFixed(2) ?? '0.00'}',
          status: isCancelled ? 'Cancelled' : 'Completed',
          iconBackgroundColor: isCancelled
              ? const Color(0xFFF1F5F9)
              : _getServiceIconBgColor(request.serviceType),
          iconColor: isCancelled
              ? const Color(0xFF94A3B8)
              : _getServiceIconColor(request.serviceType),
          statusBackgroundColor: isCancelled
              ? Colors.transparent
              : const Color(0xFFE6F9F3),
          statusTextColor: isCancelled
              ? const Color(0xFF94A3B8)
              : AppColors.success,
        );
      }).toList(),
    );
  }

  Widget _buildActiveRequestSection() {
    final activeRequest = RequestStateManager().activeRequest;

    if (activeRequest == null ||
        activeRequest.status == RequestStatus.NO_PROVIDER_FOUND ||
        activeRequest.status == RequestStatus.CANCELLED ||
        activeRequest.status == RequestStatus.PAID) {
      return const SizedBox.shrink();
    }

    // Determine the text to display for provider
    String providerDisplay = 'Searching...';
    if (activeRequest.providerName != null &&
        activeRequest.providerName!.isNotEmpty &&
        activeRequest.providerName != 'Unknown Driver') {
      providerDisplay = activeRequest.providerName!;
    } else if (activeRequest.status == RequestStatus.ACCEPTED ||
        activeRequest.status == RequestStatus.ARRIVED ||
        activeRequest.status == RequestStatus.IN_PROGRESS ||
        activeRequest.status == RequestStatus.COMPLETED) {
      providerDisplay = 'Mechanic';
    }

    final statusColor = _statusColor(activeRequest.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Request',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed('/driver/active-request');
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _statusLabel(activeRequest.status),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        activeRequest.location.isNotEmpty
                            ? activeRequest.location
                            : 'Current Location',
                        style: const TextStyle(
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
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      providerDisplay,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (activeRequest.distanceKm != null) ...[
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.straighten,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${activeRequest.distanceKm!.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                const Center(
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
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Color _statusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.PENDING:
        return Colors.orange;
      case RequestStatus.ACCEPTED:
        return AppColors.primary;
      case RequestStatus.ARRIVED:
        return Colors.teal;
      case RequestStatus.QUOTED:
        return Colors.purple;
      case RequestStatus.IN_PROGRESS:
        return Colors.deepOrange;
      case RequestStatus.COMPLETED:
        return Colors.green;
      default:
        return AppColors.primary;
    }
  }

  String _statusLabel(RequestStatus status) {
    switch (status) {
      case RequestStatus.PENDING:
        return 'Searching Mechanics';
      case RequestStatus.ACCEPTED:
        return 'Mechanic on the way';
      case RequestStatus.ARRIVED:
        return 'Mechanic Arrived';
      case RequestStatus.QUOTED:
        return 'Quoted — Action required';
      case RequestStatus.IN_PROGRESS:
        return 'In Progress';
      case RequestStatus.COMPLETED:
        return 'Completed — Make payment';
      default:
        return 'Active';
    }
  }

  Widget _buildActivityShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                height: 14,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 20,
                width: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
