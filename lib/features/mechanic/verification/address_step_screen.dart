import 'package:flutter/material.dart';
import 'package:road_rescue/features/auth/widgets/signup_steps/address_step_widget.dart';
import 'package:road_rescue/features/mechanic/verification/document_upload_screen.dart';

class AddressStepScreen extends StatefulWidget {
  final String businessName;
  final String phoneNumber;

  const AddressStepScreen({
    super.key,
    required this.businessName,
    required this.phoneNumber,
  });

  @override
  State<AddressStepScreen> createState() => _AddressStepScreenState();
}

class _AddressStepScreenState extends State<AddressStepScreen> {
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
        child: AddressStepWidget(
          onContinue: (workshopLocation) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DocumentUploadScreen(
                  businessName: widget.businessName,
                  workshopLocation: workshopLocation,
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
