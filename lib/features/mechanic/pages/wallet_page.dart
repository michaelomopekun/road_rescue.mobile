import 'package:flutter/material.dart';
import 'package:road_rescue/features/mechanic/widgets/dashboard_bottom_nav_bar.dart';
import 'package:road_rescue/theme/app_colors.dart';

class Transaction {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final bool isCredit;
  final String icon;
  final DateTime timestamp;

  Transaction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isCredit,
    required this.icon,
    required this.timestamp,
  });
}

class MechanicWalletPage extends StatefulWidget {
  const MechanicWalletPage({super.key});

  @override
  State<MechanicWalletPage> createState() => _MechanicWalletPageState();
}

class _MechanicWalletPageState extends State<MechanicWalletPage>
    with SingleTickerProviderStateMixin {
  int _selectedNavIndex = 1;
  late TabController _tabController;

  // Mock transactions
  final List<Transaction> _mockTransactions = [
    Transaction(
      id: '1',
      title: 'Job Payout - Sarah Jenkins',
      subtitle: 'Today, 2:30 PM',
      amount: 85.00,
      isCredit: true,
      icon: '🔧',
      timestamp: DateTime.now(),
    ),
    Transaction(
      id: '2',
      title: 'Withdrawal to Chase Bank',
      subtitle: 'Yesterday',
      amount: 250.00,
      isCredit: false,
      icon: '🏦',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Transaction(
      id: '3',
      title: 'Job Payout - Ford F150',
      subtitle: 'Oct 24, 2023',
      amount: 120.00,
      isCredit: true,
      icon: '🔧',
      timestamp: DateTime(2023, 10, 24),
    ),
    Transaction(
      id: '4',
      title: 'Job Payout - Battery Fix',
      subtitle: 'Oct 22, 2023',
      amount: 45.00,
      isCredit: true,
      icon: '🔧',
      timestamp: DateTime(2023, 10, 22),
    ),
    Transaction(
      id: '5',
      title: 'Withdrawal to Chase Bank',
      subtitle: 'Oct 20, 2023',
      amount: 300.00,
      isCredit: false,
      icon: '🏦',
      timestamp: DateTime(2023, 10, 20),
    ),
    Transaction(
      id: '6',
      title: 'Job Payout - Tire Replacement',
      subtitle: 'Oct 18, 2023',
      amount: 65.50,
      isCredit: true,
      icon: '🔧',
      timestamp: DateTime(2023, 10, 18),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: AppColors.primary,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Wallet',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white,
                                ),
                                onPressed: () {},
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Balance Card
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.9),
                                  AppColors.primary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Available Balance',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '\$842.50',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Withdraw funds feature coming soon',
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.account_balance_wallet),
                                        SizedBox(width: 8),
                                        Text(
                                          'Withdraw Funds',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.account_balance),
                        text: 'Bank Details',
                      ),
                      Tab(icon: Icon(Icons.history), text: 'Payout History'),
                      Tab(icon: Icon(Icons.bar_chart), text: 'Earnings Report'),
                    ],
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Bank Details Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Bank Account',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Bank Name', 'Chase Bank'),
                        const SizedBox(height: 12),
                        _buildDetailRow('Account Holder', 'John Doe'),
                        const SizedBox(height: 12),
                        _buildDetailRow('Account Number', '••••••••7890'),
                        const SizedBox(height: 12),
                        _buildDetailRow('Routing Number', '••••••••5432'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Update bank account feature coming soon',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Update Bank Account'),
                    ),
                  ),
                ],
              ),
            ),

            // Payout History Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  ..._mockTransactions.map((transaction) {
                    return _buildTransactionTile(transaction);
                  }),
                ],
              ),
            ),

            // Earnings Report Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This Month',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  _buildEarningsCard(
                    'Total Earnings',
                    '\$1,245.50',
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildEarningsCard(
                    'Number of Jobs',
                    '18 jobs',
                    AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  _buildEarningsCard(
                    'Average Job Value',
                    '\$69.19',
                    Colors.orange,
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Last 6 Months',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildMonthEarnings('February', '\$1,245.50'),
                        _buildMonthEarnings('January', '\$980.00'),
                        _buildMonthEarnings('December', '\$1,450.25'),
                        _buildMonthEarnings('November', '\$825.75'),
                        _buildMonthEarnings('October', '\$1,125.00'),
                        _buildMonthEarnings('September', '\$950.50'),
                      ],
                    ),
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(Transaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: transaction.isCredit
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                transaction.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${transaction.isCredit ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: transaction.isCredit ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(String title, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthEarnings(String month, String earnings) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              month,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              earnings,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
