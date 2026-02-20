import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:road_rescue/features/auth/widgets/role_button.dart';
import 'package:road_rescue/shared/helper/gradient_helper.dart';
import 'package:road_rescue/shared/widgets/custom_back_button.dart';
import 'package:road_rescue/shared/widgets/primary_button.dart';
import 'package:road_rescue/theme/app_colors.dart';
import 'package:road_rescue/theme/app_theme.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole; // 'driver' or 'mechanic'

  void _onRoleSelected(String role) {
    setState(() => _selectedRole = role);
  }

  void _onContinue() {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a role')));
      return;
    }

    // TODO: Handle role selection and navigate to next screen
    // Example: Navigator.push(context, MaterialPageRoute(...))
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

              // Driver Button
              RoleButton(
                label: 'Driver',
                isSelected: _selectedRole == 'driver',
                selectedColor: AppColors.primary,
                textColor: AppColors.background,
                onPressed: () => _onRoleSelected('driver'),
              ),

              const SizedBox(height: 16),

              // Mechanic Button
              RoleButton(
                label: 'Mechanic',
                isSelected: _selectedRole == 'mechanic',
                selectedColor: AppColors.lightSecondary,
                textColor: AppColors.textPrimary,
                onPressed: () => _onRoleSelected('mechanic'),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
