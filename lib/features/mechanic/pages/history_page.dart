import 'package:flutter/material.dart';
import 'package:road_rescue/features/mechanic/widgets/dashboard_bottom_nav_bar.dart';
import 'package:road_rescue/shared/widgets/request_list_item.dart';
import 'package:road_rescue/theme/app_colors.dart';
import 'package:road_rescue/services/mechanic_service.dart';

class MechanicHistoryPage extends StatefulWidget {
  const MechanicHistoryPage({super.key});

  @override
  State<MechanicHistoryPage> createState() => _MechanicHistoryPageState();
}

class _MechanicHistoryPageState extends State<MechanicHistoryPage> {
  int _selectedNavIndex = 3;
  List<RecentJob> _jobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    // Mock data for now
    setState(() {
      _jobs = [
        RecentJob(
          id: '1',
          customerId: 'cust1',
          customerName: 'Marcus Wright',
          serviceType: 'Tire Replacement',
          amount: 85.00,
          status: 'Completed',
          completedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        RecentJob(
          id: '2',
          customerId: 'cust2',
          customerName: 'Sarah Chen',
          serviceType: 'Battery Jumpstart',
          amount: 45.00,
          status: 'Completed',
          completedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        RecentJob(
          id: '3',
          customerId: 'cust3',
          customerName: 'David Miller',
          serviceType: 'Engine Check',
          amount: 120.00,
          status: 'Completed',
          completedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        RecentJob(
          id: '4',
          customerId: 'cust4',
          customerName: 'Emily Rodriguez',
          serviceType: 'Oil Change',
          amount: 55.00,
          status: 'Completed',
          completedAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        RecentJob(
          id: '5',
          customerId: 'cust5',
          customerName: 'James Anderson',
          serviceType: 'Brake Inspection',
          amount: 75.00,
          status: 'Completed',
          completedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ];
      _isLoading = false;
    });
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
        // Already on History
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed('/mechanic/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _jobs.length,
              itemBuilder: (context, index) {
                final job = _jobs[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: RequestListItem(
                      customerName: job.customerName,
                      serviceType: job.serviceType,
                      amount: '\$${job.amount.toStringAsFixed(2)}',
                      status: job.status,
                      avatarIcon: Icons.person,
                      onTap: () {
                        // TODO: Navigate to job details
                      },
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: DashboardBottomNavBar(
        selectedIndex: _selectedNavIndex,
        onTabChanged: _handleNavigation,
      ),
    );
  }
}
