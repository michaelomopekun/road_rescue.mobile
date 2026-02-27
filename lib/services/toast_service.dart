import 'package:flutter/material.dart';
import 'package:road_rescue/shared/widgets/toast_message.dart';

class ToastService {
  static OverlayEntry? _currentToastEntry;

  /// Show a success toast message
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    _showToast(
      context,
      message: message,
      type: ToastType.success,
      duration: duration,
    );
  }

  /// Show a warning toast message
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    _showToast(
      context,
      message: message,
      type: ToastType.warning,
      duration: duration,
    );
  }

  /// Show an error toast message
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    _showToast(
      context,
      message: message,
      type: ToastType.error,
      duration: duration,
    );
  }

  /// Internal method to show toast
  static void _showToast(
    BuildContext context, {
    required String message,
    required ToastType type,
    required Duration duration,
  }) {
    // Remove existing toast if any
    _currentToastEntry?.remove();

    _currentToastEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 0,
        right: 0,
        child: ToastMessage(
          message: message,
          type: type,
          duration: duration,
          onClose: () {
            _currentToastEntry?.remove();
            _currentToastEntry = null;
          },
        ),
      ),
    );

    Overlay.of(context).insert(_currentToastEntry!);
  }

  /// Dismiss current toast if any
  static void dismiss() {
    _currentToastEntry?.remove();
    _currentToastEntry = null;
  }
}
