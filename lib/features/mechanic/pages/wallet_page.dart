import 'package:flutter/material.dart';
import 'package:road_rescue/features/mechanic/widgets/dashboard_bottom_nav_bar.dart';
import 'package:road_rescue/services/toast_service.dart';
import 'package:road_rescue/services/wallet_service.dart';
import 'package:road_rescue/models/wallet.dart';
import 'package:road_rescue/models/wallet_transaction.dart';
import 'package:intl/intl.dart';

class MechanicWalletPage extends StatefulWidget {
  const MechanicWalletPage({super.key});

  @override
  State<MechanicWalletPage> createState() => _MechanicWalletPageState();
}

class _MechanicWalletPageState extends State<MechanicWalletPage> {
  int _selectedNavIndex = 1;

  Wallet? _wallet;
  List<WalletTransaction> _transactions = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _totalPages = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreTransactions();
    }
  }

  Future<void> _fetchWalletData() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _transactions = [];
    });

    try {
      final wallet = await WalletService.getBalance();
      final txData = await WalletService.getTransactions(page: 1, limit: 10);

      if (mounted) {
        setState(() {
          _wallet = wallet;
          _transactions = txData.transactions;
          _totalPages = (txData.total / txData.limit).ceil();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ToastService.showError(context, e.toString());
      }
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final txData = await WalletService.getTransactions(
        page: nextPage,
        limit: 10,
      );

      if (mounted) {
        setState(() {
          _transactions.addAll(txData.transactions);
          _currentPage = nextPage;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        ToastService.showError(context, 'Failed to load more transactions');
      }
    }
  }

  void _handleNavigation(int index) {
    if (index == _selectedNavIndex) return;
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
      body: RefreshIndicator(
        onRefresh: _fetchWalletData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: _scrollController,
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
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            '\$${_wallet?.balance.toStringAsFixed(2) ?? "0.00"}',
                            style: const TextStyle(
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
                        // Add modal or page navigation for Withdraw/TopUp
                        onPressed: () {
                          ToastService.showWarning(
                            context,
                            'Withdraw funds feature coming soon',
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
                ],
              ),
              const SizedBox(height: 16),

              // Transactions List
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_transactions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text(
                      'No transactions yet.',
                      style: TextStyle(color: subTextColor, fontSize: 16),
                    ),
                  ),
                )
              else ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    return _buildTransactionCard(
                      _transactions[index],
                      textColor,
                      subTextColor,
                    );
                  },
                ),
                if (_isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],

              // Bottom padding
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DashboardBottomNavBar(
        selectedIndex: _selectedNavIndex,
        onTabChanged: _handleNavigation,
      ),
    );
  }

  Widget _buildTransactionCard(
    WalletTransaction tx,
    Color textColor,
    Color subTextColor,
  ) {
    final bool isCredit = tx.type == 'CREDIT';
    final Color iconBgColor = isCredit
        ? const Color(0xFFEDF7F1)
        : const Color(0xFFF2F4F7);
    final Color iconColor = isCredit
        ? const Color(0xFF2EB774)
        : const Color(0xFF7A8B99);
    final Color amountColor = isCredit ? const Color(0xFF2EB774) : Colors.black;

    // Choose appropriate icon based on source
    IconData icon = Icons.receipt_long;
    if (tx.source == 'TOP_UP') {
      icon = Icons.account_balance_wallet;
    } else if (tx.source == 'PAYMENT') {
      icon = Icons.handyman;
    }

    final String dateStr = DateFormat('MMM d, y, h:mm a').format(tx.createdAt);

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
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description.isNotEmpty ? tx.description : 'Transaction',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
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
