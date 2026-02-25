import 'package:flutter/material.dart';
import 'package:road_rescue/features/auth/widgets/signup_steps/workshop_info_step_widget.dart';
import 'package:road_rescue/features/mechanic/verification/address_step_screen.dart';

class BusinessInfoScreen extends StatefulWidget {
  final String phoneNumber;

  const BusinessInfoScreen({super.key, required this.phoneNumber});

  @override
  State<BusinessInfoScreen> createState() => _BusinessInfoScreenState();
}

class _BusinessInfoScreenState extends State<BusinessInfoScreen> {
  late String _businessName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
            ),
            child: Icon(Icons.arrow_back, color: Colors.grey[700]),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: WorkshopInfoStepWidget(
          onContinue: (businessName) {
            _businessName = businessName;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddressStepScreen(
                  businessName: _businessName,
                  phoneNumber: widget.phoneNumber,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
