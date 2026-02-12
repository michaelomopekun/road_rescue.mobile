import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Base White
          Container(color: Colors.white),

          // Top Left Glow
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 350,
              height: 350,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.gradientTop, Colors.transparent],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),

          // Bottom Right Glow
          Positioned(
            bottom: -200,
            right: -200,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.gradientBottom, Colors.transparent],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),

          child,
        ],
      ),
    );
  }
}
