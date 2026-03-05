import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:road_rescue/models/service_request.dart';

class TrackingView extends StatelessWidget {
  final ServiceRequest request;
  final LatLng? mechanicLocation;
  final String statusText;
  final VoidCallback? onCancel;
  final void Function(GoogleMapController) onMapCreated;

  const TrackingView({
    super.key,
    required this.request,
    required this.mechanicLocation,
    required this.statusText,
    this.onCancel,
    required this.onMapCreated,
  });

  @override
  Widget build(BuildContext context) {
    final driverLoc = LatLng(request.latitude, request.longitude);
    final targetLoc = mechanicLocation ??
        LatLng(
          request.providerLatitude ?? request.latitude,
          request.providerLongitude ?? request.longitude,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(statusText),
        automaticallyImplyLeading: false,
        actions: [
          if (onCancel != null)
            TextButton(
              onPressed: onCancel,
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: targetLoc,
              zoom: 14,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('driver'),
                position: driverLoc,
                infoWindow: const InfoWindow(title: 'You'),
              ),
              if (mechanicLocation != null)
                Marker(
                  markerId: const MarkerId('mechanic'),
                  position: mechanicLocation!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueBlue),
                  infoWindow: InfoWindow(
                      title: request.providerName ?? 'Unknown Mechanic'),
                ),
            },
            onMapCreated: onMapCreated,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -5))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    statusText,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                          child: Text((request.providerName ?? 'U')[0])),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(request.providerName ?? 'Unknown Mechanic',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          if (request.providerPhone != null)
                            Text(request.providerPhone!),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.phone, color: Colors.green),
                        onPressed: () {
                          // implement call
                        },
                      )
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
