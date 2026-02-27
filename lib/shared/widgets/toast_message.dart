import 'package:flutter/material.dart';
import 'package:road_rescue/theme/app_colors.dart';

enum ToastType { success, warning, error }

class ToastMessage extends StatefulWidget {
  final String message;
  final ToastType type;
  final VoidCallback? onClose;
  final Duration duration;

  const ToastMessage({
    super.key,
    required this.message,
    required this.type,
    this.onClose,
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<ToastMessage> createState() => _ToastMessageState();
}

class _ToastMessageState extends State<ToastMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Auto-dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _slideAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0, -1),
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

        _fadeAnimation = Tween<double>(
          begin: 1,
          end: 0,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

        _controller.reverse().then((_) {
          if (mounted) {
            widget.onClose?.call();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case ToastType.success:
        return AppColors.success.withValues(alpha: 0.1);
      case ToastType.warning:
        return AppColors.warning.withValues(alpha: 0.1);
      case ToastType.error:
        return AppColors.error.withValues(alpha: 0.1);
    }
  }

  Color _getBorderColor() {
    switch (widget.type) {
      case ToastType.success:
        return AppColors.success;
      case ToastType.warning:
        return AppColors.warning;
      case ToastType.error:
        return AppColors.error;
    }
  }

  Color _getCircleColor() {
    switch (widget.type) {
      case ToastType.success:
        return AppColors.success;
      case ToastType.warning:
        return AppColors.warning;
      case ToastType.error:
        return AppColors.error;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case ToastType.success:
        return Icons.check;
      case ToastType.warning:
      case ToastType.error:
        return Icons.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getBorderColor(), width: 2),
          ),
          child: Row(
            children: [
              // Icon in circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getCircleColor().withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(_getIcon(), color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              // Message
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              // Close button
              GestureDetector(
                onTap: () {
                  _controller.reverse().then((_) {
                    if (mounted) {
                      widget.onClose?.call();
                    }
                  });
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
