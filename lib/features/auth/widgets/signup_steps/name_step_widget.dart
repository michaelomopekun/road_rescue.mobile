import 'package:flutter/material.dart';
import 'package:road_rescue/shared/widgets/custom_text_field.dart';
import 'package:road_rescue/shared/widgets/primary_button.dart';
import 'package:road_rescue/shared/utils/validators.dart';

class NameStepWidget extends StatefulWidget {
  final String email;
  final Function(String) onContinue;

  const NameStepWidget({
    super.key,
    required this.email,
    required this.onContinue,
  });

  @override
  State<NameStepWidget> createState() => _NameStepWidgetState();
}

class _NameStepWidgetState extends State<NameStepWidget> {
  final _nameController = TextEditingController();
  String? _errorMessage;
  bool _isNameValid = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    setState(() {
      _errorMessage = Validators.validateName(value);
      _isNameValid = _errorMessage == null && value.isNotEmpty;
    });
  }

  void _onContinue() {
    final fullName = _nameController.text.trim();
    final validationError = Validators.validateName(fullName);

    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
      });
      return;
    }

    widget.onContinue(fullName);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What's your full name?",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 32),
        CustomTextField(
          controller: _nameController,
          hintText: 'Enter your full name',
          keyboardType: TextInputType.name,
          onChanged: _onNameChanged,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.red),
          ),
        ] else if (_isNameValid) ...[
          const SizedBox(height: 8),
          Text(
            '✓ Name is valid',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.green),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: 'Continue',
            onPressed: _isNameValid ? _onContinue : null,
            text: 'Continue',
          ),
        ),
      ],
    );
  }
}
