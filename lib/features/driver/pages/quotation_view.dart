import 'package:flutter/material.dart';
import 'package:road_rescue/models/service_request.dart';
import 'package:road_rescue/services/driver_service.dart';

class QuotationView extends StatelessWidget {
  final ServiceRequest request;
  final VoidCallback? onCancel;

  const QuotationView({
    super.key,
    required this.request,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final quote = request.quotation;

    if (quote == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Waiting for details...'),
          automaticallyImplyLeading: false,
          actions: [
            if (onCancel != null)
              TextButton(
                onPressed: onCancel,
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotation Received'),
        automaticallyImplyLeading: false,
        actions: [
          if (onCancel != null)
            TextButton(
              onPressed: onCancel,
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Here is the breakdown of the service:',
                style: TextStyle(fontSize: 16)),
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
                        const Text('Total:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('N${quote.totalAmount}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Quotation rejected.')));
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
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Quotation approved.')));
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
}
