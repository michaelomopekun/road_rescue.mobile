import 'package:flutter/material.dart';
import 'package:road_rescue/theme/app_colors.dart';
import 'package:road_rescue/services/token_service.dart';
import 'package:road_rescue/features/driver/widgets/quick_action_button.dart';
import 'package:road_rescue/features/driver/widgets/recent_activity_card.dart';
import 'package:road_rescue/features/mechanic/widgets/dashboard_bottom_nav_bar.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  String _driverName = '';
  int _selectedNavIndex = 0;

  
  @override
  void initState() {
    super.initState();
    _loadDriverInfo();
  }
  
  Future<void> _loadDriverInfo() async {
    final userData = await TokenService.getUserData();
    if (mounted) {
      setState(() {
        _driverName = userData?['name'] as String? ?? 'Driver';
        // Extract first name
        if (_driverName.contains(' ')) {
          _driverName = _driverName.split(' ').first;
        }
      });
    }
  }

  void _handleNavigation(int index) {
    setState(() {
      _selectedNavIndex = index;
    });

    switch (index) {
      case 0:
        // Already on Home
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/driver/wallet');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/driver/map');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/driver/history');
        break;
      case 4:
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
                          // TODO: Handle request mechanic
                        },
                        icon: const Icon(
                          Icons.build,
                          color: AppColors.primary,
                        ),
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
                    onTap: () {},
                  ),
                  QuickActionButton(
                    icon: Icons.tire_repair,
                    label: 'Flat Tire',
                    backgroundColor: const Color(0xFFE0E7FF),
                    iconColor: const Color(0xFF4F46E5),
                    onTap: () {},
                  ),
                  QuickActionButton(
                    icon: Icons.car_repair,
                    label: 'Engine',
                    backgroundColor: const Color(0xFFFFE4E6),
                    iconColor: const Color(0xFFE11D48),
                    onTap: () {},
                  ),
                  QuickActionButton(
                    icon: Icons.rv_hookup,
                    label: 'Tow',
                    backgroundColor: Colors.white,
                    iconColor: AppColors.primary,
                    onTap: () {},
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
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
                    onPressed: () {},
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
              Container(
                decoration: BoxDecoration(
                  color: Colors.transparent, // Removing the overall border since the cards have their own borders
                ),
                child: Column(
                  children: [
                    RecentActivityCard(
                      icon: Icons.tire_repair,
                      serviceName: 'Flat Tire',
                      date: 'Mon, 12 Oct • 2:30 PM',
                      amount: '\$45.00',
                      status: 'Completed',
                      iconBackgroundColor: const Color(0xFFE0E7FF),
                      iconColor: const Color(0xFF4F46E5),
                      statusBackgroundColor: const Color(0xFFE6F9F3),
                      statusTextColor: AppColors.success,
                    ),
                    RecentActivityCard(
                      icon: Icons.battery_charging_full,
                      serviceName: 'Battery Jump',
                      date: 'Sun, 05 Oct • 9:15 AM',
                      amount: '\$35.00',
                      status: 'Completed',
                      iconBackgroundColor: const Color(0xFFFFF0E6),
                      iconColor: const Color(0xFFF97316),
                      statusBackgroundColor: const Color(0xFFE6F9F3),
                      statusTextColor: AppColors.success,
                    ),
                    RecentActivityCard(
                      icon: Icons.directions_car,
                      serviceName: 'Tow Request',
                      date: 'Sat, 28 Sep • 11:45 PM',
                      amount: 'Cancelled',
                      status: 'Cancelled',
                      iconBackgroundColor: const Color(0xFFF1F5F9), // Light grey
                      iconColor: const Color(0xFF94A3B8), // slate-400
                      statusBackgroundColor: Colors.transparent,
                      statusTextColor: const Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DashboardBottomNavBar(
        selectedIndex: _selectedNavIndex,
        onTabChanged: _handleNavigation,
      ),
    );
  }
}

