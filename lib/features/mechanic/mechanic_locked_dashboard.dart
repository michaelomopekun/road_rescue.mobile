import 'package:flutter/material.dart';
import 'package:road_rescue/models/workshop_location.dart';
import 'package:road_rescue/features/mechanic/widgets/verification_banner_card.dart';
import 'package:road_rescue/features/mechanic/widgets/profile_summary_card.dart';
import 'package:road_rescue/features/mechanic/widgets/service_type_card.dart';
import 'package:road_rescue/features/mechanic/widgets/workshop_address_card.dart';
import 'package:road_rescue/features/mechanic/widgets/dashboard_bottom_nav_bar.dart';

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
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Open search
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Verification Banner
            VerificationBannerCard(
              onVerifyPressed: () {
                // TODO: Navigate to verification flow
              },
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
      bottomNavigationBar: DashboardBottomNavBar(
        onHomeTap: () => {},
        // TODO: Handle navigation based on index
      ),
    );
  }
}
