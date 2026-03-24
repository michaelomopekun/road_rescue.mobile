import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:road_rescue/shared/widgets/primary_button.dart';
import 'package:road_rescue/theme/app_colors.dart';

class PlateNumberStepWidget extends StatefulWidget {
  final Function(String) onContinue;

  const PlateNumberStepWidget({super.key, required this.onContinue});

  @override
  State<PlateNumberStepWidget> createState() => _PlateNumberStepWidgetState();
}

class _PlateNumberStepWidgetState extends State<PlateNumberStepWidget> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _plateControllers;
  final int _plateLength = 8;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(_plateLength, (_) => FocusNode());
    _plateControllers = List.generate(
      _plateLength,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (var controller in _plateControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onPlateChange(int index, String value) {
    if (value.isNotEmpty) {
      // Convert to uppercase
      value = value.toUpperCase();
      // Only allow alphanumeric
      if (!RegExp(r'[A-Z0-9]').hasMatch(value)) {
        _plateControllers[index].clear();
        return;
      } else {
        _plateControllers[index].text = value;
      }
    }

    // Clear error when user starts typing
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }

    if (value.length == 1 && index < _plateLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _onContinue() {
    final plate = _plateControllers.map((c) => c.text).join();
    if (plate.length < 6) {
      setState(() {
        _errorMessage = 'Please enter a valid plate number';
      });
      return;
    }
    widget.onContinue(plate);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter your vehicle plate number',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            _plateLength,
            (index) => Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: TextField(
                  controller: _plateControllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  ],
                  maxLength: 1,
                  onChanged: (value) => _onPlateChange(index, value),
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _errorMessage != null
                            ? AppColors.error
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _errorMessage != null
                            ? AppColors.error
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _errorMessage != null
                            ? AppColors.error
                            : AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: 32),
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
