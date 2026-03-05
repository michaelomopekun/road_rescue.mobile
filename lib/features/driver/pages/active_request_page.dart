import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:road_rescue/models/request_status.dart';
import 'package:road_rescue/services/request_state_manager.dart';
import 'package:road_rescue/services/driver_service.dart';
import 'package:road_rescue/features/driver/pages/searching_mechanic_page.dart'; // Ensure correct path
import 'package:road_rescue/features/driver/pages/tracking_view.dart';
import 'package:road_rescue/features/driver/pages/quotation_view.dart';
import 'package:road_rescue/features/driver/pages/payment_view.dart';
import 'package:road_rescue/features/driver/pages/no_provider_view.dart';

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

    if (_stateManager.activeRequest == null || _stateManager.status == RequestStatus.CANCELLED || _stateManager.status == RequestStatus.PAID) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/driver');
      }
    }
  }

  void _handleCancelRequest() async {
    final request = _stateManager.activeRequest;
    if (request == null) return;

    final success = await DriverService.cancelRequest(request.id);
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel request.')),
        );
      }
    } else {
       // On success, backend should emit CANCELLED over socket, which will trigger redirection.
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Cancelling request...')),
          );
       }
    }
  }

  void _handleRetryNoProvider() {
     _stateManager.clearActiveRequest();
     Navigator.of(context).pushReplacement(
        MaterialPageRoute(
           builder: (context) => const SearchingMechanicPage(
              issueType: 'General Repair', // Might want to save actual issue in state to re-pass it
              issueIcon: Icons.handyman,
           ),
        ),
     );
  }

  void _handleBackToDashboard() {
     _stateManager.clearActiveRequest();
     Navigator.of(context).pushReplacementNamed('/driver');
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
        return TrackingView(
          request: request,
          mechanicLocation: _stateManager.mechanicLocation,
          statusText: 'Mechanic is on the way',
          onMapCreated: (controller) => _mapController = controller,
          onCancel: _handleCancelRequest,
        );
      case RequestStatus.ARRIVED:
        return TrackingView(
          request: request,
          mechanicLocation: _stateManager.mechanicLocation,
          statusText: 'Mechanic has arrived',
          onMapCreated: (controller) => _mapController = controller,
          onCancel: _handleCancelRequest,
        );
      case RequestStatus.QUOTED:
        return QuotationView(
          request: request,
          onCancel: _handleCancelRequest,
        );
      case RequestStatus.IN_PROGRESS:
        // No cancellation allowed here per requirements
        return TrackingView(
          request: request,
          mechanicLocation: _stateManager.mechanicLocation,
          statusText: 'Service in progress',
          onMapCreated: (controller) => _mapController = controller,
        );
      case RequestStatus.COMPLETED:
        return PaymentView(request: request);
      case RequestStatus.NO_PROVIDER_FOUND:
        return NoProviderView(
           onRetry: _handleRetryNoProvider,
           onDashboard: _handleBackToDashboard,
        );
      case RequestStatus.PAID:
      case RequestStatus.CANCELLED:
        return const Scaffold(body: Center(child: CircularProgressIndicator())); 
    }
  }

  Widget _buildPendingUi() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Searching'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _handleCancelRequest,
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: const Center(
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
}

