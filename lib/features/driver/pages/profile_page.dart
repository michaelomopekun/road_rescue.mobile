import 'package:flutter/material.dart';
import 'package:road_rescue/features/mechanic/widgets/dashboard_bottom_nav_bar.dart';
import 'package:road_rescue/theme/app_colors.dart';
import 'package:road_rescue/services/token_service.dart';
import 'package:road_rescue/services/auth_notifier.dart';

class DriverProfilePage extends StatefulWidget {
  const DriverProfilePage({super.key});

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  int _selectedNavIndex = 4;

  void _handleNavigation(int index) {
    if (index == _selectedNavIndex) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/driver');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/driver/wallet');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/driver/map');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/driver/history');
        break;
      case 4:
        break;
    }
  }

  Future<void> _logout() async {
    await TokenService.clearToken();
    authNotifier.notifyAuthStateChanged();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                children: [
                  const SizedBox(height: 24),
                  
                  // Avatar Section
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFDE68A), width: 4), // Golden ring
                          ),
                          child: const CircleAvatar(
                            radius: 48,
                            backgroundColor: Color(0xFFE2E8F0),
                            child: Icon(Icons.person, size: 48, color: Color(0xFF94A3B8)),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E4C4E),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.verified, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  const Center(
                    child: Text(
                      'Michael Scott',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDFEAF4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Premium Member',
                        style: TextStyle(
                          color: Color(0xFF5A789A), // Based on driver specific theme colors
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Menu Items
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: 'Personal Information',
                    iconBgColor: const Color(0xFFE0E7FF),
                    iconColor: const Color(0xFF4F46E5),
                  ),
                  _buildMenuItem(
                    icon: Icons.directions_car_outlined,
                    title: 'Vehicle Details',
                    subtitle: 'Toyota Corolla',
                    iconBgColor: const Color(0xFFDCFCE7),
                    iconColor: const Color(0xFF16A34A),
                  ),
                  _buildMenuItem(
                    icon: Icons.credit_card_outlined,
                    title: 'Payment Methods',
                    iconBgColor: const Color(0xFFF3E8FF),
                    iconColor: const Color(0xFF9333EA),
                  ),
                  _buildMenuItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notification Settings',
                    iconBgColor: const Color(0xFFFFF0E6),
                    iconColor: const Color(0xFFF97316),
                  ),
                  _buildMenuItem(
                    icon: Icons.headset_mic_outlined,
                    title: 'Help & Support',
                    iconBgColor: const Color(0xFFE0F2FE),
                    iconColor: const Color(0xFF0284C7),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Log Out Button
                  GestureDetector(
                    onTap: _logout,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE4E6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout, color: AppColors.error),
                          const SizedBox(width: 8),
                          const Text(
                            'Log Out',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  const Center(
                    child: Text(
                      'Version 2.4.0 (1293)',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DashboardBottomNavBar(
        selectedIndex: _selectedNavIndex,
        onTabChanged: _handleNavigation,
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
