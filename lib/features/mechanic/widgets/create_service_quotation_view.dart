import 'package:flutter/material.dart';
import 'package:road_rescue/models/quotation.dart';
import 'package:road_rescue/models/service_request.dart';
import 'package:road_rescue/services/mechanic_service.dart';
import 'package:road_rescue/services/toast_service.dart';

class CreateServiceQuotationView extends StatefulWidget {
  final ServiceRequest request;
  final VoidCallback onCancel;
  final VoidCallback onSubmitted;

  const CreateServiceQuotationView({
    super.key,
    required this.request,
    required this.onCancel,
    required this.onSubmitted,
  });

  @override
  State<CreateServiceQuotationView> createState() =>
      _CreateServiceQuotationViewState();
}

class _CreateServiceQuotationViewState
    extends State<CreateServiceQuotationView> {
  final TextEditingController _serviceDescriptionController =
      TextEditingController();
  final TextEditingController _itemDescriptionController =
      TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: "1",
  );
  final TextEditingController _unitPriceController = TextEditingController();

  String _selectedItemType = 'PART';
  String _selectedUnit = 'UNIT';

  final List<QuotationItem> _items = [];
  bool _isSubmitting = false;

  final Color _primaryDark = const Color(0xFF1B3D46);
  final Color _backgroundColor = const Color(0xFFF4F8FB);
  final Color _cardColor = Colors.white;

  double get _totalParts {
    return _items
        .where((item) => item.type == 'PART')
        .fold(0.0, (sum, item) => sum + (item.quantity * item.unitPrice));
  }

  double get _totalLabour {
    return _items
        .where((item) => item.type == 'LABOUR')
        .fold(0.0, (sum, item) => sum + (item.quantity * item.unitPrice));
  }

  double get _totalTransport {
    return _items
        .where((item) => item.type == 'TRANSPORT')
        .fold(0.0, (sum, item) => sum + (item.quantity * item.unitPrice));
  }

  double get _grandTotal {
    return _items.fold(
      0.0,
      (sum, item) => sum + (item.quantity * item.unitPrice),
    );
  }

  void _addItem() {
    if (_itemDescriptionController.text.trim().isEmpty) return;
    final qty = int.tryParse(_quantityController.text) ?? 1;
    final price = double.tryParse(_unitPriceController.text) ?? 0.0;

    if (price <= 0) return;

    setState(() {
      _items.add(
        QuotationItem(
          description: _itemDescriptionController.text.trim(),
          type: _selectedItemType,
          quantity: qty,
          unit: _selectedUnit,
          unitPrice: price,
        ),
      );
    });

    _itemDescriptionController.clear();
    _quantityController.text = "1";
    _unitPriceController.clear();

    // Unfocus keyboard
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _submitQuotation() async {
    if (_items.isEmpty) {
      ToastService.showError(
        context,
        'Please add at least one item to the quotation',
      );
      return;
    }

    if (_serviceDescriptionController.text.trim().isEmpty) {
      ToastService.showError(context, 'Please enter a service description');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final quotation = Quotation(
        items: _items,
        description: _serviceDescriptionController.text.trim(),
      );

      final success = await MechanicService.submitQuotation(
        widget.request.id,
        widget.request.providerId,
        quotation,
      );

      if (success && mounted) {
        widget.onSubmitted();
      } else if (mounted) {
        ToastService.showError(context, 'Failed to submit quotation');
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('UnauthorizedException') ||
            e.toString().contains('No token found') ||
            e.toString().contains('Unauthorized')) {
          ToastService.showError(
            context,
            'Session expired. Please log in again.',
          );
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/signin', (route) => false);
        } else {
          ToastService.showError(context, 'Error: $e');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: widget.onCancel,
        ),
        title: const Text(
          'Create Service Quotation',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 24),
            _buildSectionTitle(
              Icons.description_outlined,
              'Service Description',
            ),
            const SizedBox(height: 8),
            _buildServiceDescriptionField(),
            const SizedBox(height: 24),
            _buildAddLineItemSection(),
            const SizedBox(height: 24),
            if (_items.isNotEmpty) ...[
              _buildItemsPreviewHeader(),
              const SizedBox(height: 12),
              ..._items.asMap().entries.map(
                (entry) => _buildItemTile(entry.key, entry.value),
              ),
              const SizedBox(height: 24),
              _buildQuotationSummary(),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'FINAL PRICE MAY VARY BASED ON UNFORESEEN\nCOMPLICATIONS DURING REPAIR. CUSTOMER\nAPPROVAL REQUIRED.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.black38,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 80), // Padding for bottom buttons
            ],
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F0F4), // lighter blue/grey
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.build_circle_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REQUEST ID: ${widget.request.id.length > 8 ? widget.request.id.substring(0, 8).toUpperCase() : widget.request.id}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _primaryDark,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Issue: ${widget.request.serviceType ?? widget.request.description.split('\n').first}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Drafting quotation for provider',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: _primaryDark, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1B2C36),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _serviceDescriptionController,
        maxLines: 4,
        style: const TextStyle(fontSize: 14),
        decoration: const InputDecoration(
          hintText:
              'Enter detailed description of the\ndiagnostic findings and planned repairs...',
          hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildAddLineItemSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle_outline, color: _primaryDark, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Add Line Item',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B2C36),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Item Type',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 6),
          _buildDropdownButton(
            value: _selectedItemType,
            items: ['PART', 'LABOUR', 'TRANSPORT'],
            onChanged: (val) {
              if (val != null) setState(() => _selectedItemType = val);
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'UNIT',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          _buildDropdownButton(
            value: _selectedUnit,
            items: ['UNIT', 'HOUR', 'FLAT'],
            onChanged: (val) {
              if (val != null) setState(() => _selectedUnit = val);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QUANTITY',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'UNIT PRICE (₦)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildInputField(
                      controller: _unitPriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      hintText: '0.00',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Item Description',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 6),
          _buildInputField(
            controller: _itemDescriptionController,
            hintText: 'e.g. Brake Pads (Front Pair)',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Add to Quotation',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownButton({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
          items: items.map((String item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? hintText,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildItemsPreviewHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.list_alt, color: _primaryDark, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Items Preview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B2C36),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blueGrey.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_items.length} ${(_items.length == 1) ? 'ITEM' : 'ITEMS'} ADDED',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _primaryDark,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemTile(int index, QuotationItem item) {
    Color labelColor;
    Color labelBgColor;
    Color leftBarColor;

    switch (item.type) {
      case 'PART':
        labelColor = Colors.grey.shade700;
        labelBgColor = Colors.grey.shade200;
        leftBarColor = _primaryDark;
        break;
      case 'LABOUR':
        labelColor = Colors.blue.shade700;
        labelBgColor = Colors.blue.shade50;
        leftBarColor = Colors.blue;
        break;
      case 'TRANSPORT':
        labelColor = Colors.deepOrange.shade700;
        labelBgColor = Colors.deepOrange.shade50;
        leftBarColor = Colors.orange;
        break;
      default:
        labelColor = Colors.grey.shade700;
        labelBgColor = Colors.grey.shade200;
        leftBarColor = _primaryDark;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: leftBarColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
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
                                    item.type,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
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
                                      fontSize: 14,
                                      color: Color(0xFF1B2C36),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.quantity} ${item.unit} @ ₦${item.unitPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.blueGrey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₦${(item.quantity * item.unitPrice).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B2C36),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _removeItem(index),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.black38,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuotationSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 16),
          _buildSummaryRow('Total Parts', _totalParts),
          const SizedBox(height: 8),
          _buildSummaryRow('Total Labour', _totalLabour),
          const SizedBox(height: 8),
          _buildSummaryRow('Transport / Call-out', _totalTransport),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
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
                '₦${_grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
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
          '₦${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundColor,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1B2C36),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitQuotation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Submit Quotation',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.send_rounded, size: 18),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
