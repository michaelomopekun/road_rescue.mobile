import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class TermsAndPrivacyText extends StatelessWidget {
  final VoidCallback? onTermsTap;
  final VoidCallback? onPrivacyTap;

  const TermsAndPrivacyText({super.key, this.onTermsTap, this.onPrivacyTap});

  @override
  Widget build(BuildContext context) {
    final defaultStyle = TextStyle(
      fontSize: 12,
      color: AppColors.textSecondary.withValues(alpha: 0.7),
    );

    const linkStyle = TextStyle(
      fontSize: 13,
      color: AppColors.textPrimary,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w300,
    );

    return RichText(
      textAlign: TextAlign.center,

      text: TextSpan(
        style: defaultStyle,
        children: [
          const TextSpan(text: 'By continuing, you agree to our '),
          TextSpan(
            text: 'Terms of\nService',
            style: linkStyle,
            recognizer: TapGestureRecognizer()..onTap = onTermsTap,
          ),

          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: linkStyle,
            recognizer: TapGestureRecognizer()..onTap = onPrivacyTap,
          ),

          const TextSpan(text: '.'),
        ],
      ),
    );
  }
}
