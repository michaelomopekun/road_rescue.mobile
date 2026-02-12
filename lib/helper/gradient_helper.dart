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
            top: 0,
            left: -77,
            child: Container(
              width: 311,
              height: 324,
              decoration: BoxDecoration(
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
            top: 433,
            left: 143,
            child: Container(
              width: 384,
              height: 384,
              decoration: BoxDecoration(
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
