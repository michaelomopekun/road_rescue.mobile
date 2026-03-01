import 'package:flutter/material.dart';
import 'package:road_rescue/features/mechanic/widgets/dashboard_bottom_nav_bar.dart';

class DriverMapPage extends StatefulWidget {
  const DriverMapPage({super.key});

  @override
  State<DriverMapPage> createState() => _DriverMapPageState();
}

class _DriverMapPageState extends State<DriverMapPage> {
  int _selectedNavIndex = 2;

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
      appBar: AppBar(title: const Text('Map')),
      body: const Center(
        child: Text('Driver Map View Under Construction'),
      ),
      bottomNavigationBar: DashboardBottomNavBar(
        selectedIndex: _selectedNavIndex,
        onTabChanged: _handleNavigation,
      ),
    );
  }
}
