import 'package:flutter/material.dart';
import 'package:road_rescue/features/mechanic/widgets/dashboard_bottom_nav_bar.dart';

class Transaction {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final bool isCredit;
  final IconData icon;

  Transaction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isCredit,
    required this.icon,
  });
}

class MechanicWalletPage extends StatefulWidget {
  const MechanicWalletPage({super.key});

  @override
  State<MechanicWalletPage> createState() => _MechanicWalletPageState();
}

class _MechanicWalletPageState extends State<MechanicWalletPage> {
  int _selectedNavIndex = 1;

  // Mock transactions based on the design
  final List<Transaction> _mockTransactions = [
    Transaction(
      id: '1',
      title: 'Job Payout - Sarah Jenkins',
      subtitle: 'Today, 2:30 PM',
      amount: 85.00,
      isCredit: true,
      icon: Icons.handyman,
    ),
    Transaction(
      id: '2',
      title: 'Withdrawal to Chase Bank',
      subtitle: 'Yesterday',
      amount: 250.00,
      isCredit: false,
      icon: Icons.arrow_outward,
    ),
    Transaction(
      id: '3',
      title: 'Job Payout - Ford F150',
      subtitle: 'Oct 24, 2023',
      amount: 120.00,
      isCredit: true,
      icon: Icons.handyman,
    ),
    Transaction(
      id: '4',
      title: 'Job Payout - Battery Fix',
      subtitle: 'Oct 22, 2023',
      amount: 45.00,
      isCredit: true,
      icon: Icons.handyman,
    ),
  ];

  void _handleNavigation(int index) {
    setState(() {
      _selectedNavIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/mechanic');
        break;
      case 1:
        // Already on Wallet
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/mechanic/map');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/mechanic/history');
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed('/mechanic/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF2F9FA);
    const textColor = Color(0xFF1B2A3B);
    const subTextColor = Color(0xFF7B8A98);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              _handleNavigation(0);
            }
          },
        ),
        title: const Text(
          'Wallet',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2B4C59), // dark teal
                    Color(0xFF86B8D1), // light blue
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2B4C59).withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '\$842.50',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Withdraw funds feature coming soon'),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.payments_outlined,
                        color: Color(0xFF2B4C59),
                      ),
                      label: const Text(
                        'Withdraw Funds',
                        style: TextStyle(
                          color: Color(0xFF2B4C59),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(Icons.account_balance, 'Bank\nDetails'),
                _buildActionButton(Icons.history, 'Payout\nHistory'),
                _buildActionButton(
                  Icons.insert_chart_outlined,
                  'Earnings\nReport',
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Recent Transactions Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    alignment: Alignment.centerRight,
                  ),
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      color: Color(0xFF14A8C4),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Transactions List
            ..._mockTransactions.map(
              (tx) => _buildTransactionCard(tx, textColor, subTextColor),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: DashboardBottomNavBar(
        selectedIndex: _selectedNavIndex,
        onTabChanged: _handleNavigation,
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF2B4C59), size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF5A6B7C),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(
    Transaction tx,
    Color textColor,
    Color subTextColor,
  ) {
    final bool isCredit = tx.isCredit;
    final Color iconBgColor = isCredit
        ? const Color(0xFFEDF7F1)
        : const Color(0xFFF2F4F7);
    final Color iconColor = isCredit
        ? const Color(0xFF2EB774)
        : const Color(0xFF7A8B99);
    final Color amountColor = isCredit ? const Color(0xFF2EB774) : Colors.black;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(tx.icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tx.subtitle,
                  style: TextStyle(color: subTextColor, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isCredit ? '+' : '-'}\$${tx.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: amountColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
