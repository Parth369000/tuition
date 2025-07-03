import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../core/themes/app_colors.dart';

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

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  const GlassContainer({
    Key? key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding,
    this.backgroundColor,
    this.border,
    this.boxShadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.glassBackground,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ??
                Border.all(
                  color: AppColors.glassBorder,
                  width: 1.2,
                ),
            boxShadow: boxShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}
