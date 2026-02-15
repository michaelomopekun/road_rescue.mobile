import 'package:flutter/material.dart';
import 'package:road_rescue/theme/app_colors.dart';
import 'package:road_rescue/theme/app_theme.dart';

class OrDivider extends StatelessWidget {
  final String text;

  const OrDivider({super.key, this.text = 'or'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.divider, thickness: 1)),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),

          child: Text(text, style: AppTheme.lightTheme.textTheme.bodySmall),
        ),

        Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
      ],
    );
  }
}
