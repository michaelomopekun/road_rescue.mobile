import 'package:flutter/material.dart';
import 'package:road_rescue/shared/widgets/custom_text_field.dart';
import 'package:road_rescue/shared/widgets/primary_button.dart';
import 'package:road_rescue/theme/app_theme.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onContinue() {
    final fullName = _nameController.text.trim();
    if (fullName.isEmpty) return;
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
