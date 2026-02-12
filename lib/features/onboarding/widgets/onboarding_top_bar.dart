import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class OnboardingTopBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onSkip;

  const OnboardingTopBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),

      child: Row(
        children: [
          // Progress line
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (currentPage + 1) / totalPages,
                backgroundColor: AppColors.dotInactive.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Skip button
          GestureDetector(
            onTap: onSkip,
            child: Text(
              'Skip',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
