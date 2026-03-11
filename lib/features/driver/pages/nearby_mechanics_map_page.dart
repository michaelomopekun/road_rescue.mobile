import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:road_rescue/theme/app_colors.dart';
import 'package:road_rescue/services/driver_service.dart';
import 'package:road_rescue/services/request_state_manager.dart';
import 'package:road_rescue/models/request_status.dart';
import 'package:road_rescue/features/driver/pages/active_request_page.dart';
import 'package:road_rescue/features/driver/pages/no_provider_view.dart';
import 'package:road_rescue/features/driver/pages/searching_mechanic_page.dart';
import 'package:road_rescue/services/toast_service.dart';

class NearbyMechanicsMapPage extends StatefulWidget {
  final String issueType;
  final String requestId;
  final double driverLatitude;
  final double driverLongitude;
  final List<NearbyProvider> nearbyProviders;

  const NearbyMechanicsMapPage({
    super.key,
    required this.issueType,
    required this.requestId,
    required this.driverLatitude,
    required this.driverLongitude,
    required this.nearbyProviders,
  });

  @override
  State<NearbyMechanicsMapPage> createState() => _NearbyMechanicsMapPageState();
}

class _NearbyMechanicsMapPageState extends State<NearbyMechanicsMapPage>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;

  // Countdown timer (2 minutes = 120 seconds)
  static const int _totalSeconds = 120;
  int _remainingSeconds = _totalSeconds;
  Timer? _countdownTimer;
  bool _isCancelling = false;

  // State manager for listening to socket updates
  late RequestStateManager _stateManager;

  // Color palette for provider avatars
  static const List<Color> _avatarColors = [
    Color(0xFFFCD34D), // Amber
    Color(0xFF93C5FD), // Blue
    Color(0xFF86EFAC), // Green
    Color(0xFFFCA5A5), // Red
    Color(0xFFC4B5FD), // Purple
    Color(0xFFFBCFE8), // Pink
  ];

  static const List<Color> _avatarIconColors = [
    Color(0xFF92400E), // Amber dark
    Color(0xFF1E3A5F), // Blue dark
    Color(0xFF14532D), // Green dark
    Color(0xFF7F1D1D), // Red dark
    Color(0xFF3B0764), // Purple dark
    Color(0xFF831843), // Pink dark
  ];

  LatLng get _center => LatLng(widget.driverLatitude, widget.driverLongitude);

  @override
  void initState() {
    super.initState();
    _stateManager = RequestStateManager();
    _stateManager.addListener(_onStateChanged);
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _stateManager.removeListener(_onStateChanged);
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _onTimerExpired();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  void _onStateChanged() {
    // If a mechanic accepted the request, navigate to ActiveRequestPage
    final status = _stateManager.status;
    if (status == RequestStatus.ACCEPTED) {
      _countdownTimer?.cancel();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ActiveRequestPage()),
        );
      }
    }
  }

  Future<void> _onTimerExpired() async {
    // Auto-cancel the request when countdown reaches zero
    await _cancelRequest(isTimeout: true);
  }

  Future<void> _cancelRequest({bool isTimeout = false}) async {
    if (_isCancelling) return;
    setState(() {
      _isCancelling = true;
    });
    _countdownTimer?.cancel();

    try {
      final success = await DriverService.cancelRequest(widget.requestId);
      if (mounted) {
        if (success) {
          _stateManager.clearActiveRequest();
          if (isTimeout) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => NoProviderView(
                  onRetry: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => SearchingMechanicPage(
                          issueType: widget.issueType,
                          // You can add more props like issueIcon if necessary, or just rely on default
                        ),
                      ),
                    );
                  },
                  onDashboard: () {
                    Navigator.of(context).pushReplacementNamed('/driver');
                  },
                ),
              ),
            );
          } else {
            ToastService.showWarning(
              context,
              'Request cancelled. Returning to dashboard.',
            );
            Navigator.of(context).pushReplacementNamed('/driver');
          }
        } else {
          ToastService.showError(context, 'Failed to cancel request.');
          setState(() {
            _isCancelling = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Error cancelling request.');
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get _timerProgress => _remainingSeconds / _totalSeconds;

  Set<Marker> _createMarkers() {
    Set<Marker> markers = {};

    // Add provider markers
    for (int i = 0; i < widget.nearbyProviders.length; i++) {
      final provider = widget.nearbyProviders[i];
      markers.add(
        Marker(
          markerId: MarkerId(provider.id),
          position: LatLng(provider.baseLatitude, provider.baseLongitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    // Add driver location marker
    markers.add(
      Marker(
        markerId: const MarkerId('driver_location'),
        position: _center,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 13.5),
            markers: _createMarkers(),
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          // 2. Back button
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => _showCancelConfirmation(),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),

          // 3. Bottom Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.58,
              decoration: const BoxDecoration(
                color: Color(0xFFF4F7FB),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 16, bottom: 16),
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E4C4E).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nearby Mechanics',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.nearbyProviders.length} mechanic${widget.nearbyProviders.length == 1 ? '' : 's'} notified',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Countdown timer pill
                  _buildCountdownPill(),

                  const SizedBox(height: 12),

                  // Info banner
                  _buildInfoBanner(),

                  const SizedBox(height: 12),

                  // Provider list
                  Expanded(
                    child: widget.nearbyProviders.isNotEmpty
                        ? ListView.builder(
                            padding: const EdgeInsets.only(bottom: 8),
                            itemCount: widget.nearbyProviders.length,
                            itemBuilder: (context, index) {
                              return _buildProviderTile(
                                index,
                                widget.nearbyProviders[index],
                              );
                            },
                          )
                        : Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: AppColors.primary.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No mechanics available in your area right now.\nPlease try again later.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.8,
                                    ),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),

                  // Cancel Request Button
                  Container(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      bottom: 32,
                      top: 12,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _isCancelling ? null : _cancelRequest,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isCancelling
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFEF4444),
                                ),
                              )
                            : const Text(
                                'Cancel Request',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownPill() {
    final isLow = _remainingSeconds <= 30;
    final pillColor = isLow ? const Color(0xFFFFE4E6) : const Color(0xFFECFDF5);
    final textColor = isLow ? const Color(0xFFE11D48) : const Color(0xFF1E4C4E);
    final progressColor = isLow
        ? const Color(0xFFE11D48)
        : const Color(0xFF1E4C4E);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: pillColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: progressColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            // Circular progress
            SizedBox(
              width: 28,
              height: 28,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _timerProgress,
                    strokeWidth: 3,
                    backgroundColor: progressColor.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                  Icon(
                    Icons.hourglass_top_rounded,
                    size: 14,
                    color: progressColor,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Waiting for response',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: progressColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formattedTime,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFF9800).withValues(alpha: 0.4),
          ),
        ),
        child: const Text(
          'We have sent your request to these nearby mechanics',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE65100),
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildProviderTile(int index, NearbyProvider provider) {
    final avatarColor = _avatarColors[index % _avatarColors.length];
    final iconColor = _avatarIconColors[index % _avatarIconColors.length];
    final isCompany = provider.providerType == 'COMPANY';

    return GestureDetector(
      onTap: () {
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(provider.baseLatitude, provider.baseLongitude),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: avatarColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  isCompany ? Icons.storefront : Icons.person,
                  size: 28,
                  color: iconColor,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.businessName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.providerType,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),

            // Distance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${provider.distanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'away',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cancel Request?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to cancel this request? Mechanics have already been notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Keep Waiting',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelRequest();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
