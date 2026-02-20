import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;
  final double size;
  final double iconSize;

  const CustomBackButton({
    super.key,
    this.onPressed,
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
    this.size = 56,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? AppColors.border,
        border: Border.all(color: borderColor ?? AppColors.border, width: 1.5),
      ),
      child: IconButton(
        icon: Icon(
          Icons.arrow_back,
          size: iconSize,
          color: iconColor ?? AppColors.textPrimary,
        ),
        onPressed: onPressed ?? () => Navigator.pop(context),
      ),
    );
  }
}
