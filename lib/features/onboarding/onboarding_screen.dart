import 'package:flutter/material.dart';
import 'package:road_rescue/features/onboarding/widgets/login_link.dart';
import 'package:road_rescue/features/onboarding/widgets/onboarding_page.dart';
import 'package:road_rescue/features/onboarding/widgets/onboarding_top_bar.dart';
import 'package:road_rescue/shared/widgets/primary_button.dart';
import 'package:road_rescue/features/onboarding/widgets/progress_indicator.dart';
import 'package:road_rescue/shared/helper/gradient_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = const [
    {
      'svg': 'assets/svg/onboarding_help.svg',
      'title': 'Get Help\nFast',
      'width': 160,
      'height': 160,
      'isPayment': false,
      'isHelp': true,
      'description': 'Find nearby service providers\nwhen you need help most.',
    },
    {
      'svg': 'assets/svg/onboarding_verified.svg',
      'title': 'Verified\nProviders',
      'width': 160,
      'height': 160,
      'isPayment': false,
      'isHelp': false,
      'description': 'Only trusted and verified service\nproviders near you',
    },
    {
      'svg': 'assets/svg/onboarding_payments.svg',
      'title': 'Simple\nPayments',
      'width': 160,
      'height': 160,
      'isPayment': true,
      'isHelp': false,
      'description': 'Fast wallet payments built for\nlow network areas',
    },
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  void _onNext() {
    if (_isLastPage) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onSkip() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (!mounted) return;

    //TODO: Navigate to login + sign up screen
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(builder: (_) => const LoginScreen()),
    // );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top bar: progress line + skip
              OnboardingTopBar(
                currentPage: _currentPage,
                totalPages: _pages.length,
                onSkip: _onSkip,
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return OnboardingPage(
                      svgPath: page['svg'] as String,
                      title: page['title'] as String,
                      width: page['width'] as int,
                      height: page['height'] as int,
                      description: page['description'] as String,
                      isPayment: page['isPayment'] as bool,
                      isHelp: page['isHelp'] as bool,
                    );
                  },
                ),
              ),

              // Dot indicators
              OnboardingProgressIndicator(
                itemCount: _pages.length,
                currentIndex: _currentPage,
              ),

              const SizedBox(height: 32),

              // Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: PrimaryButton(
                  text: _isLastPage ? 'Get Started' : 'Next',
                  onPressed: _onNext,
                ),
              ),

              const SizedBox(height: 32),

              // Login link
              LoginLink(
                onTap: () {
                  // TODO: Navigate to login + sign up screen
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
