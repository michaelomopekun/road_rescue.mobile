import 'dart:ui';

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

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

          // Top-left blurred circle
          Positioned(
            top: 0,
            left: -47,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
              child: Container(
                width: 311,
                height: 324,
                decoration: BoxDecoration(
                  color: AppColors.gradientTop,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // Bottom-right blurred circle
          Positioned(
            top: 433,
            left: 143,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 140, sigmaY: 140),
              child: Container(
                width: 384,
                height: 384,
                decoration: BoxDecoration(
                  color: AppColors.gradientBottom,
                  shape: BoxShape.circle,
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
