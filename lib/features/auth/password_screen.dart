import 'package:flutter/material.dart';
import 'package:road_rescue/shared/helper/gradient_helper.dart';
import 'package:road_rescue/theme/app_theme.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/terms_and_privacy_text.dart';

class PasswordScreen extends StatefulWidget {
  final String email;

  const PasswordScreen({super.key, required this.email});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _onContinue() {
    // TODO: Handle password login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // App Logo
              const AppLogo(),

              const SizedBox(height: 24),

              // Title
              Text(
                'Password',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),

              const SizedBox(height: 40),

              // Email display (read-only)
              CustomTextField(
                controller: TextEditingController(text: widget.email),
                hintText: '',
                enabled: false,
              ),

              const SizedBox(height: 16),

              // Password Input Field
              CustomTextField(
                controller: _passwordController,
                hintText: 'Enter your password',
                obscureText: true,
              ),

              const SizedBox(height: 20),

              // Continue Button
              PrimaryButton(text: 'Continue', onPressed: _onContinue),

              const Spacer(flex: 3),

              // Terms and Privacy
              const TermsAndPrivacyText(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
