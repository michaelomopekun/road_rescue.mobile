import 'package:flutter/material.dart';
import 'package:road_rescue/features/mechanic/widgets/dashboard_bottom_nav_bar.dart';
import 'package:road_rescue/theme/app_colors.dart';

class DriverWalletPage extends StatefulWidget {
  const DriverWalletPage({super.key});

  @override
  State<DriverWalletPage> createState() => _DriverWalletPageState();
}

class _DriverWalletPageState extends State<DriverWalletPage> {
  int _selectedNavIndex = 1;

  void _handleNavigation(int index) {
    if (index == _selectedNavIndex) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/driver');
        break;
      case 1:
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/driver/map');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/driver/history');
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed('/driver/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wallet',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your payments & credits',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.more_horiz, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            
            // Balance Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E4C4E), // Dark Green/Teal
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 16),
                                const SizedBox(width: 8),
                                const Text(
                                  'Total Balance',
                                  style: TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '\$124.50',
                              style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.add_card, color: Color(0xFF1E4C4E), size: 18),
                            label: const Text('Top Up', style: TextStyle(color: Color(0xFF1E4C4E), fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.credit_card, color: Colors.white, size: 18),
                            label: const Text('Cards', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24, width: 1),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Payment Method
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(4)),
                      child: const Text('VISA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Visa ending in 4242', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text('Default method', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Payment History Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const Icon(Icons.tune, color: AppColors.textSecondary, size: 20),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Payment List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildTransactionItem(
                    title: 'Alex Mechanic',
                    subtitle: 'Tire Change • Yesterday',
                    amount: '-\$45.00',
                    status: 'Wallet',
                    icon: Icons.person,
                    isPositive: false,
                    isWalletTopUp: false,
                    bgColor: const Color(0xFF1E4C4E),
                  ),
                  _buildTransactionItem(
                    title: 'Wallet Top Up',
                    subtitle: 'Credit Card • Oct 10',
                    amount: '+\$100.00',
                    status: 'Success',
                    icon: Icons.account_balance_wallet,
                    isPositive: true,
                    isWalletTopUp: true,
                    bgColor: const Color(0xFF10B981),
                  ),
                  _buildTransactionItem(
                    title: 'Sam Repairs',
                    subtitle: 'Battery Jump • Oct 05',
                    amount: '-\$35.00',
                    status: 'Wallet',
                    icon: Icons.person,
                    isPositive: false,
                    isWalletTopUp: false,
                    bgColor: const Color(0xFFFDE68A),
                  ),
                  _buildTransactionItem(
                    title: 'Mike\'s Towing',
                    subtitle: 'Towing Service • Sep 28',
                    amount: '-\$120.00',
                    status: 'Visa ••4242',
                    icon: Icons.person,
                    isPositive: false,
                    isWalletTopUp: false,
                    bgColor: const Color(0xFFE2E8F0),
                  ),
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

  Widget _buildTransactionItem({
    required String title,
    required String subtitle,
    required String amount,
    required String status,
    required IconData icon,
    required bool isPositive,
    required bool isWalletTopUp,
    required Color bgColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
                child: isWalletTopUp
                    ? const Center(child: Text('RR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))
                    : const Icon(Icons.person, color: Colors.white70),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: const Color(0xFF1E4C4E), shape: BoxShape.circle),
                    child: Icon(isWalletTopUp ? Icons.add : Icons.build, size: 10, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isPositive ? AppColors.success : AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(status, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }
}
