import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import '../../models/teacher.dart';
import '../login_screen.dart';
import '../../models/student.dart';
import '../../controllers/teacher_controller.dart';
import 'widgets/student_card.dart';
import 'widgets/student_details_sheet.dart';
import 'widgets/student_list_header.dart';
import 'widgets/attendance_section.dart';
import 'widgets/attendance_history_section.dart';
import 'widgets/teacher_form.dart';
import 'widgets/add_student.dart';
import 'package:tuition/core/themes/app_colors.dart';
import 'class_student_list_screen.dart';
import '../../controllers/teacher_controller.dart';
import '../../models/teacher_subject.dart';
import 'package:flutter/rendering.dart';

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
    _loadTeachers();
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

  Future<void> _loadTeachers() async {
    try {
      final response = await http.post(
          Uri.parse('http://27.116.52.24:8076/getData'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({"table": "Teacher"}));

      if (response.statusCode == 200) {
        // Check if response is JSON
        if (response.headers['content-type']?.contains('application/json') ??
            false) {
          final data = json.decode(response.body);
          setState(() {
            _teachers = (data['data'] ?? []);
            print(_teachers.toList());
            if (_teachers.isEmpty) {
              _error = 'No Teacher Available';
            } else {
              _error = null;
            }
          });
        } else {
          print(
              'Invalid response format: Expected JSON but got ${response.headers['content-type']}');
          setState(() {
            _teachers = [];
          });
        }
      } else {
        print(
            'Failed to load teachers: ${response.statusCode} ${response.reasonPhrase}');
        setState(() {
          _teachers = [];
        });
      }
    } catch (e) {
      print('Error loading teachers: $e');
      setState(() {
        _teachers = [];
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
    ).then((_) => _loadTeachers()); // Refresh the list when returning
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.glassBorder,
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
            splashRadius: 24,
          ),
        ),
        centerTitle: false,
        title: const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text(
            'Admin Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
        ),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.primaryGradient,
                ),
              ),
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.glassBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.glassBorder,
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
              splashRadius: 24,
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Students Tab
          Scaffold(
            body: RefreshIndicator(
              onRefresh: () async {
                await _loadStudents();
                await _loadTeachers();
              },
              child: Column(
                children: [
                  if (_isLoading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadStudents,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: _buildGroupedStudentList(),
                    ),
                ],
              ),
            ),
          ),
          // Teachers Tab
          Scaffold(
            body: RefreshIndicator(
              onRefresh: () async {
                await _loadTeachers();
                setState(() {}); // Trigger rebuild of FutureBuilder
              },
              child: FutureBuilder<List<Teacher>>(
                future: TeacherController().getAllTeachers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    print(snapshot.error);
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {}); // Trigger rebuild
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final teachers = snapshot.data ?? [];

                  if (teachers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.school_outlined,
                              size: 48,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No teachers found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF328ECC),
                          Color(0xFF1A4B7C),
                        ],
                      ),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: teachers.length,
                      itemBuilder: (context, index) {
                        final teacher = teachers[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Material(
                                color: Colors.transparent,
                                child: ExpansionTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      teacher.fname[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    teacher.fullName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Contact: ${teacher.contact}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  iconColor: Colors.white,
                                  collapsedIconColor:
                                      Colors.white.withOpacity(0.8),
                                  children: [
                                    if (teacher.classes == null ||
                                        teacher.classes!.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Text(
                                          'No classes assigned',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.8),
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      )
                                    else
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Assigned Classes & Subjects:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            ...teacher.classes!
                                                .map((classInfo) => Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              bottom: 8.0),
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                      0.2),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                              border:
                                                                  Border.all(
                                                                color: Colors
                                                                    .white
                                                                    .withOpacity(
                                                                        0.3),
                                                                width: 1,
                                                              ),
                                                            ),
                                                            child: const Icon(
                                                              Icons.class_,
                                                              size: 16,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                            child: Text(
                                                              'Class ${classInfo.className} - ${classInfo.subjectName} (${classInfo.medium})',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                color: Colors
                                                                    .white
                                                                    .withOpacity(
                                                                        0.8),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ))
                                                .toList(),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          // Combined Attendance Tab
          Scaffold(
            body: RefreshIndicator(
              onRefresh: () async {
                // Refresh attendance data
                setState(() {
                  _selectedAttendanceTab = _selectedAttendanceTab;
                });
              },
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildAttendanceTabButton(
                                  title: 'Take Attendance',
                                  icon: Icons.calendar_today,
                                  isSelected: _selectedAttendanceTab == 0,
                                  onTap: () => setState(
                                      () => _selectedAttendanceTab = 0),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _buildAttendanceTabButton(
                                  title: 'History',
                                  icon: Icons.history,
                                  isSelected: _selectedAttendanceTab == 1,
                                  onTap: () => setState(
                                      () => _selectedAttendanceTab = 1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _selectedAttendanceTab,
                      children: const [
                        AttendanceSection(),
                        AttendanceHistorySection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedIndex < 2
          ? FloatingActionButton(
              heroTag:
                  _selectedIndex == 0 ? 'add_student_fab' : 'add_teacher_fab',
              onPressed: _selectedIndex == 0
                  ? _showAddStudentForm
                  : _showAddTeacherForm,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.primaryGradient,
              ),
              border: Border(
                top: BorderSide(
                  color: AppColors.glassBorder,
                  width: 1,
                ),
              ),
            ),
            child: BottomNavigationBar(
              items: [
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.glassBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.glassBorder,
                        width: 1,
                      ),
                    ),
                    child: const Icon(Icons.people),
                  ),
                  label: 'Students',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.glassBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.glassBorder,
                        width: 1,
                      ),
                    ),
                    child: const Icon(Icons.school),
                  ),
                  label: 'Teachers',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.glassBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.glassBorder,
                        width: 1,
                      ),
                    ),
                    child: const Icon(Icons.calendar_today),
                  ),
                  label: 'Attendance',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white.withOpacity(0.5),
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              onTap: _onItemTapped,
            ),
          ),
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
              color: Colors.grey[400],
            ),
            const SizedBox(height: 10),
            Text(
              'No students found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
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

    final classNames = classGroups.keys.toList()..sort();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF328ECC),
            Color(0xFF1A4B7C),
          ],
        ),
      ),
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
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
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
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${students.length} Students',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
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
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAttendanceTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF328ECC) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
