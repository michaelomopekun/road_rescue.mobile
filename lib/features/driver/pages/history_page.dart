import 'package:flutter/material.dart';
import 'package:road_rescue/features/mechanic/widgets/dashboard_bottom_nav_bar.dart';
import 'package:road_rescue/theme/app_colors.dart';
import 'package:road_rescue/services/driver_service.dart';
import 'package:road_rescue/services/toast_service.dart';

class DriverHistoryPage extends StatefulWidget {
  const DriverHistoryPage({super.key});

  @override
  State<DriverHistoryPage> createState() => _DriverHistoryPageState();
}

class _DriverHistoryPageState extends State<DriverHistoryPage> {
  int _selectedNavIndex = 2;
  List<DriverHistoryRequest> _requests = [];
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
      final result = await DriverService.getRequestHistoryPaginated(
        page: _currentPage,
        limit: 10,
        status: _selectedStatus,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _requests = result.data;
          } else {
            _requests.addAll(result.data);
          }
          _totalPages = result.totalPages;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[DriverHistoryPage] Error loading history: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ToastService.showError(context, 'Failed to load request history');
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
        _requests = [];
        _isLoading = true;
      });
      _loadHistory();
    }
  }

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
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/driver/profile');
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
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    String weekday = weekdays[date.weekday - 1];
    String month = months[date.month - 1];
    String day = date.day.toString().padLeft(2, '0');
    int hour = date.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    String minute = date.minute.toString().padLeft(2, '0');
    return '$weekday, $day $month \u2022 $hour:$minute $period';
  }

  IconData _getServiceIcon(String serviceType) {
    switch (serviceType.toUpperCase()) {
      case 'FLAT_TIRE':
        return Icons.tire_repair;
      case 'BATTERY_JUMP':
        return Icons.battery_charging_full;
      case 'TOW':
        return Icons.directions_car;
      case 'ENGINE':
        return Icons.car_repair;
      case 'LOCKOUT':
        return Icons.vpn_key;
      case 'FUEL_DELIVERY':
        return Icons.local_gas_station_outlined;
      default:
        return Icons.handyman;
    }
  }

  Color _getServiceIconBgColor(String serviceType) {
    switch (serviceType.toUpperCase()) {
      case 'FLAT_TIRE':
        return const Color(0xFFE0E7FF);
      case 'BATTERY_JUMP':
        return const Color(0xFFFFF0E6);
      case 'TOW':
        return const Color(0xFFF1F5F9);
      case 'ENGINE':
        return const Color(0xFFFFE4E6);
      case 'LOCKOUT':
        return const Color(0xFFF3E8FF);
      case 'FUEL_DELIVERY':
        return const Color(0xFFE6F9F3);
      default:
        return const Color(0xFFDFEAF4);
    }
  }

  Color _getServiceIconColor(String serviceType) {
    switch (serviceType.toUpperCase()) {
      case 'FLAT_TIRE':
        return const Color(0xFF4F46E5);
      case 'BATTERY_JUMP':
        return const Color(0xFFF97316);
      case 'TOW':
        return const Color(0xFF94A3B8);
      case 'ENGINE':
        return const Color(0xFFE11D48);
      case 'LOCKOUT':
        return const Color(0xFF9333EA);
      case 'FUEL_DELIVERY':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF5A789A);
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
              padding: const EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Activity History',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your past roadside assistance requests.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Status filter tabs
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Row(
                children: [
                  _buildStatusTab('PAID', 'Completed'),
                  const SizedBox(width: 12),
                  _buildStatusTab('CANCELLED', 'Cancelled'),
                ],
              ),
            ),

            // Request history list
            Expanded(
              child: _isLoading && _requests.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _requests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _selectedStatus == 'COMPLETED'
                                ? Icons.check_circle_outline
                                : Icons.cancel_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No ${_selectedStatus.toLowerCase()} requests yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
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
                            _requests.length +
                            (_currentPage < _totalPages ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Show loading indicator at bottom when loading more
                          if (index == _requests.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final request = _requests[index];
                          return _buildHistoryCard(request);
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
        variant: DashboardNavVariant.driverDashboard,
      ),
    );
  }

  Widget _buildStatusTab(String statusValue, String displayLabel) {
    final isSelected = _selectedStatus == statusValue;
    return GestureDetector(
      onTap: () => _changeStatus(statusValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: AppColors.border),
        ),
        child: Text(
          displayLabel,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(DriverHistoryRequest request) {
    final isCancelled = request.status.toUpperCase() == 'CANCELLED';
    final icon = _getServiceIcon(request.serviceType);
    final iconBgColor = isCancelled
        ? const Color(0xFFF1F5F9)
        : _getServiceIconBgColor(request.serviceType);
    final iconColor = isCancelled
        ? const Color(0xFF94A3B8)
        : _getServiceIconColor(request.serviceType);

    return GestureDetector(
      onTap: () => _showRequestDetails(request),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.serviceTypeLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Mechanic: ${request.providerName ?? 'Unassigned'}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? Colors.transparent
                        : const Color(0xFFE6F9F3),
                    borderRadius: BorderRadius.circular(12),
                    border: isCancelled
                        ? Border.all(color: AppColors.border)
                        : null,
                  ),
                  child: Text(
                    isCancelled ? 'Cancelled' : 'Completed',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isCancelled
                          ? const Color(0xFF94A3B8)
                          : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(request.completedAt ?? request.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  isCancelled
                      ? 'Cancelled'
                      : '₦${request.amount?.toStringAsFixed(2) ?? '0.00'}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCancelled
                        ? const Color(0xFF94A3B8)
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show request details in a bottom sheet
  void _showRequestDetails(DriverHistoryRequest request) {
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
                  'Request Details',
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
            _detailRow('Service', request.serviceTypeLabel),
            _detailRow('Description', request.description),
            _detailRow(
              'Mechanic',
              request.providerName ?? 'No mechanic assigned',
            ),
            _detailRow('Location', request.location),
            _detailRow('Status', request.status),
            if (request.amount != null)
              _detailRow('Amount', '₦${request.amount!.toStringAsFixed(2)}'),
            _detailRow('Requested', _formatDate(request.createdAt)),
            if (request.completedAt != null)
              _detailRow('Completed', _formatDate(request.completedAt!)),
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
