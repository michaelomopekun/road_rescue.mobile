import 'package:flutter/material.dart';
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
  bool _obscureText = true;
  String? _errorMessage;
  bool _isPasswordValid = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged(String value) {
    setState(() {
      // For login, we do basic validation (non-empty)
      if (value.isEmpty) {
        _errorMessage = null;
        _isPasswordValid = false;
      } else {
        _errorMessage = null;
        _isPasswordValid = true;
      }
    });
  }

  void _onContinue() {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Password is required';
        _isPasswordValid = false;
      });
      return;
    }
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
                obscureText: _obscureText,
                onChanged: _onPasswordChanged,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.red),
                ),
              ],

              const SizedBox(height: 20),

              // Continue Button
              PrimaryButton(
                text: 'Continue',
                onPressed: _isPasswordValid ? _onContinue : null,
                label: '',
              ),

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
