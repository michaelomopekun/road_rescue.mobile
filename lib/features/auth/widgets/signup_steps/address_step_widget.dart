import 'package:flutter/material.dart';
import 'package:road_rescue/shared/widgets/custom_text_field.dart';
import 'package:road_rescue/shared/widgets/primary_button.dart';

class AddressStepWidget extends StatefulWidget {
  final Function(String) onContinue;

  const AddressStepWidget({super.key, required this.onContinue});

  @override
  State<AddressStepWidget> createState() => _AddressStepWidgetState();
}

class _AddressStepWidgetState extends State<AddressStepWidget> {
  final _addressController = TextEditingController();
  final List<String> _suggestedAddresses = [
    'Bremerton Children\'s Centre, Coatbridge House, Camoustie Dr, London, N1 0DX',
    'Jean Stokes Community Centre, Coatbridge House, Camoustie Dr, London, N1 0DX',
    'Flat 1, Coatbridge House, Camoustie Dr, London, N1 0DX',
  ];

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _selectAddress(String address) {
    widget.onContinue(address);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select workshop address?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 32),
        CustomTextField(
          controller: _addressController,
          hintText: 'enter your address here',
          suffixIcon: const Icon(Icons.search),
        ),
        const SizedBox(height: 24),

        // Suggested addresses list
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _suggestedAddresses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _AddressTile(
              address: _suggestedAddresses[index],
              onTap: () => _selectAddress(_suggestedAddresses[index]),
            );
          },
        ),
      ],
    );
  }
}

class _AddressTile extends StatelessWidget {
  final String address;
  final VoidCallback onTap;

  const _AddressTile({required this.address, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(address, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}
