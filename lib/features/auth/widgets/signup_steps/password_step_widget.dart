import 'package:flutter/material.dart';
import 'package:road_rescue/shared/widgets/custom_text_field.dart';
import 'package:road_rescue/shared/widgets/primary_button.dart';

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

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _onContinue() {
    final password = _passwordController.text.trim();
    if (password.isEmpty) return;
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
          hintText: 'Enter password',
          obscureText: _obscureText,
          suffixIcon: IconButton(
            icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          ),
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
