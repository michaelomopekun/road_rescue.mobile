import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:road_rescue/models/request_status.dart';
import 'package:road_rescue/services/request_state_manager.dart';
import 'package:road_rescue/services/driver_service.dart';
import 'package:road_rescue/features/driver/pages/searching_mechanic_page.dart'; // Ensure correct path
// Import other parts as needed, e.g. Payment screen

class ActiveRequestPage extends StatefulWidget {
  const ActiveRequestPage({super.key});

  @override
  State<ActiveRequestPage> createState() => _ActiveRequestPageState();
}

class _ActiveRequestPageState extends State<ActiveRequestPage> {
  late RequestStateManager _stateManager;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _stateManager = RequestStateManager();
    _stateManager.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _stateManager.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {}); // Rebuild UI based on latest state
    
    // Animate map if location changed
    if (_stateManager.mechanicLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_stateManager.mechanicLocation!),
      );
    }

    if (_stateManager.activeRequest == null || _stateManager.status == RequestStatus.CANCELLED) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/driver');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_stateManager.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final request = _stateManager.activeRequest;
    if (request == null) {
      return const Scaffold(
        body: Center(child: Text('No active request')),
      );
    }

    switch (request.status) {
      case RequestStatus.PENDING:
        // Use the existing searching mechanic widget/page or similar
        return _buildPendingUi();
      case RequestStatus.ACCEPTED:
        return _buildTrackingUi('Mechanic is on the way');
      case RequestStatus.ARRIVED:
        return _buildTrackingUi('Mechanic has arrived');
      case RequestStatus.QUOTED:
        return _buildQuotationUi();
      case RequestStatus.IN_PROGRESS:
        return _buildTrackingUi('Service in progress');
      case RequestStatus.COMPLETED:
        return _buildPaymentUi();
      case RequestStatus.PAID:
        // Shouldn't stay here long, but show a success state
        return const Scaffold(body: Center(child: Text('Service paid. Thank you!')));
      case RequestStatus.CANCELLED:
        return const Scaffold(body: Center(child: Text('Request cancelled.')));
    }
  }

  Widget _buildPendingUi() {
    // We could return SearchingMechanicPage directly if it's parameterized,
    // or a simple loading view
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching for nearby mechanics...', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingUi(String statusText) {
    final request = _stateManager.activeRequest!;
    final mechanicLoc = _stateManager.mechanicLocation;
    
    final driverLoc = LatLng(request.latitude, request.longitude);
    final targetLoc = mechanicLoc ?? LatLng(request.providerLatitude ?? request.latitude, request.providerLongitude ?? request.longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text(statusText),
        automaticallyImplyLeading: false,
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
              if (mechanicLoc != null)
                Marker(
                  markerId: const MarkerId('mechanic'),
                  position: mechanicLoc,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                  infoWindow: InfoWindow(title: request.providerName ?? 'Unknown Mechanic'),
                ),
            },
            onMapCreated: (controller) => _mapController = controller,
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
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    statusText,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(child: Text((request.providerName ?? 'U')[0])),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(request.providerName ?? 'Unknown Mechanic', style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildQuotationUi() {
    final request = _stateManager.activeRequest!;
    final quote = request.quotation;

    if (quote == null) return _buildTrackingUi('Waiting for quotation details...');

    return Scaffold(
      appBar: AppBar(title: const Text('Quotation Received'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Here is the breakdown of the service:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ...quote.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item.quantity}x ${item.type}'),
                          Text('N${item.total}'),
                        ],
                      ),
                    )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('N${quote.totalAmount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Notes: ${quote.description}'),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final success = await DriverService.rejectQuotation(quote.id);
                      if (success) {
                        // Usually changes status to CANCELLED or goes back to PENDING. Backend will emit update.
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quotation rejected.')));
                      }
                    },
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final success = await DriverService.approveQuotation(quote.id);
                      if (success) {
                        // Will emit update to IN_PROGRESS
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quotation approved.')));
                      }
                    },
                    child: const Text('Approve'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentUi() {
    // Replace with real payment page logic
    return Scaffold(
      appBar: AppBar(title: const Text('Service Completed'), automaticallyImplyLeading: false),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            const Text('Service Completed Successfully!', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Should invoke payment API
                _stateManager.clearActiveRequest();
                Navigator.of(context).pushReplacementNamed('/driver');
              },
              child: const Text('Proceed to Payment'),
            )
          ],
        ),
      ),
    );
  }
}
