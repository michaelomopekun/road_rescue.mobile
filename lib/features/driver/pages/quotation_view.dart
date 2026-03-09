import 'package:flutter/material.dart';
import 'package:road_rescue/models/service_request.dart';
import 'package:road_rescue/models/quotation.dart';
import 'package:road_rescue/services/driver_service.dart';
import 'package:road_rescue/services/toast_service.dart';

class QuotationView extends StatefulWidget {
  final ServiceRequest request;
  final VoidCallback? onCancel;

  const QuotationView({super.key, required this.request, this.onCancel});

  @override
  State<QuotationView> createState() => _QuotationViewState();
}

class _QuotationViewState extends State<QuotationView> {
  bool _isProcessing = false;

  final Color _primaryDark = const Color(0xFF1B3D46);
  final Color _backgroundColor = const Color(0xFFF4F8FB);

  double _calculateTotalByType(Quotation quote, String type) {
    return quote.items
        .where((item) => item.type.toUpperCase() == type.toUpperCase())
        .fold(0.0, (sum, item) => sum + item.total);
  }

  @override
  Widget build(BuildContext context) {
    final quote = widget.request.quotation;

    if (quote == null) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          backgroundColor: _backgroundColor,
          elevation: 0,
          leading: widget.onCancel != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: widget.onCancel,
                )
              : null,
          title: const Text(
            'Waiting for details...',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        leading: widget.onCancel != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: widget.onCancel,
              )
            : null,
        title: const Text(
          'Service Quotation',
          style: TextStyle(
            color: Color(0xFF1B2C36),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProviderCard(),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF1B2C36),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Service Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2C36),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                quote.description.isNotEmpty
                    ? quote.description
                    : 'No detailed description provided by the mechanic.',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.list_alt, color: Color(0xFF1B2C36), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'BREAKDOWN LIST',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B2C36),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...quote.items.map((item) => _buildItemCard(item)),
            _buildSummaryCard(quote),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(quote),
    );
  }

  Widget _buildProviderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F0F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: Image.asset(
                'assets/images/mechanic_placeholder.png',
                fit: BoxFit.cover,
                width: 56,
                height: 56,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.person,
                    color: Colors.grey.shade400,
                    size: 36,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.request.providerName ?? 'Verified Mechanic',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Color(0xFF1B2C36),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.request.serviceType ?? 'Engine repair and maintenance',
                  style: const TextStyle(
                    color: Color(0xFF1B3D46),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Verified Mechanic',
                      style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(QuotationItem item) {
    Color labelColor;
    Color labelBgColor;

    switch (item.type.toUpperCase()) {
      case 'PART':
        labelColor = Colors.blueGrey.shade700;
        labelBgColor = Colors.grey.shade200;
        break;
      case 'LABOUR':
        labelColor = Colors.blue.shade700;
        labelBgColor = Colors.blue.shade50;
        break;
      case 'TRANSPORT':
        labelColor = Colors.deepOrange.shade700;
        labelBgColor = Colors.deepOrange.shade50;
        break;
      default:
        labelColor = Colors.grey.shade700;
        labelBgColor = Colors.grey.shade200;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: labelBgColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: labelColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1B2C36),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Qty: ${item.quantity} | Unit: \$${item.unitPrice.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '\$${item.total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1B2C36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Quotation quote) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: _primaryDark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryDark.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 20,
            top: 20,
            child: Icon(
              Icons.receipt_long,
              size: 80,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quotation Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildSummaryRow(
                  'Total Parts',
                  _calculateTotalByType(quote, 'PART'),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  'Total Labour',
                  _calculateTotalByType(quote, 'LABOUR'),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  'Transport / Call-out',
                  _calculateTotalByType(quote, 'TRANSPORT'),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: Colors.white24, height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Grand TOTAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${quote.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(Quotation quote) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(color: Color(0xFFF4F8FB)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isProcessing
                  ? null
                  : () async {
                      setState(() => _isProcessing = true);
                      final success = await DriverService.approveQuotation(
                        quote.id,
                      );
                      if (mounted) {
                        setState(() => _isProcessing = false);
                        if (success) {
                          ToastService.showSuccess(
                            context,
                            'Quotation approved.',
                          );
                        } else {
                          ToastService.showError(
                            context,
                            'Failed to approve quotation.',
                          );
                        }
                      }
                    },
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline, size: 20),
              label: const Text(
                'Approve & Start Service',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: _isProcessing
                  ? null
                  : () async {
                      setState(() => _isProcessing = true);
                      final success = await DriverService.rejectQuotation(
                        quote.id,
                      );
                      if (mounted) {
                        setState(() => _isProcessing = false);
                        if (success) {
                          ToastService.showError(
                            context,
                            'Quotation rejected.',
                          );
                        } else {
                          ToastService.showError(
                            context,
                            'Failed to reject quotation.',
                          );
                        }
                      }
                    },
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(
                  0xFF5E7282,
                ), // BlueGreyish color to match image
                side: const BorderSide(
                  color: Color(0xFFDCE4E8),
                  width: 1.5,
                ), // Soft grey border
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Reject Quotation',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
