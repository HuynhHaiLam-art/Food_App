import 'package:flutter/material.dart';
import 'package:food_app/themes/app_theme.dart';

class BackgroundWidget extends StatelessWidget {
  final Widget child;
  final bool hasPattern;

  const BackgroundWidget({
    super.key,
    required this.child,
    this.hasPattern = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: hasPattern
          ? Stack(
              children: [
                // Geometric Pattern
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GeometricPatternPainter(),
                  ),
                ),
                // Content
                child,
              ],
            )
          : child,
    );
  }
}

class _GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.fill;

    // Draw subtle geometric pattern
    for (int i = 0; i < size.width; i += 60) {
      for (int j = 0; j < size.height; j += 60) {
        canvas.drawCircle(
          Offset(i.toDouble(), j.toDouble()),
          2,
          paint,
        );
      }
    }

    // Draw diagonal lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.01)
      ..strokeWidth = 1;

    for (int i = 0; i < size.width + size.height; i += 100) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i - size.height, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}