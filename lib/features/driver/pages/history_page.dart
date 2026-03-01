import 'package:flutter/material.dart';
import 'package:road_rescue/features/mechanic/widgets/dashboard_bottom_nav_bar.dart';
import 'package:road_rescue/theme/app_colors.dart';

class DriverHistoryPage extends StatefulWidget {
  const DriverHistoryPage({super.key});

  @override
  State<DriverHistoryPage> createState() => _DriverHistoryPageState();
}

class _DriverHistoryPageState extends State<DriverHistoryPage> {
  int _selectedNavIndex = 3;
  String _selectedStatus = 'All';

  void _handleNavigation(int index) {
    if (index == _selectedNavIndex) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/driver'); // Or dashboard route
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/driver/wallet');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/driver/map');
        break;
      case 3:
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Activity History',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your past roadside assistance requests.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            
            // Status filter tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  _buildStatusTab('All'),
                  const SizedBox(width: 12),
                  _buildStatusTab('Completed'),
                  const SizedBox(width: 12),
                  _buildStatusTab('Cancelled'),
                ],
              ),
            ),
            
            // Jobs list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                children: [
                  _buildHistoryCard(
                    icon: Icons.tire_repair,
                    title: 'Flat Tire',
                    mechanic: 'David M.',
                    date: 'Mon, 12 Oct • 2:30 PM',
                    amount: '\$45.00',
                    status: 'Completed',
                    iconBgColor: const Color(0xFFE0E7FF),
                    iconColor: const Color(0xFF4F46E5),
                  ),
                  _buildHistoryCard(
                    icon: Icons.battery_charging_full,
                    title: 'Battery Jump',
                    mechanic: 'Sarah J.',
                    date: 'Sun, 05 Oct • 9:15 AM',
                    amount: '\$35.00',
                    status: 'Completed',
                    iconBgColor: const Color(0xFFFFF0E6),
                    iconColor: const Color(0xFFF97316),
                  ),
                  _buildHistoryCard(
                    icon: Icons.directions_car,
                    title: 'Tow Request',
                    mechanic: 'Unassigned',
                    date: 'Sat, 28 Sep • 11:45 PM',
                    amount: '—',
                    status: 'Cancelled',
                    iconBgColor: const Color(0xFFF1F5F9),
                    iconColor: const Color(0xFF94A3B8),
                  ),
                  _buildHistoryCard(
                    icon: Icons.car_repair,
                    title: 'Engine Check',
                    mechanic: 'Mike T.',
                    date: 'Wed, 15 Sep • 4:20 PM',
                    amount: '\$85.00',
                    status: 'Completed',
                    iconBgColor: const Color(0xFFFFE4E6),
                    iconColor: const Color(0xFFE11D48),
                  ),
                  _buildHistoryCard(
                    icon: Icons.vpn_key,
                    title: 'Lockout Service',
                    mechanic: 'Alex R.',
                    date: 'Fri, 02 Sep • 8:10 AM',
                    amount: '\$60.00',
                    status: 'Completed',
                    iconBgColor: const Color(0xFFF3E8FF),
                    iconColor: const Color(0xFF9333EA),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DashboardBottomNavBar(
        selectedIndex: _selectedNavIndex,
        onTabChanged: _handleNavigation,
      ),
    );
  }

  Widget _buildStatusTab(String label) {
    final isSelected = _selectedStatus == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard({
    required IconData icon,
    required String title,
    required String mechanic,
    required String date,
    required String amount,
    required String status,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    final isCancelled = status.toLowerCase() == 'cancelled';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Mechanic: $mechanic',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCancelled ? Colors.transparent : const Color(0xFFE6F9F3),
                  borderRadius: BorderRadius.circular(12),
                  border: isCancelled ? Border.all(color: AppColors.border) : null,
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isCancelled ? const Color(0xFF94A3B8) : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCancelled ? const Color(0xFF94A3B8) : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
