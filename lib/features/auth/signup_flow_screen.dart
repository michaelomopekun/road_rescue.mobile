import 'package:flutter/material.dart';
import 'package:road_rescue/features/auth/widgets/signup_steps/name_step_widget.dart';
import 'package:road_rescue/features/auth/widgets/signup_steps/phone_step_widget.dart';
import 'package:road_rescue/features/auth/widgets/signup_steps/otp_step_widget.dart';
import 'package:road_rescue/features/auth/widgets/signup_steps/password_step_widget.dart';
import 'package:road_rescue/shared/widgets/custom_back_button.dart';
import 'package:road_rescue/theme/app_colors.dart';

enum SignupStep { name, phone, otp, password }

enum UserRole { driver, mechanic }

class SignupFlowScreen extends StatefulWidget {
  final UserRole role;
  final String email;

  const SignupFlowScreen({super.key, required this.role, required this.email});

  @override
  State<SignupFlowScreen> createState() => _SignupFlowScreenState();
}

class _SignupFlowScreenState extends State<SignupFlowScreen> {
  late List<SignupStep> steps;
  int currentStepIndex = 0;

  // Form data
  late Map<String, dynamic> formData;

  @override
  void initState() {
    super.initState();
    _initializeSteps();
    formData = {
      'email': widget.email,
      'fullName': '',
      'phoneNumber': '',
      'otp': '',
      'password': '',
    };
  }

  void _initializeSteps() {
    // Dynamic step configuration based on role
    if (widget.role == UserRole.driver) {
      steps = [
        SignupStep.name,
        SignupStep.phone,
        SignupStep.otp,
        SignupStep.password,
      ];
    } else if (widget.role == UserRole.mechanic) {
      // TODO: Add mechanic-specific steps later
      steps = [
        SignupStep.name,
        SignupStep.phone,
        SignupStep.otp,
        SignupStep.password,
      ];
    }
  }

  void _onContinue() {
    if (currentStepIndex < steps.length - 1) {
      setState(() {
        currentStepIndex++;
      });
    } else {
      _completeSignup();
    }
  }

  void _onBack() {
    if (currentStepIndex > 0) {
      setState(() {
        currentStepIndex--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _completeSignup() async {
    // TODO: Submit signup data to backend
    // POST /signup with role, email, fullName, phoneNumber, otp, password

    if (!mounted) return;

    if (widget.role == UserRole.driver) {
      // Navigate to Driver Dashboard
      // TODO: Replace with actual DriverDashboard route
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Driver signup completed!')));
      Navigator.pushReplacementNamed(context, '/driver-dashboard');
    } else if (widget.role == UserRole.mechanic) {
      // Navigate to Mechanic Locked Dashboard (Verification Pending)
      // TODO: Replace with actual MechanicLockedDashboard route
      Navigator.pushReplacementNamed(context, '/mechanic-locked-dashboard');
    }
  }

  void _updateFormData(String key, dynamic value) {
    formData[key] = value;
  }

  @override
  Widget build(BuildContext context) {
    SignupStep currentStep = steps[currentStepIndex];
    int progressPercentage = ((currentStepIndex + 1) / steps.length * 100)
        .toInt();

    return Scaffold(
      // appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: CustomBackButton(
                borderColor: AppColors.backButtonBorder,
                backgroundColor: AppColors.backButtonBackground,
                onPressed: () => Navigator.pop(context),
              ),
            ),

            const SizedBox(height: 48),

            // Progress indicator
            LinearProgressIndicator(
              value: progressPercentage / 100,
              minHeight: 4,
              backgroundColor: Colors.grey[300],
            ),

            const SizedBox(height: 134),

            // Step content
            _buildStepContent(currentStep),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(SignupStep step) {
    switch (step) {
      case SignupStep.name:
        return NameStepWidget(
          email: widget.email,
          onContinue: (fullName) {
            _updateFormData('fullName', fullName);
            _onContinue();
          },
        );

      case SignupStep.phone:
        return PhoneStepWidget(
          onContinue: (phoneNumber) {
            _updateFormData('phoneNumber', phoneNumber);
            _onContinue();
          },
        );

      case SignupStep.otp:
        return OtpStepWidget(
          phoneNumber: formData['phoneNumber'] as String,
          onContinue: (otp) {
            _updateFormData('otp', otp);
            _onContinue();
          },
        );

      case SignupStep.password:
        return PasswordStepWidget(
          email: widget.email,
          onContinue: (password) {
            _updateFormData('password', password);
            _onContinue();
          },
        );
    }
  }
}
