import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tuition/screens/teacher/teacher_dashboard.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:tuition/widgets/liquid_glass_painter.dart';
import 'student/student_home_screen.dart';
import 'admin/admin_home_screen.dart';
import '../core/themes/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  late AnimationController _waveController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true, count: 1);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _waveController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    void showError(String message) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }

    try {
      var headers = {'Content-Type': 'application/json'};
      var request =
          http.Request('POST', Uri.parse('http://27.116.52.24:8076/login'));
      request.body = json.encode({
        "number": _phoneController.text,
        "password": _passwordController.text
      });
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Connection timed out. Please check your internet connection and try again.');
        },
      );

      final responseBody = await response.stream.bytesToString();
      print('Response status: ${response.statusCode}');
      print('Response body: $responseBody');

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);

        if (data['message'] == 'Login successful') {
          if (mounted) {
            final user = data['user'];
            final role = user['role'];
            final token = data['token'];

            // Save login info to SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', token);
            await prefs.setString('role', role);
            await prefs.setString('user', json.encode(user));
            if (role == 'student') {
              await prefs.setString('student', json.encode(data['student']));
              await prefs.setString('enrolledSubjects',
                  json.encode(data['enrolledSubjects'] ?? []));
            } else if (role == 'teacher') {
              await prefs.setString('teacher', json.encode(data['teacher']));
              await prefs.setString(
                  'teacherSubjects', json.encode(data['teacherSubjects']));
            }

            switch (role) {
              case 'admin':
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const AdminHomeScreen(),
                  ),
                );
                break;
              case 'teacher':
                final user = data['user'];
                final teacher = data['teacher'];
                final teacherSubjects = data['teacherSubjects'];
                print('Teacher data: $teacher');
                print('Teacher subjects: $teacherSubjects');
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
                break;
              case 'student':
                final user = data['user'];
                final enrolledSubjects = data['enrolledSubjects'] ?? [];
                final student = data['student'];
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
                break;
              default:
                setState(() {
                  _error = 'Invalid role: $role';
                });
            }
          }
        } else {
          final msg = (data['message'] == 'Invalid credentials')
              ? 'Invalid phone number or password. Please try again.'
              : (data['message'] ?? 'Login failed');
          showError(msg);
        }
      } else {
        // Try to parse error message from response body
        try {
          final data = json.decode(responseBody);
          final msg = (data['message'] == 'Invalid credentials')
              ? 'Invalid phone number or password. Please try again.'
              : (data['message'] ?? 'Server error: ${response.reasonPhrase}');
          showError(msg);
        } catch (e) {
          showError('Server error: ${response.reasonPhrase}');
        }
      }
    } on TimeoutException {
      showError(
          'Connection timed out. Please check your internet connection and try again.');
    } on SocketException {
      showError(
          'Unable to connect to the server. Please check your internet connection.');
    } catch (e) {
      print('Login error: $e');
      showError('An error occurred. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double logoSize = 70;
    return Scaffold(
      body: Stack(
        children: [
          // Animated vibrant gradient background
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOutCubic,
            builder: (context, value, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(AppColors.primary, AppColors.secondary, value)!,
                      Color.lerp(AppColors.primaryLight, AppColors.secondary, value)!,
                    ],
                  ),
                ),
              );
            },
          ),
          // Animated login card
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.9, end: 1.0),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) => Transform.scale(
                      scale: scale,
                      child: child,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.10),
                            blurRadius: 18,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Animated glowing logo
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.7, end: 1.0),
                              duration: const Duration(seconds: 2),
                              curve: Curves.easeInOutCubic,
                              builder: (context, glow, child) {
                                return Container(
                                  width: logoSize + 14,
                                  height: logoSize + 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.22 * glow),
                                        blurRadius: 24 * glow,
                                        spreadRadius: 4 * glow,
                                      ),
                                      BoxShadow(
                                        color: AppColors.secondary.withOpacity(0.13 * glow),
                                        blurRadius: 16 * glow,
                                        spreadRadius: 2 * glow,
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primary.withOpacity(0.18),
                                          AppColors.secondary.withOpacity(0.13),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.school,
                                        size: logoSize,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 18),
                            // App name
                            Text(
                              'Tuition App',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                                letterSpacing: 1.2,
                                fontFamily: 'Montserrat',
                                shadows: [
                                  Shadow(
                                    color: AppColors.primary.withOpacity(0.10),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Tagline
                            Text(
                              'Login to continue your learning',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 28),
                            // Phone Number Field
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: TextStyle(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                labelStyle: TextStyle(color: AppColors.textSecondary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.primary),
                                ),
                                prefixIcon: Icon(Icons.phone, color: AppColors.primary),
                                filled: true,
                                fillColor: AppColors.cardBackground,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              style: TextStyle(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(color: AppColors.textSecondary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.primary),
                                ),
                                prefixIcon: Icon(Icons.lock, color: AppColors.primary),
                                filled: true,
                                fillColor: AppColors.cardBackground,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              obscureText: _obscurePassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isLoading
                                      ? AppColors.primary.withOpacity(0.5)
                                      : AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 350),
                                  child: _isLoading
                                      ? SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3.5,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Login',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
