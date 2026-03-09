import 'package:flutter/material.dart';
import 'package:road_rescue/models/request_status.dart';
import 'package:road_rescue/services/request_state_manager.dart';
import 'package:road_rescue/services/mechanic_service.dart';
import 'package:road_rescue/features/mechanic/widgets/mechanic_navigation_view.dart';
import 'package:road_rescue/features/mechanic/widgets/create_service_quotation_view.dart';
import 'package:road_rescue/services/toast_service.dart';

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

  void _checkAndNavigate() {
    final request = _stateManager.activeRequest;
    if (request == null ||
        request.status == RequestStatus.NO_PROVIDER_FOUND ||
        request.status == RequestStatus.CANCELLED ||
        request.status == RequestStatus.COMPLETED ||
        request.providerId == null) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/mechanic');
      }
    }
  }

  void _onStateChanged() {
    setState(() {}); // Rebuild UI based on latest state
    _checkAndNavigate();
  }

  @override
  Widget build(BuildContext context) {
    if (_stateManager.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final request = _stateManager.activeRequest;
    if (request == null ||
        request.status == RequestStatus.NO_PROVIDER_FOUND ||
        request.status == RequestStatus.CANCELLED ||
        request.status == RequestStatus.COMPLETED ||
        request.providerId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndNavigate();
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
        return const Scaffold(
          body: Center(child: Text('Job paid. Return to dashboard.')),
        );
      default:
        return const Scaffold(body: Center(child: Text('Invalid status')));
    }
  }

  Widget _buildNavigationUi() {
    final request = _stateManager.activeRequest!;
    return MechanicNavigationView(request: request);
  }

  Widget _buildQuotationFormUi() {
    final request = _stateManager.activeRequest!;

    return CreateServiceQuotationView(
      request: request,
      onCancel: () {
        // Maybe navigate back to dashboard or show confirmation
        Navigator.of(context).pushReplacementNamed('/mechanic');
      },
      onSubmitted: () {
        ToastService.showSuccess(context, 'Quotation submitted successfully');
      },
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
      appBar: AppBar(
        title: const Text('Work in Progress'),
        automaticallyImplyLeading: false,
      ),
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
                  final success = await MechanicService.markCompleted(
                    request.id,
                  );
                  if (!mounted) return;
                  if (success) {
                    ToastService.showSuccess(
                      context,
                      'Job marked as completed',
                    );
                  }
                },
                child: const Text('Mark Service Completed'),
              ),
            ),
          ),
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
