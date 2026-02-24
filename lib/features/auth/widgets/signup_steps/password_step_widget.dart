import 'package:flutter/material.dart';
import 'package:road_rescue/shared/widgets/custom_text_field.dart';
import 'package:road_rescue/shared/widgets/primary_button.dart';
import 'package:road_rescue/shared/utils/validators.dart';

class PasswordStepWidget extends StatefulWidget {
  final String email;
  final Function(String) onContinue;

  const PasswordStepWidget({
    super.key,
    required this.email,
    required this.onContinue,
  });

  @override
  State<PasswordStepWidget> createState() => _PasswordStepWidgetState();
}

class _PasswordStepWidgetState extends State<PasswordStepWidget> {
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  String? _errorMessage;
  bool _isPasswordValid = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged(String value) {
    setState(() {
      _errorMessage = Validators.validatePasswordSimple(value);
      _isPasswordValid = _errorMessage == null && value.isNotEmpty;
    });
  }

  void _onContinue() {
    final password = _passwordController.text.trim();
    final validationError = Validators.validatePasswordSimple(password);

    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
      });
      return;
    }

    widget.onContinue(password);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Password', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 32),
        CustomTextField(
          controller: _passwordController,
          hintText: 'Enter password (min 8 characters)',
          obscureText: _obscureText,
          onChanged: _onPasswordChanged,
          suffixIcon: IconButton(
            icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.red),
          ),
        ] else if (_isPasswordValid) ...[
          const SizedBox(height: 8),
          Text(
            '✓ Password is valid',
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
            onPressed: _isPasswordValid ? _onContinue : null,
            text: 'Continue',
          ),
        ),
      ],
    );
  }
}
