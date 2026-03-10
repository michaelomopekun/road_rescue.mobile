import 'package:flutter/material.dart';
import 'package:road_rescue/features/mechanic/widgets/dashboard_bottom_nav_bar.dart';
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

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    String month = months[date.month - 1];
    String day = date.day.toString();
    int hour = date.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    String minute = date.minute.toString().padLeft(2, '0');
    return '$month $day, $hour:$minute $period';
  }

  IconData _getServiceIcon(String serviceType) {
    final lower = serviceType.toLowerCase();
    if (lower.contains('tire')) return Icons.tire_repair;
    if (lower.contains('battery') || lower.contains('jumpstart'))
      return Icons.bolt;
    if (lower.contains('lock') || lower.contains('key'))
      return Icons.lock_outline;
    if (lower.contains('fuel')) return Icons.local_gas_station_outlined;
    if (lower.contains('tow')) return Icons.car_repair;
    return Icons.settings_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFFF3F8FB);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar Area
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'History',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF101828),
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDFEAF4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Color(0xFF5A789A)),
                  ),
                ],
              ),
            ),

            // Status filter tabs
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  Expanded(child: _buildStatusTab('PAID', 'Completed')),
                  Expanded(child: _buildStatusTab('CANCELLED', 'Cancelled')),
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
                        'No ${_selectedStatus.toLowerCase()} jobs yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshHistory,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
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
                          return _buildJobCard(job);
                        },
                      ),
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

  // Segmented tab builder
  Widget _buildStatusTab(String statusValue, String displayLabel) {
    final isSelected = _selectedStatus == statusValue;
    return GestureDetector(
      onTap: () => _changeStatus(statusValue),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        decoration: isSelected
            ? BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              )
            : null,
        alignment: Alignment.center,
        child: Text(
          displayLabel,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF101828)
                : const Color(0xFF64748B),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(HistoryJob job) {
    return GestureDetector(
      onTap: () {
        _showJobDetails(job);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left avatar
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                color: Color(0xFF94A3B8),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Middle Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.driverName ?? "",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(job.completedAt ?? job.assignedAt),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDFEAF4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getServiceIcon(job.description),
                          size: 14,
                          color: const Color(0xFF5A789A),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            job.description,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5A789A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Trailing price and status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${job.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: job.status.toLowerCase() == 'completed'
                        ? const Color(0xFF22C55E)
                        : (job.status.toLowerCase() == 'cancelled'
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFF59E0B)),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show job details in a bottom sheet
  void _showJobDetails(HistoryJob job) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow('Driver', job.driverName ?? ""),
            _detailRow('Phone', job.driverPhone),
            _detailRow('Service', job.description),
            _detailRow('Location', job.location),
            _detailRow('Status', job.status),
            _detailRow('Amount', '\$${job.amount.toStringAsFixed(2)}'),
            _detailRow('Assigned', _formatDate(job.assignedAt)),
            if (job.completedAt != null)
              _detailRow('Completed', _formatDate(job.completedAt!)),
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
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
