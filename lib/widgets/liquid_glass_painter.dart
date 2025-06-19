import 'package:flutter/material.dart';
import 'dart:math' as math;

class LiquidGlassPainter extends CustomPainter {
  final Color waveColor;
  final double waveSpeed;
  final double waveAmplitude;
  final double waveFrequency;
  final double time;

  LiquidGlassPainter({
    required this.waveColor,
    required this.waveSpeed,
    required this.waveAmplitude,
    required this.waveFrequency,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.5 +
          math.sin((x * waveFrequency + time) * waveSpeed) *
              waveAmplitude *
              size.height;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(LiquidGlassPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.waveColor != waveColor ||
        oldDelegate.waveSpeed != waveSpeed ||
        oldDelegate.waveAmplitude != waveAmplitude ||
        oldDelegate.waveFrequency != waveFrequency;
  }
}
