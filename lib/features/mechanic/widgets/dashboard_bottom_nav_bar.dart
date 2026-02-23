import 'package:flutter/material.dart';
import 'package:road_rescue/theme/app_colors.dart';

class DashboardBottomNavBar extends StatelessWidget {
  final VoidCallback onHomeTap;

  const DashboardBottomNavBar({super.key, required this.onHomeTap});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: SizedBox(
        height: 60,
        child: Center(
          child: GestureDetector(
            onTap: onHomeTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home, color: AppColors.primary),
                const SizedBox(height: 4),
                Text(
                  'Home',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
