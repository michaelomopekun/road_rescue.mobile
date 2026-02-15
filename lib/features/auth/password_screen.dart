import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:road_rescue/shared/helper/gradient_helper.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/terms_and_privacy_text.dart';
import '../../theme/app_colors.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

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
    // TODO: Handle password submission
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
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
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 40),

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
      ),
    );
  }
}
