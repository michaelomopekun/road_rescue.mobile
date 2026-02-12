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
          // Segmented progress bars
          Expanded(
            child: Row(
              children: List.generate(totalPages, (index) {
                final isCompleted = index < currentPage;
                final isCurrent = index == currentPage;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index < totalPages - 1 ? 8 : 0,
                    ),
                    child: TweenAnimationBuilder<Color?>(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      tween: ColorTween(
                        end: isCurrent
                            ? AppColors.primary
                            : isCompleted
                            ? AppColors.primary.withValues(alpha: 0.4)
                            : AppColors.dotInactive.withValues(alpha: 0.4),
                      ),
                      builder: (context, color, _) {
                        return Container(
                          height: 4,
                          width: 210,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(width: 90),

          // Skip button
          GestureDetector(
            onTap: onSkip,
            child: Text(
              'Skip',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ),

          const SizedBox(width: 16),
        ],
      ),
    );
  }
}
