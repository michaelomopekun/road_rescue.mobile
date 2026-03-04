import 'package:flutter/material.dart';
import 'package:road_rescue/models/request_status.dart';
import 'package:road_rescue/models/quotation.dart';
import 'package:road_rescue/services/request_state_manager.dart';
import 'package:road_rescue/services/mechanic_service.dart';

class ActiveJobPage extends StatefulWidget {
  const ActiveJobPage({super.key});

  @override
  State<ActiveJobPage> createState() => _ActiveJobPageState();
}

class _ActiveJobPageState extends State<ActiveJobPage> {
  late RequestStateManager _stateManager;

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

    if (_stateManager.activeRequest == null || _stateManager.status == RequestStatus.CANCELLED) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/mechanic');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_stateManager.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final request = _stateManager.activeRequest;
    if (request == null) {
      return const Scaffold(body: Center(child: Text('No active job')));
    }

    switch (request.status) {
      case RequestStatus.ACCEPTED:
        return _buildNavigationUi();
      case RequestStatus.ARRIVED:
        return _buildQuotationFormUi();
      case RequestStatus.QUOTED:
        return _buildWaitingApprovalUi();
      case RequestStatus.IN_PROGRESS:
        return _buildWorkModeUi();
      case RequestStatus.COMPLETED:
        return _buildWaitingPaymentUi();
      case RequestStatus.PAID:
        return const Scaffold(body: Center(child: Text('Job paid. Return to dashboard.')));
      default:
        return const Scaffold(body: Center(child: Text('Invalid status')));
    }
  }

  Widget _buildNavigationUi() {
    final request = _stateManager.activeRequest!;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Navigation to Driver'), automaticallyImplyLeading: false),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.navigation, size: 80, color: Colors.blue),
                  const SizedBox(height: 16),
                  Text('Heading to: ${request.location}'),
                  Text('Driver: ${request.driverName}'),
                  if (request.driverPhone != null) Text('Phone: ${request.driverPhone!}'),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  final success = await MechanicService.markArrived(request.id);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as arrived')));
                  }
                },
                child: const Text('Mark Arrived'),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuotationFormUi() {
    final request = _stateManager.activeRequest!;
    
    // In a real app, this would be a Form widget with controllers
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Quotation'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('Inspect the vehicle and enter quotation details.'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  // Hardcoded for demonstration. Add form fields in reality.
                  final quote = Quotation(
                    items: [
                      QuotationItem(description: 'Initial Diagnostic', type: 'Diagnostic Fee', quantity: 1, unit: 'Flat', unitPrice: 5000),
                    ],
                    description: 'Basic inspection done.',
                    totalAmount: 5000,
                  );
                  
                  final success = await MechanicService.submitQuotation(request.id, quote);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quotation submitted')));
                  }
                },
                child: const Text('Send Quotation to Driver'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingApprovalUi() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Waiting for driver to approve quotation...'),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkModeUi() {
    final request = _stateManager.activeRequest!;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Work in Progress'), automaticallyImplyLeading: false),
      body: Column(
        children: [
          const Expanded(
            child: Center(
              child: Icon(Icons.build, size: 80, color: Colors.orange),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  final success = await MechanicService.markCompleted(request.id);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job marked as completed')));
                  }
                },
                child: const Text('Mark Service Completed'),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWaitingPaymentUi() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Waiting for driver to make payment...'),
          ],
        ),
      ),
    );
  }
}
