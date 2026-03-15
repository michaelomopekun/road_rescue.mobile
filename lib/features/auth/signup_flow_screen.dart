import 'package:flutter/material.dart';
import 'package:road_rescue/features/auth/widgets/signup_steps/name_step_widget.dart';
import 'package:road_rescue/features/auth/widgets/signup_steps/phone_step_widget.dart';
import 'package:road_rescue/features/auth/widgets/signup_steps/otp_step_widget.dart';
import 'package:road_rescue/features/auth/widgets/signup_steps/password_step_widget.dart';
import 'package:road_rescue/services/auth_service.dart';
import 'package:road_rescue/services/exceptions.dart';
import 'package:road_rescue/services/toast_service.dart';
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
      // 'workshopName': '',
      // 'workshopLocation': null,
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
      steps = [
        SignupStep.name,
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

    try {
      final roleString = widget.role == UserRole.driver ? 'DRIVER' : 'PROVIDER';

      // Call register API
      await AuthService.register(
        fullName: formData['fullName'] as String,
        email: formData['email'] as String,
        password: formData['password'] as String,
        phone: formData['phoneNumber'] as String,
        role: roleString,
      );

      // Auto-login after registration to persist token and user data
      // login() also calls authNotifier.notifyAuthStateChanged() which updates
      // main.dart's home widget, but since signup screens are pushed on top
      // of the nav stack, we still need manual navigation to clear them.
      await AuthService.login(
        email: formData['email'] as String,
        password: formData['password'] as String,
      );

      if (!mounted) return;

      // Show success toast before navigating
      ToastService.showSuccess(context, 'Registration successful! Welcome aboard.');

      if (widget.role == UserRole.driver) {
        // Clear the entire nav stack and go to Driver Dashboard
        Navigator.pushNamedAndRemoveUntil(context, '/driver', (route) => false);
      } else if (widget.role == UserRole.mechanic) {
        // Clear the entire nav stack and go to Mechanic Locked Dashboard
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/mechanic-dashboard',
          (route) => false,
          arguments: {
            'email': formData['email'] as String,
            'phoneNumber': formData['phoneNumber'] as String,
          },
        );
      }
    } on ValidationException catch (e) {
      if (!mounted) return;
      ToastService.showError(context, e.messages.join(', '));
    } on ApiException catch (e) {
      if (!mounted) return;
      ToastService.showError(context, e.message);
    } catch (e) {
      debugPrint('[SignupFlow] Registration error: $e');
      if (!mounted) return;
      ToastService.showError(context, 'Registration failed. Please try again.');
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
      case SignupStep.name:
        return NameStepWidget(
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
