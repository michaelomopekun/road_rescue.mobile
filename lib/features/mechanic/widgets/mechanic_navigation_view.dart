import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:road_rescue/models/service_request.dart';
import 'package:road_rescue/services/directions_service.dart';
import 'package:road_rescue/services/location_service.dart';
import 'package:road_rescue/services/socket_service.dart';
import 'package:road_rescue/services/mechanic_service.dart';
import 'package:road_rescue/theme/app_colors.dart';
import 'package:road_rescue/services/toast_service.dart';

/// Two-phase navigation view for mechanic heading to driver.
/// Phase 1: Route overview with "Start Navigation" button.
/// Phase 2: Active navigation with live tracking + "Mark Arrived" button.
class MechanicNavigationView extends StatefulWidget {
  final ServiceRequest request;
  final VoidCallback? onArrived;

  const MechanicNavigationView({
    super.key,
    required this.request,
    this.onArrived,
  });

  @override
  State<MechanicNavigationView> createState() => _MechanicNavigationViewState();
}

class _MechanicNavigationViewState extends State<MechanicNavigationView> {
  GoogleMapController? _mapController;
  final SocketService _socketService = SocketService();

  // Route data
  DirectionsResult? _directions;
  Set<Polyline> _polylines = {};
  bool _isLoadingRoute = true;

  // Phase tracking
  bool _isNavigating = false; // false = overview, true = active nav

  // Current mechanic position (updates in real-time during phase 2)
  LatLng? _currentPosition;
  StreamSubscription<LocationData>? _locationSub;

  // Markers
  Set<Marker> _markers = {};

  // Loading states
  bool _isMarkingArrived = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    // Get initial mechanic position
    final hasPermission = await LocationService.requestLocationPermission();
    if (!hasPermission || _disposed) {
      print('[MechanicNav] Location permission denied or widget disposed');
      // Fallback to provider coordinates from request
      _useProviderFallback();
      await _fetchRoute();
      return;
    }

    final location = await LocationService.getCurrentLocation();
    if (_disposed) return;
    if (location != null) {
      setState(() {
        _currentPosition = LatLng(location.latitude, location.longitude);
      });
    } else {
      // GPS failed — fallback to provider coordinates from request
      _useProviderFallback();
    }

    // Join tracking room
    _socketService.joinRequest(widget.request.id);

    // Fetch the route
    await _fetchRoute();
  }

  /// Fallback: use provider lat/lng from the request if GPS is unavailable
  void _useProviderFallback() {
    final provLat = widget.request.providerLatitude;
    final provLng = widget.request.providerLongitude;
    if (provLat != null && provLng != null && !_disposed) {
      setState(() {
        _currentPosition = LatLng(provLat, provLng);
      });
      print(
        '[MechanicNav] Using provider fallback location: $provLat, $provLng',
      );
    }
  }

  Future<void> _fetchRoute() async {
    final origin = _currentPosition;
    final destination = LatLng(
      widget.request.latitude,
      widget.request.longitude,
    );

    if (origin == null) {
      if (!_disposed) setState(() => _isLoadingRoute = false);
      return;
    }

    final result = await DirectionsService.getDirections(
      origin: origin,
      destination: destination,
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

    // Fit camera to route
    _fitCameraToRoute();
  }

  void _updateMarkers() {
    final mechanicPos = _currentPosition;
    final driverPos = LatLng(widget.request.latitude, widget.request.longitude);

    _markers = {
      if (mechanicPos != null)
        Marker(
          markerId: const MarkerId('mechanic'),
          position: mechanicPos,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'You'),
        ),
      Marker(
        markerId: const MarkerId('driver'),
        position: driverPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: widget.request.driverName),
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
        80, // padding
      ),
    );
  }

  /// Start phase 2: active navigation with real-time tracking
  void _startNavigation() {
    if (_disposed) return;
    setState(() => _isNavigating = true);

    // Start continuous location tracking
    final locationStream = LocationService.startLocationTracking();
    _locationSub = locationStream.listen((location) {
      if (_disposed) {
        _locationSub?.cancel();
        return;
      }

      final newPos = LatLng(location.latitude, location.longitude);

      setState(() {
        _currentPosition = newPos;
        _updateMarkers();
      });

      // Emit location to tracking socket
      _socketService.sendLocationUpdate(
        widget.request.id,
        location.latitude,
        location.longitude,
      );

      // Follow mechanic position on the map
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newPos, zoom: 16, tilt: 45),
        ),
      );
    });
  }

  Future<void> _markArrived() async {
    setState(() => _isMarkingArrived = true);

    try {
      final success = await MechanicService.markArrived(widget.request.id);
      if (!mounted) return;

      if (success) {
        ToastService.showSuccess(context, 'Marked as arrived');
        widget.onArrived?.call();
      } else {
        ToastService.showError(context, 'Failed to mark arrived');
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Error: $e');
      }
    } finally {
      if (!_disposed) setState(() => _isMarkingArrived = false);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _locationSub?.cancel();
    _locationSub = null;
    _socketService.leaveRequest(widget.request.id);
    _mapController?.dispose();
    LocationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driverPos = LatLng(widget.request.latitude, widget.request.longitude);
    final initialPos = _currentPosition ?? driverPos;

    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map
          GoogleMap(
            initialCameraPosition: CameraPosition(target: initialPos, zoom: 14),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: _isNavigating,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              // Fit to route after map is ready
              if (_directions != null) {
                Future.delayed(
                  const Duration(milliseconds: 500),
                  _fitCameraToRoute,
                );
              }
            },
          ),

          // Top bar — back button + status
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _buildCircleButton(
                  icon: Icons.arrow_back,
                  // navigate to dashboard
                  onTap: () =>
                      Navigator.of(context).pushReplacementNamed('/mechanic'),
                ),
                const SizedBox(width: 12),
                if (_isNavigating && _directions != null)
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
                    if (_currentPosition != null) {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLng(_currentPosition!),
                      );
                    }
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
            child: _isNavigating
                ? _buildActiveNavSheet()
                : _buildOverviewSheet(),
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
          // Drag handle
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
                    'Fastest route',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                const SizedBox(height: 16),

                // Driver info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[200],
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.request.driverName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            widget.request.location,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (widget.request.driverPhone != null)
                      IconButton(
                        icon: const Icon(Icons.phone, color: Colors.green),
                        onPressed: () {
                          // TODO: launch phone call
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Description
                if (widget.request.description.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.request.description,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 20),

                // Start Navigation button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _directions != null ? _startNavigation : null,
                    icon: const Icon(Icons.navigation, color: Colors.white),
                    label: const Text(
                      'Start Navigation',
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Phase 2 — Active navigation bottom sheet (compact)
  Widget _buildActiveNavSheet() {
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
            // Drag handle
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

            // Driver info row
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[200],
                  child: const Icon(Icons.person, size: 20, color: Colors.grey),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.request.driverName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        widget.request.location,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (widget.request.driverPhone != null)
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
            const SizedBox(height: 16),

            // Mark Arrived button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isMarkingArrived ? null : _markArrived,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isMarkingArrived
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Mark Arrived',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
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
