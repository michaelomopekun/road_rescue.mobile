import 'package:flutter/material.dart';
import 'package:road_rescue/shared/widgets/custom_text_field.dart';
import 'package:road_rescue/shared/widgets/primary_button.dart';
import 'package:road_rescue/theme/app_theme.dart';

class WorkshopInfoStepWidget extends StatefulWidget {
  final Function(String) onContinue;

  const WorkshopInfoStepWidget({super.key, required this.onContinue});

  @override
  State<WorkshopInfoStepWidget> createState() => _WorkshopInfoStepWidgetState();
}

class _WorkshopInfoStepWidgetState extends State<WorkshopInfoStepWidget> {
  final _workshopNameController = TextEditingController();

  @override
  void dispose() {
    _workshopNameController.dispose();
    super.dispose();
  }

  void _onContinue() {
    final workshopName = _workshopNameController.text.trim();
    if (workshopName.isEmpty) return;
    widget.onContinue(workshopName);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What's your workshop name?",
          style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
            fontSize: 40,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 32),
        CustomTextField(
          controller: _workshopNameController,
          hintText: 'Enter workshop name',
          keyboardType: TextInputType.text,
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
