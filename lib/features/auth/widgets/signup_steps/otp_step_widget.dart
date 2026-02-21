import 'package:flutter/material.dart';
import 'package:road_rescue/shared/widgets/primary_button.dart';

class OtpStepWidget extends StatefulWidget {
  final String phoneNumber;
  final Function(String) onContinue;

  const OtpStepWidget({
    super.key,
    required this.phoneNumber,
    required this.onContinue,
  });

  @override
  State<OtpStepWidget> createState() => _OtpStepWidgetState();
}

class _OtpStepWidgetState extends State<OtpStepWidget> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _otpControllers;
  final int _otpLength = 4;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
    _otpControllers = List.generate(_otpLength, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onOtpChange(int index, String value) {
    if (value.length == 1 && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _onContinue() {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length == _otpLength) {
      widget.onContinue(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'We just sent an SMS, enter code',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            _otpLength,
            (index) => SizedBox(
              width: 60,
              height: 60,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                onChanged: (value) => _onOtpChange(index, value),
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Resend · 00:56',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: 'Continue',
            onPressed: _onContinue,
            text: '',
          ),
        ),
      ],
    );
  }
}
