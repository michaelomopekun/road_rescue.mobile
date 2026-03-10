import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:road_rescue/models/service_request.dart';
import 'package:road_rescue/services/directions_service.dart';
import 'package:road_rescue/services/socket_service.dart';
import 'package:road_rescue/theme/app_colors.dart';

/// Two-phase tracking view for the driver watching the mechanic approach.
/// Phase 1: Route overview with "Track Mechanic" button.
/// Phase 2: Active tracking — real-time mechanic location via socket.
class DriverTrackingView extends StatefulWidget {
  final ServiceRequest request;
  final VoidCallback? onCancel;

  const DriverTrackingView({super.key, required this.request, this.onCancel});

  @override
  State<DriverTrackingView> createState() => _DriverTrackingViewState();
}

class _DriverTrackingViewState extends State<DriverTrackingView> {
  GoogleMapController? _mapController;
  final SocketService _socketService = SocketService();

  // Route data
  DirectionsResult? _directions;
  Set<Polyline> _polylines = {};
  bool _isLoadingRoute = true;

  // Phase tracking
  bool _isTracking = false; // false = overview, true = active tracking

  // Mechanic position (updates in real-time during phase 2)
  LatLng? _mechanicPosition;
  StreamSubscription<LatLng>? _mechanicLocationSub;

  // Driver position (static — the driver is waiting)
  late LatLng _driverPosition;

  // Markers
  Set<Marker> _markers = {};

  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _driverPosition = LatLng(widget.request.latitude, widget.request.longitude);

    // Use provider coordinates as initial mechanic position
    final provLat = widget.request.providerLatitude;
    final provLng = widget.request.providerLongitude;
    if (provLat != null && provLng != null) {
      _mechanicPosition = LatLng(provLat, provLng);
    }

    _updateMarkers();
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    final origin = _mechanicPosition;
    if (origin == null) {
      if (!_disposed) setState(() => _isLoadingRoute = false);
      return;
    }

    final result = await DirectionsService.getDirections(
      origin: origin,
      destination: _driverPosition,
    );

    if (_disposed) return;

    setState(() {
      _directions = result;
      _isLoadingRoute = false;

      if (result != null) {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: result.polylinePoints,
            color: Colors.blue,
            width: 5,
          ),
        };
      }

      _updateMarkers();
    });

    _fitCameraToRoute();
  }

  void _updateMarkers() {
    _markers = {
      Marker(
        markerId: const MarkerId('driver'),
        position: _driverPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'You'),
      ),
      if (_mechanicPosition != null)
        Marker(
          markerId: const MarkerId('mechanic'),
          position: _mechanicPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: widget.request.providerName ?? 'Mechanic',
          ),
        ),
    };
  }

  void _fitCameraToRoute() {
    if (_directions == null || _mapController == null) return;

    final points = _directions!.polylinePoints;
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80,
      ),
    );
  }

  /// Start phase 2: join tracking room and listen for mechanic location
  void _startTracking() {
    if (_disposed) return;
    setState(() => _isTracking = true);

    // Join the tracking room to receive mechanic location updates
    _socketService.joinRequest(widget.request.id);
    _socketService.requestCurrentLocation(widget.request.id);

    // Listen for real-time mechanic location
    _mechanicLocationSub = _socketService.onMechanicLocation.listen((location) {
      if (_disposed) {
        _mechanicLocationSub?.cancel();
        return;
      }

      setState(() {
        _mechanicPosition = location;
        _updateMarkers();
      });

      // Follow mechanic on map
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: 15),
        ),
      );
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _mechanicLocationSub?.cancel();
    _mechanicLocationSub = null;
    if (_isTracking) {
      _socketService.leaveRequest(widget.request.id);
    }
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialPos = _mechanicPosition ?? _driverPosition;

    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map
          GoogleMap(
            initialCameraPosition: CameraPosition(target: initialPos, zoom: 14),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              if (_directions != null) {
                Future.delayed(
                  const Duration(milliseconds: 500),
                  _fitCameraToRoute,
                );
              }
            },
          ),

          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _buildCircleButton(
                  icon: Icons.arrow_back,
                  onTap: () =>
                      Navigator.of(context).pushReplacementNamed('/driver'),
                ),
                const SizedBox(width: 12),
                if (_isTracking && _directions != null)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        '${_directions!.durationText} · ${_directions!.distanceText}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                const Spacer(),
                _buildCircleButton(
                  icon: Icons.my_location,
                  onTap: () {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLng(_driverPosition),
                    );
                  },
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_isLoadingRoute) const Center(child: CircularProgressIndicator()),

          // Bottom sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _isTracking ? _buildTrackingSheet() : _buildOverviewSheet(),
          ),
        ],
      ),
    );
  }

  /// Phase 1 — Route overview bottom sheet
  Widget _buildOverviewSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route info
                if (_directions != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_car,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_directions!.durationText} (${_directions!.distanceText})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                if (_directions != null) const SizedBox(height: 4),
                if (_directions != null)
                  Text(
                    'Mechanic is on the way',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                const SizedBox(height: 16),

                // Mechanic info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[200],
                      child: Text(
                        (widget.request.providerName ?? 'M')[0],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.request.providerName ?? 'Mechanic',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          if (widget.request.providerPhone != null)
                            Text(
                              widget.request.providerPhone!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (widget.request.providerPhone != null)
                      IconButton(
                        icon: const Icon(Icons.phone, color: Colors.green),
                        onPressed: () {
                          // TODO: launch phone call
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Track Mechanic button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _directions != null ? _startTracking : null,
                    icon: const Icon(
                      Icons.location_searching,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Track Mechanic',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),

                // Cancel button
                if (widget.onCancel != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton(
                      onPressed: widget.onCancel,
                      child: const Text(
                        'Cancel Request',
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Phase 2 — Active tracking bottom sheet
  Widget _buildTrackingSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Mechanic info row
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[200],
                  child: Text(
                    (widget.request.providerName ?? 'M')[0],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.request.providerName ?? 'Mechanic',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (_directions != null)
                        Text(
                          'ETA: ${_directions!.durationText} · ${_directions!.distanceText}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.request.providerPhone != null)
                  IconButton(
                    icon: const Icon(
                      Icons.phone,
                      color: Colors.green,
                      size: 22,
                    ),
                    onPressed: () {
                      // TODO: launch phone call
                    },
                  ),
              ],
            ),

            // Cancel button
            if (widget.onCancel != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Cancel Request',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}
