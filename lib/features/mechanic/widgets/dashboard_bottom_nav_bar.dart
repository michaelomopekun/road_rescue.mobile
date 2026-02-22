import 'package:flutter/material.dart';
import 'package:road_rescue/theme/app_colors.dart';

class DashboardBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const DashboardBottomNavBar({
    super.key,
    this.currentIndex = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      ],
      currentIndex: currentIndex,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey[400],
      onTap: onTap,
    );
  }
}
