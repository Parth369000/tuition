import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import '../../../models/student.dart';
import '../../../models/teacher.dart';
import '../../../models/teacher_class.dart';
import '../../../controllers/teacher_controller.dart';
import '../../../core/themes/app_colors.dart';
import 'package:intl/intl.dart';

class AttendanceSection extends StatefulWidget {
  const AttendanceSection({Key? key}) : super(key: key);

  @override
  State<AttendanceSection> createState() => _AttendanceSectionState();
}

class _AttendanceSectionState extends State<AttendanceSection> {
  final TeacherController _teacherController = TeacherController();
  List<Teacher> _teachers = [];
  Teacher? _selectedTeacher;
  List<String> _classes = [];
  List<TeacherClass> _subjects = [];
  String? _selectedClass;
  String? _selectedSubjectId;
  bool _isLoading = false;
  String? _error;
  Map<int, bool> _attendance = {};
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;
  List<dynamic> _attendanceRecords = [];

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://27.116.52.24:8076/getData'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"table": "Teacher"}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['errorStatus'] == false) {
          final List<dynamic> teachersData = data['data'] ?? [];
          final List<Teacher> teachers =
              teachersData.map((json) => Teacher.fromJson(json)).toList();

          // Fetch classes for each teacher
          for (var teacher in teachers) {
            teacher.classes =
                await _teacherController.getTeacherClasses(teacher.id);
          }

          setState(() {
            _teachers = teachers;
            _isLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load teachers');
        }
      } else {
        throw Exception('Failed to load teachers: ${response.reasonPhrase}');
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading teachers: $e';
        _isLoading = false;
      });
    }
  }

  void _onTeacherSelected(Teacher? teacher) {
    setState(() {
      _selectedTeacher = teacher;
      _selectedClass = null;
      _selectedSubjectId = null;
      _classes =
          teacher?.classes?.map((c) => c.className).toSet().toList() ?? [];
      _classes.sort();
      _subjects = [];
    });
  }

  void _onClassSelected(String? className) {
    setState(() {
      _selectedClass = className;
      _selectedSubjectId = null;
      if (_selectedTeacher != null && className != null) {
        _subjects = _selectedTeacher!.classes
                ?.where((c) => c.className == className)
                .toList() ??
            [];
      }
    });
  }

  Future<void> _loadStudents() async {
    if (_selectedTeacher == null ||
        _selectedClass == null ||
        _selectedSubjectId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First check if attendance is already marked for today
      final today = DateTime.now().toIso8601String().split('T')[0];
      final checkResponse = await http.post(
        Uri.parse('http://27.116.52.24:8076/getAttendance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'teacherId': _selectedTeacher!.id,
          'class': _selectedClass,
          'subjectId': _selectedSubjectId,
          'startDate': today,
          'endDate': today,
        }),
      );

      if (checkResponse.statusCode == 200) {
        final checkData = jsonDecode(checkResponse.body);
        if (checkData['errorStatus'] == false &&
            checkData['data'] != null &&
            (checkData['data'] as List).isNotEmpty) {
          // Attendance already marked for today
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Attendance already marked for ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
          setState(() {
            _isLoading = false;
            _attendance = {};
          });
          return;
        }
      }

      // If no attendance marked for today, proceed to load students
      final response = await http.post(
        Uri.parse('http://27.116.52.24:8076/getStudentsForTeacher'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'teacherId': _selectedTeacher!.id,
          'class': _selectedClass,
          'subjectId': _selectedSubjectId,
          'medium': _subjects
              .firstWhere((s) =>
                  s.subjectId.toString() == _selectedSubjectId.toString())
              .medium,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['errorStatus'] == false) {
          final students = data['data'] as List;
          setState(() {
            _attendance = {for (var student in students) student['id']: false};
            _isLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load students');
        }
      } else {
        throw Exception('Failed to load students: ${response.reasonPhrase}');
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading students: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAttendance() async {
    if (_selectedTeacher == null ||
        _selectedClass == null ||
        _selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select teacher, class and subject'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final presentStudents = _attendance.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (presentStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please mark at least one student as present'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final selectedSubject = _subjects.firstWhere(
          (s) => s.subjectId.toString() == _selectedSubjectId.toString());

      // Submit attendance for each present student
      for (final studentId in presentStudents) {
        final request = http.Request(
          'POST',
          Uri.parse('http://27.116.52.24:8076/markAttendance'),
        );

        request.headers.addAll({
          'Content-Type': 'application/json',
        });

        request.body = json.encode({
          "teacherId": _selectedTeacher!.id,
          "studentId": studentId,
          "status": "present",
          "date": _selectedDate.toIso8601String().split('T')[0],
          "subjectId": selectedSubject.subjectId,
          "medium": selectedSubject.medium,
        });

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          if (data['errorStatus'] == false) {
            continue; // Continue with next student
          } else {
            // Check if the error is due to already marked attendance
            if (data['message']
                    ?.toString()
                    .toLowerCase()
                    .contains('already marked') ??
                false) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Attendance already marked for ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  ),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                  action: SnackBarAction(
                    label: 'OK',
                    textColor: Colors.white,
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                  ),
                ),
              );
              return;
            }
            throw Exception(data['message'] ?? 'Failed to submit attendance');
          }
        } else {
          throw Exception(
              'Failed to submit attendance: ${response.reasonPhrase}');
        }
      }

      // If we reach here, all submissions were successful
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset attendance after successful submission
      setState(() {
        _attendance = {};
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _loadAttendanceHistory() async {
    if (_selectedTeacher == null ||
        _selectedClass == null ||
        _selectedSubjectId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://27.116.52.24:8076/getAttendanceHistory'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'teacherId': _selectedTeacher!.id,
          'class': _selectedClass,
          'subjectId': int.parse(_selectedSubjectId!),
          'startDate': _selectedDate.toIso8601String().split('T')[0],
          'endDate': _selectedDate.toIso8601String().split('T')[0],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['errorStatus'] == false) {
          final records = data['data'] as List;
          setState(() {
            _attendanceRecords = records;
            _isLoading = false;
          });
        } else {
          throw Exception(
              data['message'] ?? 'Failed to load attendance history');
        }
      } else {
        throw Exception(
            'Failed to load attendance history: ${response.reasonPhrase}');
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading attendance history: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Filter Section
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.glassBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.filter_list,
                                color: Colors.white.withOpacity(0.7)),
                            const SizedBox(width: 8),
                            const Text(
                              'Filter Attendance',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            if (_selectedTeacher != null &&
                                _selectedClass != null &&
                                _selectedSubjectId != null)
                              IconButton(
                                icon: Icon(Icons.refresh,
                                    color: Colors.white.withOpacity(0.7)),
                                onPressed: _loadAttendanceHistory,
                                tooltip: 'Refresh',
                              ),
                          ],
                        ),
                        Divider(
                            height: 24, color: Colors.white.withOpacity(0.2)),
                        if (_isLoading)
                          const Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        else if (_error != null)
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: _loadTeachers,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Teacher Selection
                              _buildDropdown<Teacher>(
                                value: _selectedTeacher,
                                label: 'Select Teacher',
                                icon: Icons.person,
                                items: _teachers.map((teacher) {
                                  return DropdownMenuItem<Teacher>(
                                    value: teacher,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: const BorderRadius.all(
                                          Radius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        teacher.fullName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (Teacher? newValue) {
                                  setState(() {
                                    _selectedTeacher = newValue;
                                    _selectedClass = null;
                                    _selectedSubjectId = null;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),

                              // Class and Subject Selection
                              if (_selectedTeacher != null)
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDropdown<String>(
                                        value: _selectedClass,
                                        label: 'Select Class',
                                        icon: Icons.school,
                                        items: _classes.map((className) {
                                          return DropdownMenuItem<String>(
                                            value: className,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius:
                                                    const BorderRadius.all(
                                                  Radius.circular(8),
                                                ),
                                              ),
                                              child: Text(
                                                'Class $className',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            _selectedClass = newValue;
                                            _selectedSubjectId = null;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildDropdown<String>(
                                        value: _selectedSubjectId,
                                        label: 'Select Subject',
                                        icon: Icons.book,
                                        items: _subjects.map((subject) {
                                          return DropdownMenuItem<String>(
                                            value: subject.subjectId.toString(),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius:
                                                    const BorderRadius.all(
                                                  Radius.circular(8),
                                                ),
                                              ),
                                              child: Text(
                                                '${subject.subjectName} (${subject.medium})',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            _selectedSubjectId = newValue;
                                          });
                                          if (newValue != null) {
                                            _loadAttendanceHistory();
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 16),

                              // Date Range Selection
                              if (_selectedSubjectId != null) ...[
                                const Text(
                                  'Select Date Range',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildDateRangeSelector(),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Results Section
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.glassBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.history,
                                    color: Colors.white.withOpacity(0.7)),
                                const SizedBox(width: 8),
                                const Text(
                                  'Attendance Records',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                if (_attendanceRecords.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${_attendanceRecords.length} Records',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Divider(
                              height: 1, color: Colors.white.withOpacity(0.2)),
                          Expanded(
                            child: _buildAttendanceTable(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceTable() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadAttendanceHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_attendanceRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.white.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(
              'No attendance records found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Group attendance records by student
    final Map<String, List<dynamic>> studentRecords = {};
    for (var record in _attendanceRecords) {
      final studentName =
          '${record['Student']['fname']} ${record['Student']['lname']}';
      final studentId = record['studentId'].toString();
      final key = '$studentName ($studentId)';

      if (!studentRecords.containsKey(key)) {
        studentRecords[key] = [];
      }
      studentRecords[key]!.add(record);
    }

    // Sort students alphabetically
    final sortedStudents = studentRecords.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sortedStudents.length,
      itemBuilder: (context, index) {
        final studentKey = sortedStudents[index];
        final records = studentRecords[studentKey]!;

        // Calculate attendance statistics
        final totalDays = records.length;
        final presentDays =
            records.where((r) => r['status'] == 'present').length;
        final attendancePercentage =
            (presentDays / totalDays * 100).toStringAsFixed(1);

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(
                    studentKey[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  studentKey,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Wrap(
                  spacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: double.parse(attendancePercentage) >= 75
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$attendancePercentage%',
                        style: TextStyle(
                          color: double.parse(attendancePercentage) >= 75
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '$presentDays/$totalDays days',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance History',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...records.map((record) {
                          final isPresent = record['status'] == 'present';
                          final date = DateTime.parse(record['date']);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isPresent
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    DateFormat('dd\nMMM').format(date),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color:
                                          isPresent ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat('EEEE, MMMM d, y')
                                            .format(date),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Status: ${record['status'].toString().toUpperCase()}',
                                        style: TextStyle(
                                          color: isPresent
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DropdownButtonFormField<T>(
          value: value,
          dropdownColor: AppColors.glassBackground,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            errorStyle: const TextStyle(color: Colors.red),
          ),
          items: items,
          onChanged: onChanged,
          icon:
              Icon(Icons.arrow_drop_down, color: Colors.white.withOpacity(0.7)),
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    // Implementation of _buildDateRangeSelector method
    // This method should return a widget that allows the user to select a date range
    // You can use a DateRangePicker or a custom implementation to allow the user to select a date range
    return Container(); // Placeholder return, actual implementation needed
  }
}
