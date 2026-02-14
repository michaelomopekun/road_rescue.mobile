import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class LoginLink extends StatelessWidget {
  final VoidCallback? onTap;

  const LoginLink({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
        ),

        // const SizedBox(width: 4),
        GestureDetector(
          onTap: onTap,
          child: const Text(
            'Log in',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
