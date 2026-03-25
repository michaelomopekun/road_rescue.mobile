import 'package:flutter/material.dart';
import 'package:road_rescue/features/mechanic/widgets/dashboard_bottom_nav_bar.dart';
import 'package:road_rescue/features/mechanic/widgets/edit_workshop_bottom_sheet.dart';
import 'package:road_rescue/services/token_service.dart';
import 'package:road_rescue/services/toast_service.dart';
import 'package:road_rescue/services/mechanic_service.dart';
import 'package:road_rescue/services/auth_service.dart';
import 'package:road_rescue/theme/app_colors.dart';

class MechanicProfilePage extends StatefulWidget {
  const MechanicProfilePage({super.key});

  @override
  State<MechanicProfilePage> createState() => _MechanicProfilePageState();
}

class _MechanicProfilePageState extends State<MechanicProfilePage> {
  int _selectedNavIndex = 4;
  ProviderProfile? _providerProfile;
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        MechanicService.getProviderProfile(),
        AuthService.getUserProfile(),
      ]);
      if (mounted) {
        setState(() {
          _providerProfile = futures[0] as ProviderProfile;
          _userProfile = futures[1] as UserProfile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ToastService.showError(context, 'Failed to load profile');
      }
    }
  }

  Future<void> _editProfile() async {
    if (_providerProfile == null) return;

    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) =>
          EditWorkshopBottomSheet(providerProfile: _providerProfile!),
    );

    if (result != null && mounted) {
      setState(() => _isLoading = true);
      try {
        await MechanicService.updateProviderProfile(
          businessName: result['businessName']!,
          businessPhone: result['businessPhone']!,
          businessAddress: result['businessAddress']!,
        );
        if (mounted) {
          ToastService.showSuccess(context, 'Workshop Details updated');
          _loadProfileData();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ToastService.showError(context, 'Update failed: $e');
        }
      }
    }
  }

  Future<void> _editPersonalInfo() async {
    if (_userProfile == null) return;

    final nameController = TextEditingController(text: _userProfile!.fullname);
    final phoneController = TextEditingController(text: _userProfile!.phone);
    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2A3B),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context, true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save Details'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() => _isLoading = true);
      try {
        await AuthService.updateUserProfile(
          fullname: nameController.text.trim(),
          phone: phoneController.text.trim(),
          plateNumber: _userProfile!.plateNumber,
        );
        if (mounted) {
          ToastService.showSuccess(context, 'Personal Info updated');
          _loadProfileData();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ToastService.showError(context, 'Update failed: $e');
        }
      }
    }
  }

  void _handleNavigation(int index) {
    setState(() {
      _selectedNavIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/mechanic');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/mechanic/wallet');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/mechanic/map');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/mechanic/history');
        break;
      case 4:
        // Already on Profile
        break;
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      ToastService.showSuccess(context, 'Logged out successfully');
      await TokenService.clearAuthData();
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.of(context).pushReplacementNamed('/login');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF2F9FA);
    const textColor = Color(0xFF1B2A3B);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            pinned: true,
            expandedHeight: 330, // Adjusted height to match design
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border, width: 2),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    // Profile Image with Verification Badge
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFEDB882),
                                border: Border.all(
                                  color: const Color(0xFFF2F9FA),
                                  width: 4,
                                ),
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 80,
                                color: const Color(0xFFDCA776),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C8D9),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else ...[
                      Text(
                        _providerProfile?.businessName.isNotEmpty == true
                            ? _providerProfile!.businessName
                            : 'Workshop Provider',
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _providerProfile?.providerType.replaceAll('_', ' ') ??
                            'Provider',
                        style: const TextStyle(
                          color: Color(0xFFAAB8C2),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_providerProfile?.businessPhone.isNotEmpty ==
                          true) ...[
                        const SizedBox(height: 4),
                        Text(
                          _providerProfile!.businessPhone,
                          style: const TextStyle(
                            color: Color(0xFFAAB8C2),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Primary Actions Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border, width: 2),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSettingsRow(
                          icon: Icons.person_outline,
                          iconColor: const Color(0xFF3282B8),
                          iconBgColor: const Color(0xFFF0F6FA),
                          title: 'Personal Information',
                          onTap: _editPersonalInfo,
                        ),
                        _buildDivider(),
                        _buildSettingsRow(
                          icon: Icons.business,
                          iconColor: const Color(0xFFE87A4F),
                          iconBgColor: const Color(0xFFFDF2ED),
                          title: 'Workshop Details',
                          onTap: _editProfile,
                        ),
                        _buildDivider(),
                        // _buildSettingsRow(
                        //   icon: Icons.credit_card,
                        //   iconColor: const Color(0xFF2EB774),
                        //   iconBgColor: const Color(0xFFEBF7F1),
                        //   title: 'Payout Methods',
                        // ),
                        // _buildDivider(),
                        // _buildSettingsRow(
                        //   icon: Icons.badge_outlined,
                        //   iconColor: const Color(0xFF9B51E0),
                        //   iconBgColor: const Color(0xFFF5EEFC),
                        //   title: 'Documents & Verification',
                        // ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Secondary Actions Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border, width: 2),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSettingsRow(
                          icon: Icons.notifications_none_outlined,
                          iconColor: const Color(0xFF5A6B7C),
                          iconBgColor: const Color(0xFFF2F4F7),
                          title: 'Notifications',
                        ),
                        _buildDivider(),
                        _buildSettingsRow(
                          icon: Icons.help_outline,
                          iconColor: const Color(0xFF5A6B7C),
                          iconBgColor: const Color(0xFFF2F4F7),
                          title: 'Help & Support',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Color(0xFFE55858)),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Color(0xFFE55858),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFFDECEC)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App Version
                  const Text(
                    'RoadRescue Mechanic App v2.4.0',
                    style: TextStyle(
                      color: Color(0xFFAAB8C2),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: DashboardBottomNavBar(
        selectedIndex: _selectedNavIndex,
        onTabChanged: _handleNavigation,
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1B2A3B),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFCDD6DD), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 76, right: 20),
      color: const Color(0xFFF2F4F7),
    );
  }
}
