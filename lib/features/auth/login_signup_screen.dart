import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:road_rescue/features/auth/password_screen.dart';
import 'package:road_rescue/features/auth/role_selection_screen.dart';
import 'package:road_rescue/features/auth/widgets/oauth_buttons.dart';
import 'package:road_rescue/features/auth/widgets/or_divider.dart';
import 'package:road_rescue/services/api_client.dart';
import 'package:road_rescue/services/auth_service.dart';
import 'package:road_rescue/shared/helper/gradient_helper.dart';
import 'package:road_rescue/shared/widgets/app_logo.dart';
import 'package:road_rescue/shared/widgets/custom_text_field.dart';
import 'package:road_rescue/shared/widgets/primary_button.dart';
import 'package:road_rescue/shared/widgets/terms_and_privacy_text.dart';
import 'package:road_rescue/shared/utils/validators.dart';
import 'package:road_rescue/theme/app_theme.dart';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  final _emailController = TextEditingController();
  String? _errorMessage;
  bool _isEmailValid = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onEmailChanged(String value) {
    setState(() {
      _errorMessage = Validators.validateEmail(value);
      _isEmailValid = _errorMessage == null && value.isNotEmpty;
    });
  }

  void _onContinue() async {
    final email = _emailController.text.trim();
    final validationError = Validators.validateEmail(email);

    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
        _isEmailValid = false;
      });
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if email already exists
      final emailExists = await AuthService.checkEmailExists(email);

      if (!mounted) return;

      if (emailExists.exists) {
        String role = emailExists.role ?? '';

        // Existing user → navigate to Password screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PasswordScreen(email: email, role: role),
          ),
        );
      } else {
        // New user → navigate to Role Selection
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RoleSelectionScreen(email: email)),
        );
      }
    } on ValidationException catch (e) {
      setState(() {
        _errorMessage = e.errors.join(', ');
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });
    }
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
              const SizedBox(height: 190),

              // App Logo
              const AppLogo(size: 64),

              const SizedBox(height: 40),

              // Title
              Text(
                'Log in or sign up',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),

              const SizedBox(height: 32),

              // Email Input
              CustomTextField(
                controller: _emailController,
                hintText: 'example@gmail.com',
                keyboardType: TextInputType.emailAddress,
                onChanged: _onEmailChanged,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.red),
                ),
              ] else if (_isEmailValid) ...[
                const SizedBox(height: 8),
                Text(
                  '✓ Email is valid',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.green),
                ),
              ],

              const SizedBox(height: 16),

              // Continue Button
              PrimaryButton(
                text: 'Continue',
                onPressed: _isEmailValid && !_isLoading ? _onContinue : null,
                label: '',
                isLoading: _isLoading,
              ),

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

              const SizedBox(height: 48),

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
