import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    required this.label,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? AppColors.primary : Colors.grey[400],
          foregroundColor: Colors.white,
          elevation: isEnabled ? 0 : 0,
          disabledBackgroundColor: Colors.grey[400],
          disabledForegroundColor: Colors.grey[600],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTheme.lightTheme.textTheme.labelLarge,
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isEnabled ? Colors.white : Colors.grey[600]!,
                  ),
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  color: isEnabled ? Colors.white : Colors.grey[600],
                ),
              ),
      ),
    );
  }
}
