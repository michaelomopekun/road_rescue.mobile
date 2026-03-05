import 'package:flutter/material.dart';
import 'package:road_rescue/theme/app_colors.dart';
import 'package:road_rescue/services/driver_service.dart';
import 'package:road_rescue/services/location_service.dart';
import 'package:road_rescue/services/token_service.dart';
import 'dart:math' as math;
import 'package:geocoding/geocoding.dart';
import 'package:road_rescue/services/request_state_manager.dart';
import 'package:road_rescue/models/service_request.dart';
import 'package:road_rescue/models/request_status.dart';
import 'package:road_rescue/features/driver/pages/active_request_page.dart';

class SearchingMechanicPage extends StatefulWidget {
  final String issueType;
  final IconData issueIcon;

  const SearchingMechanicPage({
    super.key,
    this.issueType = 'Battery Issue',
    this.issueIcon = Icons.bolt,
  });

  @override
  State<SearchingMechanicPage> createState() => _SearchingMechanicPageState();
}

class _SearchingMechanicPageState extends State<SearchingMechanicPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isSearching = true;
  bool _noProviderFound = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Start the actual API request
    _createServiceRequest();
  }

  Future<void> _createServiceRequest() async {
    try {
      // 0. Pre-check for duplicate active requests
      final rm = RequestStateManager();
      if (rm.hasActiveRequest &&
          rm.status.name != 'PAID' &&
          rm.status.name != 'CANCELLED' &&
          rm.status.name != 'NO_PROVIDER_FOUND') {
        print(
          '[SearchingMechanicPage] Active request found. Short-circuiting and redirecting.',
        );
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ActiveRequestPage()),
          );
        }
        return;
      }

      // 1. Get the driver's current location
      final hasPermission = await LocationService.requestLocationPermission();
      if (!hasPermission) {
        if (mounted) {
          setState(() {
            _isSearching = false;
            _errorMessage =
                'Location permission is required to find nearby mechanics.';
          });
        }
        return;
      }

      final locationData = await LocationService.getCurrentLocation();
      if (locationData == null) {
        if (mounted) {
          setState(() {
            _isSearching = false;
            _errorMessage =
                'Unable to get your current location. Please enable GPS and try again.';
          });
        }
        return;
      }

      // 2. Reverse-geocode the coordinates to get an address string
      String locationAddress = 'Current Location';
      try {
        final placemarks = await placemarkFromCoordinates(
          locationData.latitude,
          locationData.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final parts = [
            place.street,
            place.locality,
            place.administrativeArea,
            place.country,
          ].where((p) => p != null && p.isNotEmpty);
          locationAddress = parts.join(', ');
        }
      } catch (e) {
        print('[SearchingMechanicPage] Reverse geocoding failed: $e');
        // Continue with fallback address
      }

      // 3. (Not needed, handled via token)
      // 4. Build a proper description from the issue type
      final description = _buildDescription(widget.issueType);

      // 5. Call the API
      final response = await DriverService.createServiceRequest(
        description: description,
        location: locationAddress,
        latitude: locationData.latitude,
        longitude: locationData.longitude,
      );

      // 6. Request was created. Set it directly on the state manager from the response.
      final stateManager = RequestStateManager();
      stateManager.setActiveRequest(
        ServiceRequest(
          id: response.id,
          status: RequestStatus.fromString(response.status),
          description: response.description,
          location: response.location,
          latitude: response.latitude,
          longitude: response.longitude,
          driverId: response.driverId,
          driverName: '',
          createdAt: response.createdAt,
        ),
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ActiveRequestPage()),
        );
      }
    } catch (e) {
      print('[SearchingMechanicPage] Error creating request: $e');
      if (mounted) {
        final isNoProvider =
            e.toString().contains('No nearby providers') ||
            e.toString().contains('Failed to create service');
        setState(() {
          _isSearching = false;
          _noProviderFound = isNoProvider;
          _errorMessage = _parseError(e);
        });
      }
    }
  }

  String _buildDescription(String issueType) {
    switch (issueType.toLowerCase()) {
      case 'battery issue':
        return 'Vehicle battery issue - needs jump start or battery replacement';
      case 'flat tire':
        return 'Flat tire - needs tire repair or replacement on the road';
      case 'engine issue':
        return 'Engine problem - vehicle not starting or engine overheating';
      case 'tow request':
        return 'Vehicle needs towing - cannot be driven to a repair shop';
      case 'general repair':
        return 'General vehicle breakdown - needs roadside mechanical assistance';
      default:
        return '$issueType - needs roadside assistance';
    }
  }

  String _parseError(dynamic error) {
    if (error.toString().contains('Only DRIVER')) {
      return 'Only driver accounts can create service requests.';
    }
    if (error.toString().contains('Unauthorized')) {
      return 'Session expired. Please log in again.';
    }
    if (error.toString().contains('Network error')) {
      return 'Network error. Please check your connection and try again.';
    }
    if (error.toString().contains('No nearby providers') ||
        error.toString().contains('no nearby providers')) {
      return 'No mechanics are available in your area right now. Please try again shortly.';
    }
    return 'You have an active help request.';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            Text(
              _isSearching
                  ? 'SEARCHING FOR HELP...'
                  : _noProviderFound
                  ? 'NO MECHANIC FOUND'
                  : 'REQUEST FAILED',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                letterSpacing: 1.5,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            Expanded(
              child: Center(
                child: _isSearching
                    ? AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: RipplePainter(
                              animationValue: _controller.value,
                              color: const Color(0xFF2DD4BF),
                            ),
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E4C4E),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF1E4C4E,
                                    ).withValues(alpha: 0.2),
                                    blurRadius: 16,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.build_outlined,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          );
                        },
                      )
                    : _noProviderFound
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.search_off_rounded,
                              color: Color(0xFF94A3B8),
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No Mechanic Found',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              _errorMessage ??
                                  'No mechanics are available in your area right now.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          // ElevatedButton.icon(
                          //   onPressed: () {
                          //     setState(() {
                          //       _isSearching = true;
                          //       _noProviderFound = false;
                          //       _errorMessage = null;
                          //     });
                          //     _createServiceRequest();
                          //   },
                          //   icon: const Icon(Icons.refresh, size: 20),
                          //   label: const Text('Retry Search'),
                          //   style: ElevatedButton.styleFrom(
                          //     backgroundColor: const Color(0xFF1E4C4E),
                          //     foregroundColor: Colors.white,
                          //     padding: const EdgeInsets.symmetric(
                          //       horizontal: 28,
                          //       vertical: 14,
                          //     ),
                          //     shape: RoundedRectangleBorder(
                          //       borderRadius: BorderRadius.circular(14),
                          //     ),
                          //     elevation: 0,
                          //   ),
                          // ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE4E6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.error_outline,
                              color: Color(0xFFE11D48),
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              _errorMessage ?? 'Something went wrong',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _isSearching = true;
                                _errorMessage = null;
                              });
                              _createServiceRequest();
                            },
                            icon: const Icon(
                              Icons.refresh,
                              color: Color(0xFF1E4C4E),
                            ),
                            label: const Text(
                              'Try Again',
                              style: TextStyle(
                                color: Color(0xFF1E4C4E),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _isSearching
                    ? 'Connecting you\nwith a Mechanic'
                    : _noProviderFound
                    ? 'No Mechanics\nNearby'
                    : 'Unable to Connect',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 48),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.issueIcon,
                        color: const Color(0xFF475569),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.issueType,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isSearching
                                ? 'Searching within 5km'
                                : _noProviderFound
                                ? 'No mechanics in range'
                                : 'Search stopped',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isSearching)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E4C4E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _isSearching ? 'Cancel Request' : 'Go Back',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class RipplePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  RipplePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final maxRadius = 1000.0;

    for (int i = 0; i < 3; i++) {
      double offsetValue = (animationValue + (i / 3.0)) % 1.0;
      double radius = 40.0 * math.pow(maxRadius / 40.0, offsetValue);
      double opacity = 1.0 - offsetValue;
      paint.color = color.withValues(alpha: opacity * 0.8);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant RipplePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
