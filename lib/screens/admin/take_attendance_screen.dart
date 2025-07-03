import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../controllers/teacher_controller.dart';
import '../../../models/teacher.dart';
import '../../../services/attendance_service.dart';
import '../../../widgets/attendance_ui_utils.dart';
import '../../../core/themes/app_colors.dart';

class TakeAttendanceScreen extends StatefulWidget {
  const TakeAttendanceScreen({Key? key}) : super(key: key);

  @override
  _TakeAttendanceScreenState createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  // Filter options
  Teacher? selectedTeacher;
  dynamic selectedClassData;
  DateTime selectedDate = DateTime.now();

  // Data lists
  List<Teacher> teachers = [];
  List<dynamic> teacherClasses = [];
  List<dynamic> students = [];
  Map<int, bool> attendanceStatus = {};

  // Loading states
  bool isLoadingTeachers = true;
  bool isLoadingClasses = false;
  bool isLoadingStudents = false;
  bool isSubmitting = false;
  String? error;
  bool attendanceTaken = false;

  // Add a flag to control showing filters and find button
  bool showStudentListOnly = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() => isLoadingTeachers = true);
    try {
      teachers = await TeacherController().getAllTeachers();
    } catch (e) {
      if (mounted) setState(() => error = 'Error loading teachers: $e');
    } finally {
      if (mounted) setState(() => isLoadingTeachers = false);
    }
  }

  Future<void> _onTeacherSelected(Teacher? teacher) async {
    if (teacher == null || teacher == selectedTeacher) return;

    setState(() {
      selectedTeacher = teacher;
      selectedClassData = null;
      teacherClasses = [];
      students = [];
      attendanceStatus = {};
      attendanceTaken = false;
      isLoadingClasses = true;
    });

    try {
      teacherClasses =
          await AttendanceService.getClassesForTeacher(teacherId: teacher.id);
    } catch (e) {
      if (mounted) setState(() => error = 'Error loading classes: $e');
      teacherClasses = [];
    } finally {
      if (mounted) setState(() => isLoadingClasses = false);
    }
  }

  Future<void> _onClassSelected(dynamic classData) async {
    if (classData == null || classData == selectedClassData) return;
    setState(() {
      selectedClassData = classData;
      students = [];
      attendanceStatus = {};
      attendanceTaken = false;
    });
    await _loadStudents();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF667eea)),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        students = [];
        attendanceStatus = {};
        attendanceTaken = false;
      });
      await _loadStudents();
    }
  }

  Future<void> _loadStudents() async {
    if (selectedTeacher == null || selectedClassData == null) return;

    setState(() {
      isLoadingStudents = true;
      error = null;
    });

    try {
      final studentList = await AttendanceService.getStudentsForTeacher(
        teacherId: selectedTeacher!.id,
        className: selectedClassData!['class'],
        subjectId: selectedClassData!['subjectId'],
        medium: selectedClassData!['medium'] ?? '',
      );
      if (mounted) {
        setState(() {
          students = studentList;
          attendanceStatus = {
            for (var s in students) s['id']: true
          }; // Default to present
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = 'Error loading students: $e');
    } finally {
      if (mounted) setState(() => isLoadingStudents = false);
    }
  }

  void _submitAttendance() async {
    if (isSubmitting || attendanceTaken) return;

    setState(() => isSubmitting = true);

    int successCount = 0;
    int errorCount = 0;
    int alreadyMarkedCount = 0;

    for (var entry in attendanceStatus.entries) {
      final studentId = entry.key;
      final isPresent = entry.value;
      try {
        final result = await AttendanceService.submitAttendance(
          teacherId: selectedTeacher!.id.toString(),
          studentId: studentId.toString(),
          date: DateFormat('yyyy-MM-dd').format(selectedDate),
          status: isPresent ? "present" : "absent",
          subjectId: selectedClassData!['subjectId'].toString(),
          medium: selectedClassData!['medium'] ?? '',
        );

        if (result['errorStatus'] == false) {
          successCount++;
        } else {
          final message = result['msg'] as String? ?? '';
          if (message.contains('Attendance already marked')) {
            alreadyMarkedCount++;
          } else {
            errorCount++;
          }
        }
      } catch (e) {
        errorCount++;
      }
    }

    if (mounted) {
      setState(() {
        isSubmitting = false;
        if (errorCount == 0) {
          attendanceTaken = true;
          showStudentListOnly = true;
        }
      });

      String snackBarMessage;
      bool isError = false;

      if (errorCount > 0) {
        snackBarMessage = "$errorCount submissions failed. Please try again.";
        isError = true;
      } else if (successCount > 0 && alreadyMarkedCount > 0) {
        snackBarMessage =
            "$successCount marked, $alreadyMarkedCount were already marked.";
      } else if (successCount > 0) {
        snackBarMessage =
            "Attendance submitted successfully for $successCount students!";
      } else if (alreadyMarkedCount > 0) {
        snackBarMessage =
            "Attendance was already marked for all selected students.";
      } else {
        snackBarMessage = "No changes to submit.";
      }

      AttendanceUIUtils.showSnackBar(context, snackBarMessage,
          isError: isError);
    }
  }

  void _showFilterDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
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
                  color: AppColors.primary.withOpacity(0.3), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Find Students',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDateCard(),
                    const SizedBox(height: 12),
                    _buildFilterDropdownCard(
                      title: 'Teacher',
                      icon: Icons.person_outline,
                      isLoading: isLoadingTeachers,
                      child: DropdownButton<Teacher>(
                        isExpanded: true,
                        value: selectedTeacher,
                        hint: const Text('Choose teacher',
                            style: TextStyle(color: AppColors.textSecondary)),
                        underline: const SizedBox.shrink(),
                        dropdownColor: Colors.white,
                        items: teachers
                            .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.fullName,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary))))
                            .toList(),
                        onChanged: (teacher) async {
                          Navigator.of(context).pop();
                          await _onTeacherSelected(teacher);
                          _showFilterDialog();
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (selectedTeacher != null)
                      _buildFilterDropdownCard(
                        title: 'Class & Subject',
                        icon: Icons.school_outlined,
                        isLoading: isLoadingClasses,
                        child: DropdownButton<dynamic>(
                          isExpanded: true,
                          value: selectedClassData,
                          hint: const Text('Choose class & subject',
                              style: TextStyle(color: AppColors.textSecondary)),
                          underline: const SizedBox.shrink(),
                          dropdownColor: Colors.white,
                          items: teacherClasses
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                        '${c['class']} - ${c['subjectName']} (${c['medium']})',
                                        style: const TextStyle(
                                            color: AppColors.textPrimary)),
                                  ))
                              .toList(),
                          onChanged: (classData) {
                            Navigator.of(context).pop();
                            _onClassSelected(classData);
                            _showFilterDialog();
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    Container(
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
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: (selectedTeacher != null &&
                                selectedClassData != null)
                            ? () async {
                                Navigator.of(context).pop();
                                setState(() {
                                  isLoadingStudents = true;
                                });
                                await _loadStudents();
                                setState(() {
                                  showStudentListOnly = true;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.search, color: Colors.white),
                        label: const Text('Find Students',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          disabledBackgroundColor:
                              AppColors.textSecondary.withOpacity(0.1),
                          disabledForegroundColor: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.scaffoldBackground,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Container(
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
        padding: const EdgeInsets.fromLTRB(20, 20, 10, 10),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Take Attendance',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
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
            const Spacer(),
            IconButton(
              onPressed: _showFilterDialog,
              icon: const Icon(Icons.checklist_outlined, color: Colors.white),
              tooltip: 'Find Students',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(34),
          topRight: Radius.circular(34),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        child: Column(
          children: [
            Expanded(child: _buildStudentList()),
            if (students.isNotEmpty) _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF8F9FA),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined,
              color: AppColors.textPrimary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Attendance Date',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                Text(
                  DateFormat.yMMMd().format(selectedDate),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _selectDate,
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdownCard({
    required String title,
    required IconData icon,
    required bool isLoading,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF8F9FA),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: child),
          if (isLoading)
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                )),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    if (isLoadingStudents) {
      return const Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)));
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _loadStudents,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (students.isEmpty) {
      return const Center(
          child: Text("Select a teacher and class to see students.",
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        final studentId = student['id'];
        final isPresent = attendanceStatus[studentId] ?? true;

        return Container(
          margin: const EdgeInsets.only(bottom: 12, top: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Color(0xFFF8F9FA),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.primary.withOpacity(0.3), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isPresent
                        ? [
                            const Color(0xFF81C784), // Soft green
                            const Color(0xFFB2DFDB), // Lighter green
                          ]
                        : [
                            const Color(0xFFE57373), // Soft red
                            const Color(0xFFFFCDD2), // Lighter red
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isPresent
                          ? const Color(0xFF81C784).withOpacity(0.25)
                          : const Color(0xFFE57373).withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    student['fname']?.substring(0, 1).toUpperCase() ?? '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${student['fname']} ${student['lname']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        )),
                    const SizedBox(height: 4),
                    Text('ID: $studentId',
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Switch(
                value: isPresent,
                onChanged: attendanceTaken
                    ? null
                    : (value) {
                        setState(() {
                          attendanceStatus[studentId] = value;
                        });
                      },
                activeColor: attendanceTaken
                    ? const Color(0xFFBDBDBD)
                    : const Color(0xFF388E3C), // Harmonious green
                activeTrackColor: attendanceTaken
                    ? const Color(0xFFE0E0E0)
                    : const Color(0xFF81C784).withOpacity(0.3),
                inactiveThumbColor: attendanceTaken
                    ? const Color(0xFFBDBDBD)
                    : const Color(0xFFD32F2F), // Harmonious red
                inactiveTrackColor: attendanceTaken
                    ? const Color(0xFFE0E0E0)
                    : const Color(0xFFE57373).withOpacity(0.3),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    final bool isDisabled = isSubmitting || attendanceTaken;
    final bool isSuccess = attendanceTaken;
    List<Color> gradientColors = isDisabled
        ? [
            AppColors.success, AppColors.success.withOpacity(0.7)
          ]
        : (isSuccess
            ? [AppColors.success, AppColors.success.withOpacity(0.7)]
            : [AppColors.primary, Color(0xFFE67E22)]);
    Color iconColor = Colors.white;
    Color textColor = Colors.white;
    String label = isSubmitting
        ? 'Submitting...'
        : (attendanceTaken ? 'Attendance Submitted' : 'Submit Attendance');
    IconData icon = isSubmitting
        ? Icons.hourglass_top
        : (attendanceTaken ? Icons.check_circle : Icons.check_circle_outline);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: isDisabled ? null : _submitAttendance,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSubmitting)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Icon(icon, color: iconColor, size: 26),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: textColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
