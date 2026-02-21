import 'package:flutter/material.dart';
import 'package:road_rescue/shared/widgets/custom_text_field.dart';
import 'package:road_rescue/shared/widgets/primary_button.dart';

class PhoneStepWidget extends StatefulWidget {
  final Function(String) onContinue;

  const PhoneStepWidget({super.key, required this.onContinue});

  @override
  State<PhoneStepWidget> createState() => _PhoneStepWidgetState();
}

class _PhoneStepWidgetState extends State<PhoneStepWidget> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onContinue() {
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) return;
    widget.onContinue(phoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter your Phone Number',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 32),
        CustomTextField(
          controller: _phoneController,
          hintText: '+1 (555) 000-0000',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: 'Continue',
            onPressed: _onContinue,
            text: 'Continue',
          ),
        ),
      ],
    );
  }
}
