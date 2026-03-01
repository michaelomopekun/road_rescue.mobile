import 'package:flutter/material.dart';
import 'package:road_rescue/theme/app_colors.dart';

enum DashboardNavVariant { lockedDashboard, fullDashboard }

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
    final allItems = [
      BottomNavigationBarItem(icon: const Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(
        icon: const Icon(Icons.account_balance_wallet),
        label: 'Wallet',
      ),
      BottomNavigationBarItem(icon: const Icon(Icons.map), label: 'Map'),
      BottomNavigationBarItem(
        icon: const Icon(Icons.history),
        label: 'History',
      ),
      BottomNavigationBarItem(icon: const Icon(Icons.person), label: 'Profile'),
    ];

    // For full dashboard, show all tabs
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
