import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:road_rescue/theme/app_colors.dart';
import 'package:road_rescue/services/driver_service.dart';

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

class _NearbyMechanicsMapPageState extends State<NearbyMechanicsMapPage> {
  GoogleMapController? _mapController;
  int _selectedMechanicIndex = 0;

  LatLng get _center => LatLng(widget.driverLatitude, widget.driverLongitude);

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

  Set<Marker> _createMarkers() {
    Set<Marker> markers = {};

    // Add provider markers
    for (int i = 0; i < widget.nearbyProviders.length; i++) {
      final provider = widget.nearbyProviders[i];
      final isSelected = _selectedMechanicIndex == i;
      markers.add(
        Marker(
          markerId: MarkerId(provider.id),
          position: LatLng(provider.baseLatitude, provider.baseLongitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isSelected ? BitmapDescriptor.hueCyan : BitmapDescriptor.hueAzure,
          ),
          zIndex: isSelected ? 2.0 : 1.0,
          onTap: () {
            setState(() {
              _selectedMechanicIndex = i;
            });
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(provider.baseLatitude, provider.baseLongitude),
              ),
            );
          },
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
    final hasProviders = widget.nearbyProviders.isNotEmpty;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 13.5,
            ),
            markers: _createMarkers(),
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          // 2. Top Buttons
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
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
                child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              ),
            ),
          ),

          Positioned(
            top: 50,
            right: 20,
            child: GestureDetector(
              onTap: () {
                // Filter action
              },
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
                child: const Icon(Icons.tune, color: AppColors.textPrimary),
              ),
            ),
          ),

          // 3. Bottom Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.55,
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
                            hasProviders
                                ? '${widget.nearbyProviders.length} available nearby'
                                : 'No mechanics found nearby',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // List
                  Expanded(
                    child: hasProviders
                        ? ListView.builder(
                            padding: const EdgeInsets.only(bottom: 20),
                            itemCount: widget.nearbyProviders.length,
                            itemBuilder: (context, index) {
                              return _buildProviderTile(index, widget.nearbyProviders[index]);
                            },
                          )
                        : Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No mechanics available in your area right now.\nPlease try again later.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),

                  // Request Button
                  if (hasProviders)
                    Container(
                      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32, top: 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4F7FB),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final selectedProvider = widget.nearbyProviders[_selectedMechanicIndex];
                            _showRequestingDialog(selectedProvider);
                          },
                          icon: const Icon(Icons.build_outlined, color: Colors.white, size: 20),
                          label: Text(
                            'Request ${widget.nearbyProviders[_selectedMechanicIndex].businessName}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
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
          ),
        ],
      ),
    );
  }

  void _showRequestingDialog(NearbyProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _RequestingAssistanceDialog(
          provider: provider,
          requestId: widget.requestId,
        );
      },
    );
  }

  Widget _buildProviderTile(int index, NearbyProvider provider) {
    final isSelected = _selectedMechanicIndex == index;
    final avatarColor = _avatarColors[index % _avatarColors.length];
    final iconColor = _avatarIconColors[index % _avatarIconColors.length];
    final isCompany = provider.providerType == 'COMPANY';

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMechanicIndex = index;
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(provider.baseLatitude, provider.baseLongitude),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          border: isSelected
              ? const Border(left: BorderSide(color: Color(0xFF1E4C4E), width: 4))
              : const Border(left: BorderSide(color: Colors.transparent, width: 4)),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            // Avatar Container
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      isCompany ? Icons.storefront : Icons.person,
                      size: 32,
                      color: iconColor,
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Middle info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.businessName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.providerType,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),

            // Right info (Distance)
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
}

/// Dialog that handles assigning a provider to a request via API
/// Shows: Sending → Waiting for Approval → Error states
class _RequestingAssistanceDialog extends StatefulWidget {
  final NearbyProvider provider;
  final String requestId;

  const _RequestingAssistanceDialog({
    required this.provider,
    required this.requestId,
  });

  @override
  State<_RequestingAssistanceDialog> createState() => _RequestingAssistanceDialogState();
}

class _RequestingAssistanceDialogState extends State<_RequestingAssistanceDialog> {
  // States: 'sending', 'waiting', 'error'
  String _state = 'sending';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _assignProvider();
  }

  Future<void> _assignProvider() async {
    try {
      await DriverService.selectProvider(
        requestId: widget.requestId,
        providerId: widget.provider.id,
      );

      if (mounted) {
        setState(() {
          _state = 'waiting';
        });
      }
    } catch (e) {
      print('[RequestDialog] Error assigning provider: $e');
      if (mounted) {
        setState(() {
          _state = 'error';
          _errorMessage = e.toString().replaceAll('ApiException: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case 'sending':
        return _buildSendingState();
      case 'waiting':
        return _buildWaitingState();
      case 'error':
        return _buildErrorState();
      default:
        return _buildSendingState();
    }
  }

  Widget _buildSendingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            const SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E4C4E)),
                strokeWidth: 4,
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFF0FDFA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Color(0xFF1E4C4E),
                size: 28,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Sending Request...',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Contacting ${widget.provider.businessName}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            const SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF64748B)),
                strokeWidth: 4,
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFF0FDFA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                color: Color(0xFF1E4C4E),
                size: 28,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Waiting for Approval',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${widget.provider.businessName} has been notified.\nPlease wait for them to accept your request.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, size: 14, color: Color(0xFF10B981)),
              const SizedBox(width: 4),
              Text(
                '${widget.provider.distanceKm.toStringAsFixed(1)} km away',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'Cancel Request',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFFFFE4E6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline,
            color: Color(0xFFE11D48),
            size: 36,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Request Failed',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _errorMessage ?? 'Something went wrong. Please try again.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _state = 'sending';
                    _errorMessage = null;
                  });
                  _assignProvider();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E4C4E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
