import 'package:flutter/material.dart';
import 'package:road_rescue/features/auth/widgets/signup_steps/address_step_widget.dart';
import 'package:road_rescue/features/mechanic/verification/document_upload_screen.dart';
import 'package:road_rescue/shared/widgets/custom_back_button.dart';

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
        leading: CustomBackButton(onPressed: () => Navigator.of(context).pop()),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Indicator (Step 2/3)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: index < 1 ? Colors.teal[700] : Colors.grey[300],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AddressStepWidget(
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
          ],
        ),
      ),
    );
  }
}
