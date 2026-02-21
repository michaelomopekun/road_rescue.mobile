import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:road_rescue/features/auth/signup_flow_screen.dart';
import 'package:road_rescue/features/auth/widgets/role_button.dart';
import 'package:road_rescue/shared/widgets/custom_back_button.dart';
import 'package:road_rescue/theme/app_colors.dart';
import 'package:road_rescue/theme/app_theme.dart';

class RoleSelectionScreen extends StatefulWidget {
  final String email;

  const RoleSelectionScreen({super.key, required this.email});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  void _onRoleSelected(UserRole role) {
    // Navigate directly to SignupFlowScreen on role tap
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignupFlowScreen(role: role, email: widget.email),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: CustomBackButton(
                  borderColor: AppColors.backButtonBorder,
                  backgroundColor: AppColors.backButtonBackground,
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              const SizedBox(height: 146),

              // SVG Illustration
              SvgPicture.asset(
                'assets/svg/role_selection.svg',
                width: 376,
                height: 240,
              ),

              const SizedBox(height: 20),

              // Title
              Text(
                'Are you a Driver\nor a Mechanic?',
                textAlign: TextAlign.center,
                style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  fontSize: 30,
                ),
              ),

              const SizedBox(height: 117),

              // Driver Button - Tap to navigate
              RoleButton(
                label: 'Driver',
                isSelected: false,
                selectedColor: AppColors.primary,
                textColor: AppColors.background,
                onPressed: () => _onRoleSelected(UserRole.driver),
              ),

              const SizedBox(height: 16),

              // Mechanic Button - Tap to navigate
              RoleButton(
                label: 'Mechanic',
                isSelected: false,
                selectedColor: AppColors.lightSecondary,
                textColor: AppColors.textPrimary,
                onPressed: () => _onRoleSelected(UserRole.mechanic),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
