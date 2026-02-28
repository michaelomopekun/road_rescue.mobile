import 'package:flutter/material.dart';
import 'package:road_rescue/features/mechanic/widgets/dashboard_bottom_nav_bar.dart';
import 'package:road_rescue/shared/widgets/request_list_item.dart';
import 'package:road_rescue/theme/app_colors.dart';
import 'package:road_rescue/services/mechanic_service.dart';
import 'package:road_rescue/services/toast_service.dart';

class MechanicHistoryPage extends StatefulWidget {
  const MechanicHistoryPage({super.key});

  @override
  State<MechanicHistoryPage> createState() => _MechanicHistoryPageState();
}

class _MechanicHistoryPageState extends State<MechanicHistoryPage> {
  int _selectedNavIndex = 3;
  List<HistoryJob> _jobs = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;
  String _selectedStatus = 'COMPLETED';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Load history from API with pagination
  Future<void> _loadHistory({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
    }

    try {
      final result = await MechanicService.getRequestHistoryPaginated(
        page: _currentPage,
        limit: 10,
        status: _selectedStatus,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _jobs = result.data;
          } else {
            _jobs.addAll(result.data);
          }
          _totalPages = result.totalPages;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[HistoryPage] Error loading history: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ToastService.showError(context, 'Failed to load job history');
      }
    }
  }

  /// Handle manual refresh
  Future<void> _refreshHistory() async {
    await _loadHistory(refresh: true);
  }

  /// Load more when user scrolls to bottom
  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _currentPage < _totalPages) {
      _currentPage++;
      _loadHistory();
    }
  }

  /// Change filter and reload
  void _changeStatus(String newStatus) {
    if (newStatus != _selectedStatus) {
      setState(() {
        _selectedStatus = newStatus;
        _currentPage = 1;
        _jobs = [];
        _isLoading = true;
      });
      _loadHistory();
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
      body: Column(
        children: [
          // Status filter tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildStatusTab('COMPLETED'),
                const SizedBox(width: 8),
                _buildStatusTab('ASSIGNED'),
              ],
            ),
          ),
          // Jobs list
          Expanded(
            child: _isLoading && _jobs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _jobs.isEmpty
                ? Center(
                    child: Text(
                      'No $_selectedStatus jobs yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshHistory,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          _jobs.length + (_currentPage < _totalPages ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Show loading indicator at bottom when loading more
                        if (index == _jobs.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final job = _jobs[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: RequestListItem(
                              customerName: job.driverName,
                              serviceType: job.description,
                              amount: job.location,
                              status: job.status,
                              avatarIcon: Icons.person,
                              onTap: () {
                                // Show job details
                                _showJobDetails(job);
                              },
                            ),
                          ),
                        );
                      },
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

  /// Build status filter tab
  Widget _buildStatusTab(String status) {
    final isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () => _changeStatus(status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary, width: 1),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Show job details in a bottom sheet
  void _showJobDetails(HistoryJob job) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Job Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow('Driver', job.driverName),
            _detailRow('Phone', job.driverPhone),
            _detailRow('Service', job.description),
            _detailRow('Location', job.location),
            _detailRow('Status', job.status),
            _detailRow('Assigned', job.assignedAt.toString().split('.')[0]),
            if (job.completedAt != null)
              _detailRow('Completed', job.completedAt.toString().split('.')[0]),
          ],
        ),
      ),
    );
  }

  /// Helper widget for detail rows
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}
