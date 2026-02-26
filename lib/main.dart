import 'package:flutter/material.dart';
import 'package:road_rescue/services/token_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/login_signup_screen.dart';
import 'features/mechanic/mechanic_locked_dashboard.dart';
import 'features/mechanic/verification/business_info_screen.dart';
import 'features/mechanic/verification/address_step_screen.dart';
import 'features/mechanic/verification/document_upload_screen.dart';
import 'features/mechanic/verification/verification_pending_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  runApp(MyApp(onboardingComplete: onboardingComplete));
}

class MyApp extends StatelessWidget {
  final bool onboardingComplete;

  const MyApp({super.key, required this.onboardingComplete});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: FutureBuilder<AuthData?>(
        future: TokenService.getAuthData(),
        builder: (context, snapshot) {
          // While checking authentication status
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // If user is authenticated, show appropriate dashboard based on role
          if (snapshot.hasData && snapshot.data != null) {
            final authData = snapshot.data!;

            // Route to appropriate dashboard based on user role
            if (authData.role == 'mechanic') {
              return FutureBuilder<String?>(
                future: TokenService.getVerificationStatus(),
                builder: (context, statusSnapshot) {
                  final status = statusSnapshot.data;

                  // If approved, show full dashboard (placeholder)
                  if (status == 'approved') {
                    return Scaffold(
                      appBar: AppBar(
                        title: const Text('Full Mechanic Dashboard'),
                      ),
                      body: const Center(
                        child: Text('Full Mechanic Dashboard - Coming Soon'),
                      ),
                    );
                  }

                  // Otherwise show locked dashboard
                  return FutureBuilder<String?>(
                    future: TokenService.getUserEmail(),
                    builder: (context, emailSnapshot) {
                      return MechanicLockedDashboard(
                        email: emailSnapshot.data ?? 'user@example.com',
                        phoneNumber: '', // Will be updated from dashboard logic
                      );
                    },
                  );
                },
              );
            } else if (authData.role == 'driver') {
              return const DashboardPlaceholder(); // TODO: Replace with driver dashboard
            }
          }

          // If not authenticated, show login/onboarding
          return onboardingComplete
              ? const LoginSignupScreen()
              : const OnboardingScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginSignupScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/mechanic-dashboard': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          return MechanicLockedDashboard(
            email: args?['email'] ?? 'user@example.com',
            phoneNumber: args?['phoneNumber'] ?? '',
          );
        },
        '/business-info': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          return BusinessInfoScreen(phoneNumber: args?['phoneNumber'] ?? '');
        },
        '/address-info': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          return AddressStepScreen(
            businessName: args?['businessName'] ?? '',
            phoneNumber: args?['phoneNumber'] ?? '',
          );
        },
        '/document-upload': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          return DocumentUploadScreen(
            businessName: args?['businessName'] ?? '',
            workshopLocation: args?['workshopLocation'],
            phoneNumber: args?['phoneNumber'] ?? '',
          );
        },
        '/verification-pending': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          return VerificationPendingScreen(
            serviceProviderId: args?['serviceProviderId'] ?? '',
          );
        },
      },
    );
  }
}

/// Placeholder for dashboard - replace with actual dashboard widget
class DashboardPlaceholder extends StatelessWidget {
  const DashboardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // Logout
            await TokenService.clearToken();
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
          child: const Text('Logout'),
        ),
      ),
    );
  }
}
