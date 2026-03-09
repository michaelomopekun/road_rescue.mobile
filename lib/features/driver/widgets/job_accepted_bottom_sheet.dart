import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:road_rescue/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:road_rescue/services/api_client.dart';
import 'package:road_rescue/services/toast_service.dart';

/// Bottom sheet shown to the driver when a mechanic accepts their request.
///
/// Displays mechanic info with action buttons:
/// - Start Navigating (opens Google Maps directions)
/// - Call Mechanic (opens phone dialer)
/// - Mark Service as Completed
///
/// Usage:
/// ```dart
/// JobAcceptedBottomSheet.show(
///   context,
///   requestId: 'abc123',
///   mechanicName: 'John Roadside Services',
///   mechanicPhone: '+2348012345678',
///   mechanicLatitude: 6.53,
///   mechanicLongitude: 3.385,
///   distanceKm: 0.8,
/// );
/// ```
class JobAcceptedBottomSheet extends StatefulWidget {
  final String requestId;
  final String mechanicName;
  final String mechanicPhone;
  final double mechanicLatitude;
  final double mechanicLongitude;
  final double distanceKm;
  final String? issueDescription;

  const JobAcceptedBottomSheet({
    super.key,
    required this.requestId,
    required this.mechanicName,
    required this.mechanicPhone,
    required this.mechanicLatitude,
    required this.mechanicLongitude,
    required this.distanceKm,
    this.issueDescription,
  });

  /// Show the bottom sheet from anywhere
  static Future<String?> show(
    BuildContext context, {
    required String requestId,
    required String mechanicName,
    required String mechanicPhone,
    required double mechanicLatitude,
    required double mechanicLongitude,
    required double distanceKm,
    String? issueDescription,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => JobAcceptedBottomSheet(
        requestId: requestId,
        mechanicName: mechanicName,
        mechanicPhone: mechanicPhone,
        mechanicLatitude: mechanicLatitude,
        mechanicLongitude: mechanicLongitude,
        distanceKm: distanceKm,
        issueDescription: issueDescription,
      ),
    );
  }

  @override
  State<JobAcceptedBottomSheet> createState() => _JobAcceptedBottomSheetState();
}

class _JobAcceptedBottomSheetState extends State<JobAcceptedBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  bool _isCompleting = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  Future<void> _startNavigation() async {
    final lat = widget.mechanicLatitude;
    final lng = widget.mechanicLongitude;

    // Try Google Maps first, fallback to Apple Maps on iOS
    final googleMapsUrl = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final appleMapsUrl = Uri.parse(
      'https://maps.apple.com/?daddr=$lat,$lng&dirflg=d',
    );
    final webMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl);
      } else if (Platform.isIOS && await canLaunchUrl(appleMapsUrl)) {
        await launchUrl(appleMapsUrl);
      } else {
        await launchUrl(webMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('[JobAccepted] Error launching navigation: $e');
      if (mounted) {
        ToastService.showError(context, 'Could not open maps application');
      }
    }
  }

  Future<void> _callMechanic() async {
    final phoneUrl = Uri.parse('tel:${widget.mechanicPhone}');
    try {
      if (await canLaunchUrl(phoneUrl)) {
        await launchUrl(phoneUrl);
      }
    } catch (e) {
      print('[JobAccepted] Error launching phone: $e');
      if (mounted) {
        ToastService.showError(context, 'Could not open phone dialer');
      }
    }
  }

  Future<void> _markAsCompleted() async {
    setState(() => _isCompleting = true);

    try {
      final response = await ApiClient.post(
        '/requests/complete',
        body: {'requestId': widget.requestId},
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _isCompleting = false;
            _isCompleted = true;
          });

          // Wait to show the success state, then close
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.of(context).pop('completed');
          }
        }
      } else {
        print('[JobAccepted] Failed to complete: ${response.statusCode}');
        if (mounted) {
          setState(() => _isCompleting = false);
          ToastService.showError(
            context,
            'Failed to mark as completed. Try again.',
          );
        }
      }
    } catch (e) {
      print('[JobAccepted] Error completing request: $e');
      if (mounted) {
        setState(() => _isCompleting = false);
        ToastService.showError(context, 'Network error. Try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 100),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 16),
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Success check animation
            ScaleTransition(
              scale: CurvedAnimation(
                parent: _checkController,
                curve: Curves.elasticOut,
              ),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Title
            const Text(
              'Help is on the way!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '${widget.mechanicName} accepted your request',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
              ),
            ),

            const SizedBox(height: 24),

            // Mechanic info card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    // Mechanic avatar
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E4C4E), Color(0xFF2D6A6C)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF1E4C4E,
                            ).withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(widget.mechanicName),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Name and distance
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.mechanicName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Color(0xFF10B981),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.distanceKm.toStringAsFixed(1)} km away',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Verified badge
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Action buttons
            if (!_isCompleted) ...[
              // Start Navigating button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _startNavigation,
                    icon: const Icon(
                      Icons.navigation_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    label: const Text(
                      'Start Navigating',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Call Mechanic button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _callMechanic,
                    icon: const Icon(
                      Icons.phone_outlined,
                      color: Color(0xFF1E4C4E),
                      size: 20,
                    ),
                    label: Text(
                      'Call ${_getFirstName(widget.mechanicName)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E4C4E),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFF1E4C4E),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Mark as Completed button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isCompleting ? null : _markAsCompleted,
                    icon: _isCompleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                    label: Text(
                      _isCompleting
                          ? 'Completing...'
                          : 'Mark Service as Completed',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      disabledBackgroundColor: const Color(
                        0xFF10B981,
                      ).withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Completed state
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Service Completed! 🎉',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Thank you for using Road Rescue',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  String _getFirstName(String name) {
    final parts = name.trim().split(' ');
    return parts.first;
  }
}
