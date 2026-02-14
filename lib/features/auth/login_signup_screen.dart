import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:road_rescue/features/auth/widgets/oauth_buttons.dart';
import 'package:road_rescue/features/auth/widgets/or_divider.dart';
import 'package:road_rescue/shared/helper/gradient_helper.dart';
import 'package:road_rescue/shared/widgets/app_logo.dart';
import 'package:road_rescue/shared/widgets/custom_text_field.dart';
import 'package:road_rescue/shared/widgets/primary_button.dart';
import 'package:road_rescue/shared/widgets/terms_and_privacy_text.dart';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onContinue() {
    // TODO: handle email continue action...
  }

  void _onGoogleSignIn() {
    // TODO: handle Google sign in action...
  }

  void _onAppleSignIn() {
    // TODO: handle Apple sign in action...
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 80),

              // App Logo
              const AppLogo(size: 64),

              const SizedBox(height: 32),

              // Title
              const Text(
                'Log in or sign up',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 40),

              // Email Input
              CustomTextField(
                controller: _emailController,
                hintText: 'jsmith.mobbin1@gmail.com',
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              // Continue Button
              PrimaryButton(text: 'Continue', onPressed: _onContinue),

              const SizedBox(height: 32),

              // Or Divider
              const OrDivider(),

              const SizedBox(height: 32),

              // Google Sign In
              OauthButtons(
                label: 'Continue with Google',
                icon: SvgPicture.asset(
                  'assets/svg/google_logo.svg',
                  width: 24,
                  height: 24,
                ),
                onPressed: _onGoogleSignIn,
              ),

              const SizedBox(height: 16),

              // Apple Sign In
              OauthButtons(
                label: 'Continue with Apple',
                icon: const Icon(Icons.apple, size: 24, color: Colors.black),
                onPressed: _onAppleSignIn,
              ),
              const SizedBox(height: 40),

              // Terms & Privacy
              TermsAndPrivacyText(
                onTermsTap: () {
                  // TODO: Open Terms of Service
                },
                onPrivacyTap: () {
                  // TODO: Open Privacy Policy
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
