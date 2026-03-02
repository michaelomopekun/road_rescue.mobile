import 'package:flutter/material.dart';
import 'package:road_rescue/theme/app_colors.dart';
import 'dart:math' as math;
import 'package:road_rescue/features/driver/pages/nearby_mechanics_map_page.dart';

class SearchingMechanicPage extends StatefulWidget {
  final String issueType;
  final IconData issueIcon;

  const SearchingMechanicPage({
    super.key,
    this.issueType = 'Battery Issue',
    this.issueIcon = Icons.bolt,
  });

  @override
  State<SearchingMechanicPage> createState() => _SearchingMechanicPageState();
}

class _SearchingMechanicPageState extends State<SearchingMechanicPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    
    // Simulate searching and then transition
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => NearbyMechanicsMapPage(issueType: widget.issueType),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            Text(
              'SEARCHING FOR HELP...',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                letterSpacing: 1.5,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: RipplePainter(
                        animationValue: _controller.value,
                        color: const Color(0xFF2DD4BF), // Light Teal/Green
                      ),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E4C4E), // Dark Teal
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E4C4E).withValues(alpha: 0.2),
                              blurRadius: 16,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.build_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Connecting you\nwith a Mechanic',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ),
            
            const SizedBox(height: 48),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9), // Very light grey
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.issueIcon,
                        color: const Color(0xFF475569), // Slate
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.issueType,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Searching within 5km',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFCBD5E1)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E4C4E), // Dark Teal
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Cancel Request',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class RipplePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  RipplePainter({
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Use a much larger max radius for the rings to cover bounds
    final maxRadius = 1000.0; 

    // Draw 3 concentric rings that expand
    for (int i = 0; i < 3; i++) {
        // Offset each ring's phase evenly
        double offsetValue = (animationValue + (i / 3.0)) % 1.0;
        
        
        // Exponential expansion for a more natural ripple effect
        double radius = 40.0 * math.pow(maxRadius / 40.0, offsetValue);


        // // Linear expansion to maintain spacing instead of exponential curve crowding
        // double radius = 40.0 + (maxRadius - 40.0) * offsetValue;

        // Opacity drops smoothly as radius increases to maxRadius
        double opacity = 1.0 - offsetValue;
        paint.color = color.withValues(alpha: opacity * 0.8);

        canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant RipplePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
