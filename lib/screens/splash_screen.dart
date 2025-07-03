import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:tuition/widgets/liquid_glass_painter.dart';
import 'package:tuition/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'student/student_home_screen.dart';
import 'teacher/teacher_dashboard.dart';
import 'admin/admin_home_screen.dart';
import '../../core/themes/app_colors.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _waveAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _logoGlowAnimation;
  late Animation<double> _nameFadeAnimation;
  late Animation<double> _taglineFadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _logoGlowAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _nameFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.3, 0.7, curve: Curves.easeIn)),
    );
    _taglineFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.6, 1.0, curve: Curves.easeIn)),
    );

    _controller.forward().then((_) async {
      await Future.delayed(const Duration(seconds: 1));
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final role = prefs.getString('role');
      if (token != null && role != null) {
        if (role == 'student') {
          final user = json.decode(prefs.getString('user') ?? '{}');
          final student = json.decode(prefs.getString('student') ?? '{}');
          final enrolledSubjects =
              json.decode(prefs.getString('enrolledSubjects') ?? '[]');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => StudentHomeScreen(
                token: token,
                user: user,
                student: student,
                enrolledSubjects: enrolledSubjects,
              ),
            ),
          );
        } else if (role == 'teacher') {
          final user = json.decode(prefs.getString('user') ?? '{}');
          final teacher = json.decode(prefs.getString('teacher') ?? '{}');
          final teacherSubjects =
              json.decode(prefs.getString('teacherSubjects') ?? '[]');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => TeacherDashboard(
                teacherId: user['id'].toString(),
                token: token,
                user: user,
                teacher: teacher,
                teacherSubjects: teacherSubjects,
              ),
            ),
          );
        } else if (role == 'admin') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const AdminHomeScreen(),
            ),
          );
        } else {
          _goToLogin();
        }
      } else {
        _goToLogin();
      }
    });
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double logoSize = 90;
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Animated gradient background
          final List<Color> gradientColors = [
            ...AppColors.primaryGradient,
          ];
          final Alignment begin = Alignment(
            -1 + 2 * (_controller.value),
            -1 + 2 * (1 - _controller.value),
          );
          final Alignment end = Alignment(
            1 - 2 * (_controller.value),
            1 - 2 * (1 - _controller.value),
          );
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: begin,
                    end: end,
                    colors: gradientColors,
                  ),
                ),
              ),
              // Animated waves overlay
              AnimatedBuilder(
                animation: _waveAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: LiquidGlassPainter(
                      waveColor: AppColors.primary.withOpacity(0.10),
                      waveSpeed: 0.7,
                      waveAmplitude: 0.12,
                      waveFrequency: 1.2,
                      time: _waveAnimation.value * 2,
                    ),
                  );
                },
              ),
              // Main content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated 'Anand' text with script font and color
                    FadeTransition(
                      opacity: _nameFadeAnimation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(_nameFadeAnimation),
                        child: Column(
                          children: [
                            Text(
                              'Anand',
                              style: GoogleFonts.pacifico(
                                fontSize: 64,
                                color: const Color(
                                    0xFF3B4252), // dark blue/gray from image
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            // Yellow underline bar
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 170,
                              height: 18,
                              color: AppColors.secondary, // Use your yellow
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 'COACHING CENTER' text
                    FadeTransition(
                      opacity: _taglineFadeAnimation,
                      child: Text(
                        'COACHING CENTER',
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          color: const Color(0xFF3B4252),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Custom animated loader
                    _AnimatedLoader(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Custom shimmer text widget
class _ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Color shimmerColor;
  const _ShimmerText(
      {required this.text, required this.style, required this.shimmerColor});
  @override
  State<_ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<_ShimmerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              colors: [
                widget.shimmerColor.withOpacity(0.2),
                widget.shimmerColor,
                widget.shimmerColor.withOpacity(0.2)
              ],
              stops: [
                (_controller.value - 0.2).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.2).clamp(0.0, 1.0)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: Text(widget.text, style: widget.style),
          blendMode: BlendMode.srcATop,
        );
      },
    );
  }
}

// Custom animated loader widget
class _AnimatedLoader extends StatefulWidget {
  @override
  State<_AnimatedLoader> createState() => _AnimatedLoaderState();
}

class _AnimatedLoaderState extends State<_AnimatedLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _LoaderPainter(_controller.value),
          );
        },
      ),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  final double progress;
  _LoaderPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final double radius = size.width / 2 - 6;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double startAngle = 2 * pi * progress;
    final double sweepAngle = pi * 1.2;
    paint.shader = SweepGradient(
      colors: [AppColors.primary, AppColors.secondary, AppColors.primary],
      stops: const [0.0, 0.7, 1.0],
      startAngle: 0,
      endAngle: 2 * pi,
      transform: GradientRotation(startAngle),
    ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
        sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _LoaderPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
