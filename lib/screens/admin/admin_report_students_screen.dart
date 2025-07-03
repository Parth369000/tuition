import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'admin_student_attendance_report_screen.dart';
import '../../core/themes/app_colors.dart';

class AdminReportStudentsScreen extends StatefulWidget {
  const AdminReportStudentsScreen({Key? key}) : super(key: key);

  @override
  State<AdminReportStudentsScreen> createState() =>
      _AdminReportStudentsScreenState();
}

class _AdminReportStudentsScreenState extends State<AdminReportStudentsScreen> {
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> filteredStudents = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStudents();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        filteredStudents = students;
      });
    } else {
      setState(() {
        filteredStudents = students.where((student) {
          final name = [student['fname'], student['mname'], student['lname']]
              .where((s) => s != null && s.toString().trim().isNotEmpty)
              .join(' ')
              .toLowerCase();
          final className = (student['class'] ?? '').toString().toLowerCase();
          final batch = (student['batch'] ?? '').toString().toLowerCase();
          final id = (student['id'] ?? '').toString().toLowerCase();
          return name.contains(query) ||
              className.contains(query) ||
              batch.contains(query) ||
              id.contains(query);
        }).toList();
      });
    }
  }

  Future<void> _fetchStudents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response =
          await http.post(Uri.parse('http://27.116.52.24:8076/getAllStudents'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['errorStatus'] == false && data['data'] != null) {
          setState(() {
            students = List<Map<String, dynamic>>.from(data['data']);
            filteredStudents = students;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'No students found.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to fetch students.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.scaffoldBackground,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.scaffoldBackground)))
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
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
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            filteredStudents.length.toString(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search students...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _searchController.clear();
                                    FocusScope.of(context).unfocus();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.cardBackground,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.primary,
                        backgroundColor: AppColors.scaffoldBackground,
                        onRefresh: _fetchStudents,
                        child: ListView.builder(
                          itemCount: filteredStudents.length,
                          itemBuilder: (context, idx) {
                            final student = filteredStudents[idx];
                            final fullName = [
                              student['fname'],
                              student['mname'],
                              student['lname']
                            ]
                                .where((s) =>
                                    s != null && s.toString().trim().isNotEmpty)
                                .join(' ');
                            final className =
                                student['class']?.toString() ?? '';
                            final batch = student['batch']?.toString() ?? '';

                            final initials =
                                (student['fname']?.isNotEmpty == true
                                    ? student['fname'][0]
                                    : '');
                            return Container(
                              margin: const EdgeInsets.only(
                                  top: 10, bottom: 8, left: 16, right: 16),
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
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AdminStudentAttendanceReportScreen(
                                          studentId: student['id'],
                                          studentName: fullName,
                                          studentClass: className,
                                          fname: student['fname'],
                                          mname: student['mname'],
                                          lname: student['lname'],
                                          contact: student['contact'],
                                          parentContact:
                                              student['parentContact'],
                                          bdate: student['bdate'],
                                          board: student['board'],
                                          school: student['school'],
                                          medium: student['medium'],
                                          feeTotal: student['feeTotal'],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 18),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                AppColors.primary,
                                                Color(0xFFE67E22),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                                spreadRadius: 0,
                                              ),
                                            ],
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            initials.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 18),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                fullName.isNotEmpty
                                                    ? fullName
                                                    : 'No Name',
                                                style: TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios,
                                            color: Colors.black38, size: 20),
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
    );
  }
}
