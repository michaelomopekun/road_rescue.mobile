import 'package:flutter/material.dart';
import 'package:road_rescue/models/verification_status.dart';
import 'package:road_rescue/features/mechanic/widgets/verification_banner_card.dart';
import 'package:road_rescue/features/mechanic/widgets/profile_summary_card.dart';
import 'package:road_rescue/features/mechanic/widgets/service_type_card.dart';
import 'package:road_rescue/features/mechanic/widgets/workshop_address_card.dart';
import 'package:road_rescue/features/mechanic/widgets/dashboard_bottom_nav_bar.dart';
import 'package:road_rescue/features/mechanic/verification/business_info_screen.dart';
import 'package:road_rescue/services/token_service.dart';
import 'package:road_rescue/services/auth_service.dart';

class MechanicLockedDashboard extends StatefulWidget {
  final String email;
  final String phoneNumber;
  // final String workshopName;
  // final WorkshopLocation workshopLocation;

  const MechanicLockedDashboard({
    super.key,
    required this.email,
    required this.phoneNumber,
    // required this.workshopName,
    // required this.workshopLocation,
  });

  @override
  State<MechanicLockedDashboard> createState() =>
      _MechanicLockedDashboardState();
}

class _MechanicLockedDashboardState extends State<MechanicLockedDashboard> {
  VerificationStatus? _verificationStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    try {
      final userId = await TokenService.getUserId();
      final providerId = await TokenService.getProviderId() ?? userId;

      if (providerId != null) {
        final response = await AuthService.getVerificationStatus(
          providerId: providerId,
        );

        setState(() {
          _verificationStatus = VerificationStatus.fromJson({
            'id': response.id,
            'verificationStatus': response.verificationStatus,
            'createdAt': response.createdAt,
            'verifiedAt': response.verifiedAt,
          });
        });
      }
    } catch (e) {
      // Status check failed, assume not started
      print('Error loading verification status: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToVerification() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) =>
                BusinessInfoScreen(phoneNumber: widget.phoneNumber),
          ),
        )
        .then((_) {
          // Refresh verification status when returning
          _loadVerificationStatus();
        });
  }

  Future<void> _refreshDashboard() async {
    await _loadVerificationStatus();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            // TODO: Navigate to profile
          },
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
            ),
            child: Icon(Icons.person, color: Colors.grey[600]),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Logout: clear auth data and navigate to login
              await TokenService.clearAuthData();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Open notifications
            },
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Verification Banner
              VerificationBannerCard(
                onVerifyPressed: _navigateToVerification,
                verificationStatus: _verificationStatus,
              ),

              const SizedBox(height: 32),

              // Profile Summary Section
              ProfileSummaryCard(
                fullName: widget.email,
                phoneNumber: widget.phoneNumber,
              ),

              const SizedBox(height: 32),

              // Service Type Section
              ServiceTypeCard(),

              const SizedBox(height: 32),

              // Workshop Address Section
              WorkshopAddressCard(
                // workshopAddress: widget.workshopLocation.formattedAddress,
                // latitude: widget.workshopLocation.latitude,
                // longitude: widget.workshopLocation.longitude,
                onEditPressed: () {
                  // TODO: Navigate to edit profile
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DashboardBottomNavBar(
        onHomeTap: () => {},
        // TODO: Handle navigation based on index
      ),
    );
  }
}
