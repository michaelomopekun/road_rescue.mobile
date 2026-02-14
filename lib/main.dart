import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/login_signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
  final onboardingComplete = false;

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
      home: onboardingComplete
          ? const LoginSignupScreen()
          : const OnboardingScreen(),
    );
  }
}
