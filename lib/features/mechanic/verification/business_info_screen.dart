import 'package:flutter/material.dart';
import 'package:road_rescue/features/auth/widgets/signup_steps/workshop_info_step_widget.dart';
import 'package:road_rescue/features/mechanic/verification/address_step_screen.dart';
import 'package:road_rescue/shared/widgets/custom_back_button.dart';

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
        leading: CustomBackButton(onPressed: () => Navigator.of(context).pop()),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Indicator (Step 1/3)
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
                        color: index == 0 ? Colors.teal[700] : Colors.grey[300],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            WorkshopInfoStepWidget(
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
          ],
        ),
      ),
    );
  }
}
