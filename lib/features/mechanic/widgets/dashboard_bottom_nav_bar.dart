import 'package:flutter/material.dart';
import 'package:road_rescue/theme/app_colors.dart';

enum DashboardNavVariant { lockedDashboard, fullDashboard, driverDashboard }

class DashboardBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChanged;
  final DashboardNavVariant variant;

  const DashboardBottomNavBar({
    super.key,
    this.selectedIndex = 0,
    required this.onTabChanged,
    this.variant = DashboardNavVariant.fullDashboard,
  });

  List<BottomNavigationBarItem> _getItems() {
    final allItems = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(
        icon: Icon(Icons.account_balance_wallet),
        label: 'Wallet',
      ),
      if (variant != DashboardNavVariant.driverDashboard)
        const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
      const BottomNavigationBarItem(
        icon: Icon(Icons.history),
        label: 'History',
      ),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];

    return allItems;
  }

  @override
  Widget build(BuildContext context) {
    // For locked dashboard
    if (variant == DashboardNavVariant.lockedDashboard) {
      return const SizedBox.shrink();
    }

    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onTabChanged,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      elevation: 2,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      iconSize: 24,
      items: _getItems(),
    );
  }
}
