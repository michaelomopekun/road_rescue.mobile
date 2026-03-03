import 'package:flutter/material.dart';
import 'package:road_rescue/theme/app_colors.dart';

/// A beautiful bottom sheet that appears when a mechanic receives an
/// incoming job request via FCM notification.
///
/// Usage:
/// ```dart
/// IncomingJobBottomSheet.show(
///   context,
///   requestId: 'abc123',
///   driverName: 'John Doe',
///   issueDescription: 'Flat tire on highway',
///   location: '123 Main Street, Lagos',
///   distanceKm: 2.3,
/// );
/// ```
class IncomingJobBottomSheet extends StatefulWidget {
  final String requestId;
  final String driverName;
  final String issueDescription;
  final String location;
  final double distanceKm;
  final String? driverPhone;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const IncomingJobBottomSheet({
    super.key,
    required this.requestId,
    required this.driverName,
    required this.issueDescription,
    required this.location,
    required this.distanceKm,
    this.driverPhone,
    this.onAccept,
    this.onDecline,
  });

  /// Show the bottom sheet from anywhere using a BuildContext
  static Future<bool?> show(
    BuildContext context, {
    required String requestId,
    required String driverName,
    required String issueDescription,
    required String location,
    required double distanceKm,
    String? driverPhone,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => IncomingJobBottomSheet(
        requestId: requestId,
        driverName: driverName,
        issueDescription: issueDescription,
        location: location,
        distanceKm: distanceKm,
        driverPhone: driverPhone,
        onAccept: () => Navigator.of(context).pop(true),
        onDecline: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  State<IncomingJobBottomSheet> createState() => _IncomingJobBottomSheetState();
}

class _IncomingJobBottomSheetState extends State<IncomingJobBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 80),
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

            const SizedBox(height: 20),

            // Pulsing "New Request" badge
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      const Color(0xFFECFDF5),
                      const Color(0xFFD1FAE5),
                      _pulseController.value,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Color.lerp(
                        const Color(0xFF10B981),
                        const Color(0xFF059669),
                        _pulseController.value,
                      )!.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            const Color(0xFF10B981),
                            const Color(0xFF059669),
                            _pulseController.value,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'NEW REQUEST',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Driver info section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Driver avatar and name
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1E4C4E),
                          Color(0xFF2D6A6C),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E4C4E).withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(widget.driverName),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    widget.driverName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'needs your help',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Details cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    // Issue row
                    _buildDetailRow(
                      icon: Icons.build_outlined,
                      iconColor: const Color(0xFFF59E0B),
                      iconBgColor: const Color(0xFFFEF3C7),
                      label: 'ISSUE',
                      value: widget.issueDescription,
                    ),

                    Divider(
                      height: 1,
                      color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
                      indent: 20,
                      endIndent: 20,
                    ),

                    // Location row
                    _buildDetailRow(
                      icon: Icons.location_on_outlined,
                      iconColor: const Color(0xFF3B82F6),
                      iconBgColor: const Color(0xFFDBEAFE),
                      label: 'LOCATION',
                      value: widget.location,
                    ),

                    Divider(
                      height: 1,
                      color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
                      indent: 20,
                      endIndent: 20,
                    ),

                    // Distance row
                    _buildDetailRow(
                      icon: Icons.directions_car_outlined,
                      iconColor: const Color(0xFF10B981),
                      iconBgColor: const Color(0xFFECFDF5),
                      label: 'DISTANCE',
                      value: '${widget.distanceKm.toStringAsFixed(1)} km away',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Decline button
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _isProcessing ? null : () {
                          setState(() => _isProcessing = true);
                          widget.onDecline?.call();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Decline',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Accept button
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : () {
                          setState(() => _isProcessing = true);
                          widget.onAccept?.call();
                        },
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                        label: Text(
                          _isProcessing ? 'Processing...' : 'Accept Job',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E4C4E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
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
}
