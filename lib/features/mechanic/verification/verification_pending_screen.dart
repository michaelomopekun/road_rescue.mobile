import 'package:flutter/material.dart';
import 'package:road_rescue/shared/widgets/primary_button.dart';
import 'package:road_rescue/shared/widgets/custom_back_button.dart';

class VerificationPendingScreen extends StatelessWidget {
  final String? serviceProviderId;

  const VerificationPendingScreen({super.key, this.serviceProviderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: CustomBackButton(
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed('/mechanic-dashboard'),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // const SizedBox(height: 83),

              // Hourglass Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue[100],
                ),
                child: Icon(
                  Icons.hourglass_bottom,
                  size: 60,
                  color: Colors.blue[600],
                ),
              ),

              const SizedBox(height: 40),

              // Verification Pending Title
              Text(
                'Verification\nPending',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 46),

              // Explanation Text
              Text(
                'Our team is reviewing your\ndocuments. This usually takes 24-\n48 hours. We\'ll notify you once\nyour account is ready.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 188),

              // Back to Home Button
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Back to Home',
                  text: 'Back to Home',
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushReplacementNamed('/mechanic-dashboard');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
