import 'package:flutter/material.dart';
import 'package:road_rescue/services/token_service.dart';
import 'package:road_rescue/services/mechanic_service.dart';
import 'package:road_rescue/services/auth_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/login_signup_screen.dart';
import 'features/mechanic/mechanic_locked_dashboard.dart';
import 'features/mechanic/mechanic_dashboard.dart';
import 'features/mechanic/pages/wallet_page.dart';
import 'features/mechanic/pages/map_page.dart';
import 'features/mechanic/pages/history_page.dart';
import 'features/mechanic/pages/profile_page.dart';
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

  /// Get verification status from cache, or fetch from API if not cached
  Future<String?> _getVerificationStatus(AuthData authData) async {
    // First try to get from SharedPreferences (saved during login)
    final cachedStatus = await TokenService.getVerificationStatus();
    if (cachedStatus != null) {
      print('Using cached verification status: $cachedStatus');
      return cachedStatus;
    }

    // If not in cache, fetch from API
    print('Verification status not cached, fetching from API...');
    try {
      final providerId = await TokenService.getProviderId();
      if (providerId != null) {
        // Use MechanicService to fetch verification status
        final providerStatus = await MechanicService.getVerificationStatus(
          providerId,
        );
        final status = providerStatus.verificationStatus;
        // Cache it for future app launches
        await TokenService.saveVerificationStatus(status);
        print('Fetched and cached verification status: $status');
        return status;
      }
    } catch (e) {
      print('Error fetching verification status: $e');
    }

    // Default to not verified if we can't get the status
    return 'NOT_VERIFIED';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: ListenableBuilder(
        listenable: authNotifier,
        builder: (context, child) {
          return FutureBuilder<AuthData?>(
            future: authNotifier.getAuthData(),
            builder: (context, snapshot) {
              print(
                '[Main] FutureBuilder - connectionState: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, data: ${snapshot.data}',
              );

              // While checking authentication status
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // If user is authenticated, show appropriate dashboard based on role
              if (snapshot.hasData && snapshot.data != null) {
                final authData = snapshot.data!;
                print('[Main] User authenticated with role: ${authData.role}');

                // Route to appropriate dashboard based on user role
                if (authData.role == 'PROVIDER') {
                  return FutureBuilder<String?>(
                    future: _getVerificationStatus(authData),
                    builder: (context, statusSnapshot) {
                      final status = statusSnapshot.data?.toUpperCase();
                      print('[Main] Verification status: $status');

                      // If approved, show full dashboard
                      if (status == 'APPROVED') {
                        return const MechanicDashboard();
                      }

                      // Otherwise show locked dashboard
                      return FutureBuilder<String?>(
                        future: TokenService.getUserEmail(),
                        builder: (context, emailSnapshot) {
                          return MechanicLockedDashboard(
                            email: emailSnapshot.data ?? 'user@example.com',
                            phoneNumber:
                                '', // Will be updated from dashboard logic
                          );
                        },
                      );
                    },
                  );
                } else if (authData.role == 'DRIVER') {
                  return const DashboardPlaceholder(); // TODO: Replace with driver dashboard
                }
              }

              // If not authenticated, show login/onboarding
              return onboardingComplete
                  ? const LoginSignupScreen()
                  : const OnboardingScreen();
            },
          );
        },
      ),
      routes: {
        '/login': (context) => const LoginSignupScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/mechanic': (context) => const MechanicDashboard(),
        '/mechanic/wallet': (context) => const MechanicWalletPage(),
        '/mechanic/map': (context) => const MechanicMapPage(),
        '/mechanic/history': (context) => const MechanicHistoryPage(),
        '/mechanic/profile': (context) => const MechanicProfilePage(),
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
            authNotifier.notifyAuthStateChanged();
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
