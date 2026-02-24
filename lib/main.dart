import 'package:flutter/material.dart';
import 'package:road_rescue/services/token_service.dart';
import 'theme/app_theme.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/login_signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
  const bool onboardingComplete = false;

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
      home: FutureBuilder<bool>(
        future: TokenService.isAuthenticated(),
        builder: (context, snapshot) {
          // While checking authentication status
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // If user is authenticated, show dashboard
          if (snapshot.hasData && snapshot.data == true) {
            return const DashboardPlaceholder(); // TODO: Replace with actual dashboard
          }

          // If not authenticated, show login/onboarding
          return onboardingComplete
              ? const LoginSignupScreen()
              : const OnboardingScreen();
        },
      ),
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
