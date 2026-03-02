import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:road_rescue/theme/app_colors.dart';

class NearbyMechanicsMapPage extends StatefulWidget {
  final String issueType;

  const NearbyMechanicsMapPage({
    super.key,
    required this.issueType,
  });

  @override
  State<NearbyMechanicsMapPage> createState() => _NearbyMechanicsMapPageState();
}

class _NearbyMechanicsMapPageState extends State<NearbyMechanicsMapPage> {
  GoogleMapController? _mapController;
  int _selectedMechanicIndex = 0;

  // Let's position the map center roughly correctly
  final LatLng _center = const LatLng(34.0522, -118.2437);

  final List<Map<String, dynamic>> _mechanics = [
    {
      'name': 'Mike Richardson',
      'specialty': 'TOWING EXPERT',
      'distance': '0.8',
      'icon': Icons.person,
      'color': Colors.white,
      'iconColor': const Color(0xFFEAB308), // Yellow
      'lat': 34.0562,
      'lng': -118.2417,
      'hasBorder': true,
    },
    {
      'name': 'Sarah Jenkins',
      'specialty': 'BATTERY & LOCKOUT',
      'distance': '1.2',
      'icon': Icons.person,
      'color': const Color(0xFFFCD34D), // Amber 300
      'iconColor': const Color(0xFF1E293B), // Slate 800
      'lat': 34.0482,
      'lng': -118.2517,
      'hasBorder': false,
    },
    {
      'name': 'Quick Fix Auto',
      'specialty': 'FULL SERVICE',
      'distance': '2.5',
      'icon': Icons.storefront,
      'color': const Color(0xFFF1F5F9), // Slate 100
      'iconColor': const Color(0xFF94A3B8), // Slate 400
      'lat': 34.0622,
      'lng': -118.2337,
      'hasBorder': false,
    },
  ];

  Set<Marker> _createMarkers() {
    Set<Marker> markers = {};
    for (int i = 0; i < _mechanics.length; i++) {
      final mech = _mechanics[i];
      final isSelected = _selectedMechanicIndex == i;
      markers.add(
        Marker(
          markerId: MarkerId(mech['name']),
          position: LatLng(mech['lat'], mech['lng']),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isSelected ? BitmapDescriptor.hueCyan : BitmapDescriptor.hueAzure,
          ),
          zIndex: isSelected ? 2.0 : 1.0,
          onTap: () {
            setState(() {
              _selectedMechanicIndex = i;
            });
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(LatLng(mech['lat'], mech['lng'])),
            );
          },
        ),
      );
    }
    
    // Add dummy user marker
    markers.add(
      Marker(
        markerId: const MarkerId('user_loc'),
        position: _center,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      )
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
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 1),
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
                // Feature explicitly requested action
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 1),
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
                color: Color(0xFFF4F7FB), // Matched exactly to the blueish light shade
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))
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
                            '3 available within 5 miles',
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
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: _mechanics.length,
                      itemBuilder: (context, index) {
                        return _buildMechanicTile(index, _mechanics[index]);
                      },
                    ),
                  ),
                  
                  // Request Button
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
                          // Show "Requesting Assistance" Dialog
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) {
                              return Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
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
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(0xFFE2E8F0),
                                                width: 4,
                                              ),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.build_outlined,
                                            color: Color(0xFF1E4C4E),
                                            size: 32,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      const Text(
                                        'Requesting Assistance...',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Please wait for the mechanic to accept\nyour request. This usually takes less than\na minute.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF64748B),
                                          height: 1.5,
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
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.build_outlined, color: Colors.white, size: 20),
                        label: const Text(
                          'Request Mechanic',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
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
          )
        ],
      ),
    );
  }

  Widget _buildMechanicTile(int index, Map<String, dynamic> mechanic) {
    final isSelected = _selectedMechanicIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMechanicIndex = index;
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(mechanic['lat'], mechanic['lng'])),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          border: isSelected 
              ? const Border(left: BorderSide(color: Color(0xFF1E4C4E), width: 4))
              : const Border(left: BorderSide(color: Colors.transparent, width: 4)),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
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
                    color: mechanic['color'],
                    borderRadius: BorderRadius.circular(16),
                    border: mechanic['hasBorder'] 
                        ? Border.all(color: const Color(0xFFF1F5F9), width: 2)
                        : null,
                  ),
                  child: Center(
                    child: mechanic['hasBorder']
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEAB308), // inner circle for Mike
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Icon(mechanic['icon'], size: 28, color: const Color(0xFF1E293B)),
                            ],
                          )
                        : Icon(mechanic['icon'], size: 32, color: mechanic['iconColor']),
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
                    mechanic['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mechanic['specialty'],
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
                  '${mechanic['distance']} mi',
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
