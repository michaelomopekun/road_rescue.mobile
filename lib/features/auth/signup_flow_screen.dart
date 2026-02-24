import 'package:flutter/material.dart';
import 'package:road_rescue/features/auth/widgets/signup_steps/phone_step_widget.dart';
import 'package:road_rescue/features/auth/widgets/signup_steps/otp_step_widget.dart';
import 'package:road_rescue/features/auth/widgets/signup_steps/password_step_widget.dart';
import 'package:road_rescue/features/mechanic/mechanic_locked_dashboard.dart';
import 'package:road_rescue/services/auth_service.dart';
import 'package:road_rescue/services/api_client.dart';
import 'package:road_rescue/shared/widgets/custom_back_button.dart';
import 'package:road_rescue/theme/app_colors.dart';

enum SignupStep { phone, otp, password }

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
  bool _isLoading = false;

  // Form data
  late Map<String, dynamic> formData;

  @override
  void initState() {
    super.initState();
    _initializeSteps();
    formData = {
      'email': widget.email,
      // 'fullName': '',
      'phoneNumber': '',
      'otp': '',
      // 'workshopName': '',
      // 'workshopLocation': null,
      'password': '',
    };
  }

  void _initializeSteps() {
    // Dynamic step configuration based on role
    if (widget.role == UserRole.driver) {
      steps = [
        // SignupStep.name,
        SignupStep.phone,
        SignupStep.otp,
        SignupStep.password,
      ];
    } else if (widget.role == UserRole.mechanic) {
      steps = [
        // SignupStep.name,
        SignupStep.phone,
        SignupStep.otp,
        // SignupStep.workshopInfo,
        // SignupStep.address,
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
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final roleString = widget.role == UserRole.driver ? 'DRIVER' : 'PROVIDER';

      // Call register API
      await AuthService.register(
        email: formData['email'] as String,
        password: formData['password'] as String,
        phone: formData['phoneNumber'] as String,
        role: roleString,
      );

      if (!mounted) return;

      if (widget.role == UserRole.driver) {
        // Navigate to Driver Dashboard
        Navigator.pushReplacementNamed(context, '/driver-dashboard');
      } else if (widget.role == UserRole.mechanic) {
        // Navigate to Mechanic Locked Dashboard with signup data
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MechanicLockedDashboard(
              email: formData['email'] as String,
              phoneNumber: formData['phoneNumber'] as String,
            ),
          ),
        );
      }
    } on ValidationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.errors.join(', '))));
      setState(() {
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed. Please try again.')),
      );
      setState(() {
        _isLoading = false;
      });
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
                onPressed: () => _onBack(),
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

      // case SignupStep.workshopInfo:
      //   return WorkshopInfoStepWidget(
      //     onContinue: (workshopName) {
      //       _updateFormData('workshopName', workshopName);
      //       _onContinue();
      //     },
      //   );

      // case SignupStep.address:
      //   return AddressStepWidget(
      //     onContinue: (workshopLocation) {
      //       _updateFormData('workshopLocation', workshopLocation);
      //       _onContinue();
      //     },
      //   );

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
