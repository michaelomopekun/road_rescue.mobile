import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

class OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const OnboardingPage({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          const Spacer(flex: 2),

          // Icon container
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(icon, size: 80, color: AppColors.primary),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTheme.lightTheme.textTheme.headlineMedium,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
