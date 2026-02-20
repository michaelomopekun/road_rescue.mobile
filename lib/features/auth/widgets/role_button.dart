import 'package:flutter/material.dart';
import 'package:road_rescue/theme/app_colors.dart';

class RoleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final Color textColor;
  final VoidCallback onPressed;

  const RoleButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: selectedColor,
          border: Border.all(
            color: isSelected ? selectedColor : AppColors.border,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
