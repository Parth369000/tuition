import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tuition/screens/admin/widgets/TeachersTabWidget.dart';
import 'dart:convert';
import 'dart:async';
import '../../controllers/subject_controller.dart';
import '../../models/subject.dart';
import '../../models/teacher.dart';
import '../../models/teacher_class.dart';
import '../login_screen.dart';
import '../../models/student.dart';
import '../../controllers/teacher_controller.dart';
import 'widgets/student_card.dart';
import 'widgets/student_details_sheet.dart';
import 'widgets/student_list_header.dart';
import 'widgets/teacher_form.dart';
import 'widgets/add_student.dart';
import 'package:tuition/core/themes/app_colors.dart';
import 'class_student_list_screen.dart';
import 'package:flutter/rendering.dart';
import 'attendance_records_screen.dart';
import 'take_attendance_screen.dart';
import 'admin_materials_screen.dart';
import 'admin_report_students_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  List<dynamic> _students = [];
  List<dynamic> _filteredStudents = [];
  List<dynamic> _teachers = [];
  bool _isLoading = false;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  int _selectedIndex = 0;
  Timer? _debounce;
  int _selectedAttendanceTab = 0;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _filterStudents(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        if (query.isEmpty) {
          _filteredStudents = _students;
        } else {
          _filteredStudents = _students.where((student) {
            final searchLower = query.toLowerCase();
            switch (_selectedFilter) {
              case 'Name':
                return '${student['fname']} ${student['lname']}'
                    .toLowerCase()
                    .contains(searchLower);
              case 'ID':
                return student['id'].toLowerCase().contains(searchLower);
              case 'Class':
                return student['class']?.toLowerCase().contains(searchLower) ??
                    false;
              case 'Batch':
                return student['batch']?.toLowerCase().contains(searchLower) ??
                    false;
              default:
                return '${student['fname']} ${student['lname']}'
                        .toLowerCase()
                        .contains(searchLower) ||
                    student['id'].toLowerCase().contains(searchLower) ||
                    (student['class']?.toLowerCase().contains(searchLower) ??
                        false) ||
                    (student['batch']?.toLowerCase().contains(searchLower) ??
                        false);
            }
          }).toList();
        }
      });
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _filteredStudents = _students;
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (_searchController.text.isNotEmpty) {
        _filterStudents(_searchController.text);
      }
    });
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://27.116.52.24:8076/getAllStudents'),
      );

      if (response.statusCode == 200) {
        // Check if response is JSON
        if (response.headers['content-type']?.contains('application/json') ??
            false) {
          final data = json.decode(response.body);
          setState(() {
            _students = data['data'] ?? [];
            _filteredStudents = _students;
            // sorting students by class
            _filteredStudents.sort((a, b) {
              final classA = a['class']?.toString() ?? '';
              final classB = b['class']?.toString() ?? '';
              return classA.compareTo(classB);
            });
            _isLoading = false;
          });
        } else {
          throw Exception(
              'Invalid response format: Expected JSON but got ${response.headers['content-type']}');
        }
      } else {
        throw Exception(
            'Failed to load students: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading students: $e';
        _isLoading = false;
      });
    }
  }

  void _showStudentDetails(dynamic student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StudentDetailsSheet(
        student: student,
      ),
    );
  }

  void _showAddStudentForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StudentFormWidget(),
      ),
    ).then((_) => _loadStudents()); // Refresh the list when returning
  }

  void _showAddTeacherForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TeacherForm(),
      ),
    ).then((_) => TeachersTabWidget()); // Refresh the list when returning
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.glassBorder,
            width: 1.5,
          ),
        ),
        title: Text(
          'Logout',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      ),
    );
  }

  void showError(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.school,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
          ),
        ),
        centerTitle: false,
        title: const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            'Admin Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 22,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 1),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2A4759), // Your dark blue-gray
                Color(0xFF1E3440), // Darker blue-gray
                Color(0xFF152A35), // Deepest blue-gray
              ],
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.logout,
                color: Colors.white,
                size: 20,
              ),
              onPressed: _logout,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 20,
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Students Tab
          Scaffold(
            backgroundColor: AppColors.scaffoldBackground,
            body: Container(
              color: AppColors.scaffoldBackground,
              child: RefreshIndicator(
                color: AppColors.primaryLight,
                backgroundColor: AppColors.scaffoldBackground,
                onRefresh: () async {
                  await _loadStudents();
                },
                child: Stack(
                  children: [
                    // Main content (student list)
                    if (!_isLoading && _error == null)
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                            child: Row(
                              children: [
                                const Icon(Icons.people,
                                    color: AppColors.primaryDark, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Total Students: ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                Text(
                                  _filteredStudents.length.toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.primary),
                                ),
                                const Spacer(),
                                Container(
                                  // decorate the button
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.add_circle_outline,
                                            color: AppColors.secondary,
                                            size: 28),
                                        tooltip: 'Add Student',
                                        onPressed: _showAddStudentForm,
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 10.0),
                                        child: Text(
                                          'Add Student',
                                          style: TextStyle(
                                            color: AppColors.secondary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _buildGroupedStudentList(),
                          ),
                        ],
                      ),
                    // Loading indicator
                    if (_isLoading)
                      Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    // Error message
                    if (_error != null && !_isLoading)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _error!,
                              style: TextStyle(color: AppColors.error),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadStudents,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Teachers Tab
          Container(
            color: AppColors.scaffoldBackground,
            child: TeachersTabWidget(),
          ),
          // Attendance Tab
          Container(
            color: AppColors.scaffoldBackground,
            child: Scaffold(
              backgroundColor: AppColors.scaffoldBackground,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: AppColors.primary,
                        size: 72,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Attendance Management',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Mark and manage student attendance with ease',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildAttendanceActionCard(
                      context,
                      icon: Icons.assignment_turned_in,
                      title: 'Take Attendance',
                      subtitle: 'Mark daily student attendance',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TakeAttendanceScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildAttendanceActionCard(
                      context,
                      icon: Icons.history,
                      title: 'View Records',
                      subtitle: 'Check attendance history and analytics',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AttendanceRecordsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Materials Tab
          AdminMaterialsScreen(),
          // Report Tab
          AdminReportStudentsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2A4759), // Your dark blue-gray
              Color(0xFF1E3440), // Darker blue-gray
              Color(0xFF152A35), // Even darker for depth
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, -2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.people),
              ),
              label: 'Students',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school),
              ),
              label: 'Teachers',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_today),
              ),
              label: 'Attendance',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.folder),
              ),
              label: 'Materials',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.pie_chart_outline),
              ),
              label: 'Report',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.white70,
          backgroundColor: Colors.transparent,
          elevation: 4,
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Widget _buildGroupedStudentList() {
    if (_filteredStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 10),
            Text(
              'No students found',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Group students by class
    final Map<String, List<dynamic>> classGroups = {};
    for (var student in _filteredStudents) {
      final className = student['class']?.toString() ?? 'Unknown';
      final medium = student['medium']?.toString() ?? 'Unknown';
      final classWithMedium = '$className ($medium)';
      classGroups.putIfAbsent(classWithMedium, () => []).add(student);
    }

    final classNames = classGroups.keys.toList()
      ..sort((a, b) {
        final numA = int.tryParse(a.split(' ').first) ?? 0;
        final numB = int.tryParse(b.split(' ').first) ?? 0;
        return numA.compareTo(numB);
      });

    return Container(
      color: AppColors.scaffoldBackground,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: classNames.length,
        itemBuilder: (context, classIdx) {
          final className = classNames[classIdx];
          final students = classGroups[className]!;
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClassStudentListScreen(
                    className: className,
                    students: students,
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Color(0xFFF8F9FA),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClassStudentListScreen(
                          className: className,
                          students: students,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary,
                                Color(0xFFE67E22),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.class_,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Class $className',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${students.length} Students',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary,
                                Color(0xFFE67E22),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAttendanceActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xFFF8F9FA),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    Color(0xFFE67E22),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    Color(0xFFE67E22),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
