import 'package:flutter/material.dart';
import 'package:road_rescue/theme/app_colors.dart';
import 'package:road_rescue/theme/app_theme.dart';

class OauthButtons extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onPressed;

  const OauthButtons({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,

      child: OutlinedButton(
        onPressed: onPressed,

        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.background,

          side: BorderSide(color: AppColors.border, width: 1),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          elevation: 0,
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            SizedBox(width: 24, height: 24, child: icon),

            const SizedBox(width: 12),

            Text(label, style: AppTheme.lightTheme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
