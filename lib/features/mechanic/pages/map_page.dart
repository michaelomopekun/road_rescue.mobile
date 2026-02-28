import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:road_rescue/features/mechanic/widgets/dashboard_bottom_nav_bar.dart';
import 'package:road_rescue/theme/app_colors.dart';
import 'package:road_rescue/services/location_service.dart';
import 'package:road_rescue/services/mechanic_service.dart';
import 'package:road_rescue/services/toast_service.dart';

class MechanicMapPage extends StatefulWidget {
  const MechanicMapPage({super.key});

  @override
  State<MechanicMapPage> createState() => _MechanicMapPageState();
}

class _MechanicMapPageState extends State<MechanicMapPage> {
  int _selectedNavIndex = 2;
  late GoogleMapController _mapController;
  bool _isAvailable = true;
  bool _isLoadingLocation = true;
  bool _disposed = false;

  LatLng? _currentLocation;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    if (!mounted) return;

    // Request location permission
    final hasPermission = await LocationService.requestLocationPermission();
    if (!hasPermission) {
      if (mounted && !_disposed) {
        ToastService.showWarning(context, 'Location permission denied');
        setState(() => _isLoadingLocation = false);
      }
      return;
    }

    // Check if location service is enabled
    final isEnabled = await LocationService.isLocationServiceEnabled();
    if (!isEnabled) {
      if (mounted && !_disposed) {
        ToastService.showWarning(context, 'Please enable location services');
        setState(() => _isLoadingLocation = false);
      }
      return;
    }

    // Get initial location
    final location = await LocationService.getCurrentLocation();
    if (location != null && !_disposed) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(location.latitude, location.longitude);
          _updateMapMarkers();
          _isLoadingLocation = false;
        });
      }

      // Start continuous tracking
      LocationService.startLocationTracking().listen(
        (locationData) {
          if (!_disposed && mounted) {
            setState(() {
              _currentLocation = LatLng(
                locationData.latitude,
                locationData.longitude,
              );
              _updateMapMarkers();
            });
          }
        },
        onError: (error) {
          print('Location tracking error: $error');
        },
      );
    } else if (!_disposed && mounted) {
      setState(() => _isLoadingLocation = false);
      ToastService.showError(context, 'Unable to get location');
    }
  }

  void _updateMapMarkers() {
    if (_currentLocation == null) return;

    // Clear previous markers and circles
    _markers.clear();
    _circles.clear();

    // Add mechanic location marker
    _markers.add(
      Marker(
        markerId: const MarkerId('mechanic_location'),
        position: _currentLocation!,
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'Current position',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    // Add accuracy circle
    _circles.add(
      Circle(
        circleId: const CircleId('accuracy_circle'),
        center: _currentLocation!,
        radius: 50, // 50 meters
        fillColor: AppColors.primary.withOpacity(0.1),
        strokeColor: AppColors.primary.withOpacity(0.3),
        strokeWidth: 1,
      ),
    );
  }

  void _handleNavigation(int index) {
    setState(() {
      _selectedNavIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/mechanic');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/mechanic/wallet');
        break;
      case 2:
        // Already on Map
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/mechanic/history');
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed('/mechanic/profile');
        break;
    }
  }

  Future<void> _toggleAvailability() async {
    setState(() => _isAvailable = !_isAvailable);

    try {
      await MechanicService.updateAvailabilityStatus(_isAvailable);
      if (mounted && !_disposed) {
        ToastService.showSuccess(
          context,
          _isAvailable ? 'You are now Online' : 'You are now Offline',
        );
      }
    } catch (e) {
      if (mounted && !_disposed) {
        setState(() => _isAvailable = !_isAvailable);
        ToastService.showError(context, 'Failed to update status');
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _searchController.dispose();
    LocationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          if (_isLoadingLocation || _currentLocation == null)
            const Center(child: CircularProgressIndicator())
          else
            GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
                if (_currentLocation != null) {
                  _mapController.animateCamera(
                    CameraUpdate.newLatLng(_currentLocation!),
                  );
                }
              },
              initialCameraPosition: CameraPosition(
                target: _currentLocation ?? const LatLng(0, 0),
                zoom: 16,
              ),
              markers: _markers,
              circles: _circles,
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
            ),

          // Top controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for area',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status card
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _isAvailable
                                    ? Colors.green
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isAvailable
                                  ? 'You are Online'
                                  : 'You are Offline',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              value: _isAvailable,
                              onChanged: (_) => _toggleAvailability(),
                              activeColor: AppColors.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isAvailable
                              ? 'Waiting for requests...'
                              : 'Not receiving requests',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom navigation
                DashboardBottomNavBar(
                  selectedIndex: _selectedNavIndex,
                  onTabChanged: _handleNavigation,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
