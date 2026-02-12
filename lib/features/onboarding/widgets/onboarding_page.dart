import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

class OnboardingPage extends StatelessWidget {
  final String svgPath;
  final String title;
  final String description;

  const OnboardingPage({
    super.key,
    required this.svgPath,
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

          // SVG illustration
          SvgPicture.asset(
            svgPath,
            width: 160,
            height: 160,
            colorFilter: const ColorFilter.mode(
              AppColors.primary,
              BlendMode.srcIn,
            ),
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
