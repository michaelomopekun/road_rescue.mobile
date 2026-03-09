import 'package:flutter/material.dart';
import 'package:road_rescue/models/service_request.dart';
import 'package:road_rescue/services/driver_service.dart';
import 'package:uuid/uuid.dart';
import 'package:road_rescue/services/toast_service.dart';

class PaymentView extends StatefulWidget {
  final ServiceRequest request;

  const PaymentView({super.key, required this.request});

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  bool _isProcessing = false;

  Future<void> _processPayment() async {
    final quoteId = widget.request.quotation?.id;
    if (quoteId == null) {
      ToastService.showError(context, 'Error: No quotation found to pay for.');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final idempotencyKey =
          'driver-${widget.request.id}-quotation-$quoteId-${const Uuid().v4()}';

      final success = await DriverService.processPayment(
        quotationId: quoteId,
        idempotencyKey: idempotencyKey,
      );

      if (success) {
        // We wait for the socket state update to turn the request PAID organically
        if (mounted) {
          ToastService.showWarning(
            context,
            'Payment processing. Please wait...',
          );
        }
      } else {
        if (mounted) {
          ToastService.showError(context, 'Payment failed. Please try again.');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Completed'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Service Completed Successfully!',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 24),
            _isProcessing
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _processPayment,
                    child: const Text('Proceed to Payment'),
                  ),
          ],
        ),
      ),
    );
  }
}
