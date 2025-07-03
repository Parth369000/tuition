import 'package:flutter/material.dart';
import 'package:tuition/core/themes/app_colors.dart';
import 'class_details_screen.dart';
import 'teacher_profile_screen.dart';
import '../login_screen.dart';
import '../../widgets/liquid_glass_painter.dart';
import 'package:tuition/services/attendance_service.dart';

class TeacherDashboard extends StatefulWidget {
  final String teacherId;
  final String token;
  final Map<String, dynamic> user;
  final Map<String, dynamic> teacher;
  final List<dynamic> teacherSubjects;

  const TeacherDashboard({
    super.key,
    required this.teacherId,
    required this.token,
    required this.user,
    required this.teacher,
    required this.teacherSubjects,
  });

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  late List<dynamic> _teacherSubjects;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _teacherSubjects = List.from(widget.teacherSubjects);
  }

  Future<void> _refreshSubjects() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final subjects = await AttendanceService.getClassesForTeacher(
        teacherId: int.parse(widget.teacher['id'].toString()),
      );
      setState(() {
        _teacherSubjects = subjects;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh classes: \$e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToClassDetails(
      String classKey, String subject, String subjectId, String medium) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassDetailsScreen(
          userId: int.parse(widget.teacherId),
          teacherId: int.parse(widget.teacher['id'].toString()),
          classKey: classKey,
          subject: subject,
          subjectId: subjectId,
          batch: medium,
        ),
      ),
    );
  }

  String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return parts.take(2).map((e) => e[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2A4759),
                Color(0xFF1E3440),
                Color(0xFF152A35),
              ],
            ),
          ),
        ),
        title: const Text(
          'Teacher Dashboard',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TeacherProfileScreen(
                    user: widget.user,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.cardBackground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  title: Text('Logout', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  content: Text('Are you sure you want to logout?', style: TextStyle(color: AppColors.textPrimary)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      child: Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Classes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshSubjects,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _teacherSubjects.isEmpty
                            ? Center(
                                child: Text(
                                  'No classes assigned',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _teacherSubjects.length,
                                itemBuilder: (context, index) {
                                  final subjectData = _teacherSubjects[index];
                                  final classKey = subjectData['class'] ?? '';
                                  final className = subjectData['subjectName'] ?? '';
                                  final medium = subjectData['medium'] ?? '';
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Material(
                                      color: Colors.transparent,
                                      elevation: 3,
                                      borderRadius: BorderRadius.circular(18),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(18),
                                        onTap: () => _navigateToClassDetails(
                                          subjectData['class'].toString(),
                                          subjectData['subjectName'],
                                          subjectData['subjectId'].toString(),
                                          subjectData['medium'],
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.cardBackground,
                                            borderRadius: BorderRadius.circular(18),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.06),
                                                blurRadius: 8,
                                                offset: Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 24,
                                                backgroundColor: AppColors.secondary,
                                                child: Text(
                                                  getInitials(className),
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      subjectData['class'] + 'th ' + className,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.textPrimary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Medium: $medium',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: AppColors.textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(
                                                Icons.arrow_forward_ios_outlined,
                                                color: AppColors.secondary,
                                                size: 28,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
