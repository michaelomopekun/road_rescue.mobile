import 'package:flutter/material.dart';
import 'package:road_rescue/services/token_service.dart';
import 'package:road_rescue/services/mechanic_service.dart';
import 'package:road_rescue/services/fcm_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
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
import 'package:road_rescue/features/driver/driver_dashboard.dart';
import 'package:road_rescue/features/driver/pages/wallet_page.dart';
import 'package:road_rescue/features/driver/pages/map_page.dart';
import 'package:road_rescue/features/driver/pages/history_page.dart';
import 'package:road_rescue/features/driver/pages/profile_page.dart';
import 'features/mechanic/verification/business_info_screen.dart';
import 'features/mechanic/verification/address_step_screen.dart';
import 'features/mechanic/verification/document_upload_screen.dart';
import 'features/mechanic/verification/verification_pending_screen.dart';
import 'package:road_rescue/services/request_state_manager.dart';
import 'package:road_rescue/features/driver/pages/active_request_page.dart';

import 'package:road_rescue/features/mechanic/pages/active_job_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class GlobalStateInitializer extends StatefulWidget {
  final Widget child;
  final String role; // Add role to know which view to redirect to
  
  const GlobalStateInitializer({
    super.key, 
    required this.child,
    required this.role,
  });

  @override
  State<GlobalStateInitializer> createState() => _GlobalStateInitializerState();
}

class _GlobalStateInitializerState extends State<GlobalStateInitializer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await RequestStateManager().initialize();
      
      // Auto-redirect if there is an active request
      final rm = RequestStateManager();
      if (rm.hasActiveRequest) {
         final statusName = rm.status.name;
         if (statusName != 'PAID' && statusName != 'CANCELLED' && statusName != 'NO_PROVIDER_FOUND') {
           if (widget.role == 'DRIVER') {
             navigatorKey.currentState?.pushReplacementNamed('/driver/active-request');
           } else if (widget.role == 'PROVIDER') {
             navigatorKey.currentState?.pushReplacementNamed('/mechanic/active-job');
           }
         }
      }

      // Re-register FCM token now that user is authenticated
      // (initial registration in main() may have been skipped if auth wasn't ready)
      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await FcmService.registerDevice(fcmToken);
        }
      } catch (e) {
        print('[GlobalStateInitializer] FCM token registration error: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and FCM
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FcmService.initialize();
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }

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
      navigatorKey: navigatorKey,
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
                        return const GlobalStateInitializer(
                          role: 'PROVIDER', 
                          child: MechanicDashboard()
                        );
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
                  return const GlobalStateInitializer(
                    role: 'DRIVER', 
                    child: DriverDashboard()
                  );
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
        '/driver': (context) => const DriverDashboard(),
        '/driver/wallet': (context) => const DriverWalletPage(),
        '/driver/map': (context) => const DriverMapPage(),
        '/driver/history': (context) => const DriverHistoryPage(),
        '/driver/profile': (context) => const DriverProfilePage(),
        '/driver/active-request': (context) => const ActiveRequestPage(),
        '/mechanic/active-job': (context) => const ActiveJobPage(),
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
