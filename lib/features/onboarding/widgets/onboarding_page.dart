import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

class OnboardingPage extends StatelessWidget {
  final String svgPath;
  final int width;
  final int height;
  final String title;
  final String description;
  final bool isPayment;
  final bool isHelp;

  const OnboardingPage({
    super.key,
    required this.svgPath,
    required this.height,
    required this.width,
    required this.title,
    required this.description,
    required this.isPayment,
    required this.isHelp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          const Spacer(flex: 2),

          if (isPayment) const SizedBox(height: 64),

          // SVG illustration
          SvgPicture.asset(
            svgPath,
            colorFilter: const ColorFilter.mode(
              AppColors.onboardingIcon,
              BlendMode.srcIn,
            ),
          ),

          if (isPayment)
            const SizedBox(height: 68)
          else if (isHelp)
            const SizedBox(height: 70)
          else
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
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith( fontWeight: FontWeight.w400),
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
