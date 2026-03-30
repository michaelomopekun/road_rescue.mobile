import 'package:flutter/material.dart';
import 'package:road_rescue/shared/widgets/custom_text_field.dart';
import 'package:road_rescue/shared/widgets/primary_button.dart';
import 'package:road_rescue/shared/utils/validators.dart';

class PhoneStepWidget extends StatefulWidget {
  final Function(String) onContinue;

  const PhoneStepWidget({super.key, required this.onContinue});

  @override
  State<PhoneStepWidget> createState() => _PhoneStepWidgetState();
}

class _PhoneStepWidgetState extends State<PhoneStepWidget> {
  final _phoneController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _formatPhoneNumber(String number) {
    String formatted = number.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    if (formatted.isEmpty) return formatted;

    if (formatted.startsWith('0')) {
      formatted = '+234${formatted.substring(1)}';
    } else if (formatted.startsWith('234')) {
      formatted = '+$formatted';
    } else if (!formatted.startsWith('+')) {
      formatted = '+234$formatted';
    }
    return formatted;
  }

  String? _validateNigerianPhone(String formattedNumber) {
    final baseError = Validators.validatePhoneNumber(formattedNumber);

    if (baseError != null &&
        !baseError.contains('10 digits') &&
        !baseError.contains('15 digits')) {
      return baseError;
    }

    if (formattedNumber.length < 14) {
      return 'Phone number is not valid (should be 11 digits)';
    } else if (formattedNumber.length > 14) {
      return 'Phone number is not valid (should be 11 digits)';
    }
    return null;
  }

  void _onPhoneChanged(String value) {
    setState(() {
      if (value.isEmpty) {
        _errorMessage = null;
        return;
      }
      final formattedNumber = _formatPhoneNumber(value);
      _errorMessage = _validateNigerianPhone(formattedNumber);
    });
  }

  void _onContinue() {
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
      setState(() {
        _errorMessage = 'Phone number is required';
      });
      return;
    }

    final formattedNumber = _formatPhoneNumber(phoneNumber);
    final validationError = _validateNigerianPhone(formattedNumber);

    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
      });
      return;
    }

    widget.onContinue(formattedNumber);
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
          hintText: '+234 8135763381',
          keyboardType: TextInputType.phone,
          onChanged: _onPhoneChanged,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.red),
          ),
        ],
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
