import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../../controllers/teacher_controller.dart';
import '../../../models/teacher.dart';
import '../../../services/attendance_service.dart';
import '../../../widgets/attendance_ui_utils.dart';
import '../../../core/themes/app_colors.dart';

class AttendanceRecordsScreen extends StatefulWidget {
  const AttendanceRecordsScreen({Key? key}) : super(key: key);

  @override
  _AttendanceRecordsScreenState createState() =>
      _AttendanceRecordsScreenState();
}

class _AttendanceRecordsScreenState extends State<AttendanceRecordsScreen> {
  // Filter options
  Teacher? selectedTeacher;
  dynamic selectedClassData;
  DateTime? startDate;
  DateTime? endDate;
  String? selectedStatus = 'all';

  // Data lists
  List<Teacher> teachers = [];
  List<dynamic> teacherClasses = [];
  List<dynamic> attendanceRecords = [];
  List<Map<String, dynamic>> filteredRecords = [];

  // Loading states
  bool isLoadingTeachers = true;
  bool isLoadingClasses = false;
  bool isLoadingRecords = false;
  String? error;

  // New filter dialog control
  bool showSummaryHeader = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, 1);
    endDate = now;
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

  void _onClassSelected(dynamic classData) {
    if (classData == null || classData == selectedClassData) return;
    setState(() => selectedClassData = classData);
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary, // header background color
            onPrimary: Colors.white, // header text color
            surface: Colors.white, // dialog background color
            onSurface: Colors.black, // default text color
          ),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.black), // calendar text color
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }

  Future<void> _loadAttendanceRecords() async {
    if (selectedTeacher == null ||
        selectedClassData == null ||
        startDate == null ||
        endDate == null) {
      AttendanceUIUtils.showSnackBar(
          context, 'Please select all required filters',
          isError: true);
      return;
    }

    setState(() {
      isLoadingRecords = true;
      error = null;
    });

    try {
      final records = await AttendanceService.getAttendanceRecords(
        teacherId: selectedTeacher!.id,
        className: selectedClassData!['class'],
        subjectId: selectedClassData!['subjectId'],
        medium: '',
        startDate: DateFormat('yyyy-MM-dd').format(startDate!),
        endDate: DateFormat('yyyy-MM-dd').format(endDate!),
      );
      if (mounted) {
        setState(() {
          attendanceRecords = records;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted)
        setState(() => error = 'Error loading attendance records: $e');
    } finally {
      if (mounted) setState(() => isLoadingRecords = false);
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(attendanceRecords);
    if (selectedStatus != null && selectedStatus != 'all') {
      filtered = filtered
          .where((record) => record['status'] == selectedStatus)
          .toList();
    }

    // Group records by student
    Map<String, List<Map<String, dynamic>>> groupedByStudent = {};
    for (var record in filtered) {
      String studentName = record['studentName'] ?? 'Unknown Student';
      if (!groupedByStudent.containsKey(studentName)) {
        groupedByStudent[studentName] = [];
      }
      groupedByStudent[studentName]!.add(record);
    }

    // Convert grouped data to list format for display
    List<Map<String, dynamic>> groupedRecords = [];
    groupedByStudent.forEach((studentName, records) {
      int presentCount = records.where((r) => r['status'] == 'present').length;
      int absentCount = records.where((r) => r['status'] == 'absent').length;
      int totalDays = records.length;

      groupedRecords.add({
        'studentName': studentName,
        'studentId': records.first['studentId'],
        'totalDays': totalDays,
        'presentCount': presentCount,
        'absentCount': absentCount,
        'attendancePercentage':
            totalDays > 0 ? (presentCount / totalDays * 100).round() : 0,
        'records': records,
      });
    });

    setState(() => filteredRecords = groupedRecords);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF2A4759),
              Color(0xFF1E3440),
              Color(0xFF152A35),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.18)),
              ),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Attendance Records',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _showFilterDialog,
              icon: const Icon(Icons.filter_list, color: Colors.white),
              tooltip: 'Filter',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 18,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        child: Column(
          children: [
            Expanded(child: _buildResultsSection()),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: AppColors.cardBackground,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient header
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF2A4759),
                      Color(0xFF1E3440),
                      Color(0xFF152A35),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.filter_list, color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Filter Options',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDateRangeCard(),
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
                          dropdownColor: AppColors.cardBackground,
                          items: teachers
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(
                                      t.fullName,
                                      style: const TextStyle(
                                          color: AppColors.textPrimary),
                                    ),
                                  ))
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
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                            underline: const SizedBox.shrink(),
                            dropdownColor: AppColors.cardBackground,
                            items: teacherClasses
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        '${c['class']} - ${c['subjectName']} (${c['medium']})',
                                        style: const TextStyle(
                                            color: AppColors.textPrimary),
                                      ),
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
                      ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _loadAttendanceRecords();
                        },
                        icon: isLoadingRecords
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ))
                            : const Icon(Icons.search),
                        label: Text(isLoadingRecords
                            ? 'Searching...'
                            : 'Search Records'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateRangeCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Date Range',
                    style:
                        TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                Text(
                  '${DateFormat.yMMMd().format(startDate!)} - ${DateFormat.yMMMd().format(endDate!)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _selectDateRange,
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
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
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

  Widget _buildResultsSection() {
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child:
                    Icon(Icons.error_outline, color: AppColors.error, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.error, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadAttendanceRecords,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (attendanceRecords.isEmpty && !isLoadingRecords) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.search_off,
                    color: AppColors.textSecondary, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                "No records found",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Please refine your search criteria",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (isLoadingRecords) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Loading attendance records...",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // Enhanced Summary header (always visible)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow.withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.bar_chart, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      "Attendance Summary",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildSummaryCardWithIcon(
                        icon: Icons.people_alt,
                        title: 'Total Students',
                        count: filteredRecords.length,
                        color: AppColors.cardBackground,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCardWithIcon(
                        icon: Icons.emoji_events,
                        title: 'Good Attendance',
                        count: filteredRecords
                            .where((r) => r['attendancePercentage'] >= 80)
                            .length,
                        color: AppColors.cardBackground,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCardWithIcon(
                        icon: Icons.warning_amber_rounded,
                        title: 'Needs Attention',
                        count: filteredRecords
                            .where((r) => r['attendancePercentage'] < 60)
                            .length,
                        color: AppColors.cardBackground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(
                    color: Colors.white.withOpacity(0.18),
                    thickness: 1,
                    height: 1),
              ],
            ),
          ),
          // Student list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            itemCount: filteredRecords.length,
            itemBuilder: (context, index) {
              return _buildEnhancedRecordCard(filteredRecords[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCardWithIcon({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withOpacity(0.13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.cardBackground, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2A4759),
                      Color(0xFF1E3440),
                      Color(0xFF152A35),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          // const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                  // maxLines: 2,
                  // overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedRecordCard(Map<String, dynamic> studentData) {
    final attendancePercentage = studentData['attendancePercentage'] as int;
    Color statusColor;
    if (attendancePercentage >= 80) {
      statusColor = AppColors.success;
    } else if (attendancePercentage >= 60) {
      statusColor = AppColors.warning;
    } else {
      statusColor = AppColors.error;
    }
    return GestureDetector(
      onTap: () => _showAttendanceCalendar(studentData),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow.withOpacity(0.13),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 70,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF2A4759),
                            Color(0xFF1E3440),
                            Color(0xFF152A35),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: AppColors.scaffoldBackground,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (studentData['studentName']?.substring(0, 1).toUpperCase() ?? '?'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  studentData['studentName'] ?? 'Unknown Student',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.13),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${attendancePercentage}%',
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttendanceCalendar(Map<String, dynamic> studentData) {
    final studentName = studentData['studentName'] as String;
    final records = studentData['records'] as List<Map<String, dynamic>>;

    // Create a map of dates to attendance status
    Map<String, String> dateToStatus = {};
    for (var record in records) {
      String date = record['date'] as String;
      String status = record['status'] as String;
      dateToStatus[date] = status;
    }

    // Use the selected date range for calendar navigation
    DateTime calendarStart = startDate ?? DateTime.now();
    DateTime calendarEnd = endDate ?? DateTime.now();
    DateTime initialMonth = DateTime(calendarStart.year, calendarStart.month);

    showDialog(
      context: context,
      builder: (context) => AttendanceCalendarDialog(
        studentName: studentName,
        dateToStatus: dateToStatus,
        calendarStart: calendarStart,
        calendarEnd: calendarEnd,
        initialMonth: initialMonth,
      ),
    );
  }
}

class AttendanceCalendarDialog extends StatefulWidget {
  final String studentName;
  final Map<String, String> dateToStatus;
  final DateTime calendarStart;
  final DateTime calendarEnd;
  final DateTime initialMonth;

  const AttendanceCalendarDialog({
    required this.studentName,
    required this.dateToStatus,
    required this.calendarStart,
    required this.calendarEnd,
    required this.initialMonth,
  });

  @override
  State<AttendanceCalendarDialog> createState() =>
      AttendanceCalendarDialogState();
}

class AttendanceCalendarDialogState extends State<AttendanceCalendarDialog> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.initialMonth;
  }

  void _goToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  bool get _canGoToPreviousMonth {
    return (_currentMonth.year > widget.calendarStart.year) ||
        (_currentMonth.year == widget.calendarStart.year &&
            _currentMonth.month > widget.calendarStart.month);
  }

  bool get _canGoToNextMonth {
    return (_currentMonth.year < widget.calendarEnd.year) ||
        (_currentMonth.year == widget.calendarEnd.year &&
            _currentMonth.month < widget.calendarEnd.month);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gradient header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF2A4759),
                    Color(0xFF1E3440),
                    Color(0xFF152A35),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      widget.studentName.substring(0, 1),
                      style: const TextStyle(
                        color: Color(0xFF2A4759),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.studentName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Attendance Calendar',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCalendarView(_currentMonth, widget.dateToStatus),
                  const SizedBox(height: 18),
                  _buildLegend(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarView(DateTime month, Map<String, String> dateToStatus) {
    return Column(
      children: [
        // Month header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _canGoToPreviousMonth ? _goToPreviousMonth : null,
              icon: const Icon(Icons.chevron_left, color: AppColors.primary),
            ),
            Text(
              DateFormat.yMMMM().format(month),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
            IconButton(
              onPressed: _canGoToNextMonth ? _goToNextMonth : null,
              icon: const Icon(Icons.chevron_right, color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Calendar grid
        _buildCalendarGrid(month, dateToStatus),
      ],
    );
  }

  Widget _buildCalendarGrid(DateTime month, Map<String, String> dateToStatus) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final firstWeekday = firstDay.weekday;
    final daysInMonth = lastDay.day;

    List<Widget> calendarDays = [];

    // Add empty cells for days before the first day of the month
    for (int i = 1; i < firstWeekday; i++) {
      calendarDays.add(const SizedBox(height: 40, width: 35));
    }

    // Add days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      final status = dateToStatus[dateString];

      Color backgroundColor;
      Color textColor;
      BoxBorder? border;

      if (status == 'present') {
        backgroundColor = AppColors.present;
        textColor = Colors.white;
        border = null;
      } else if (status == 'absent') {
        backgroundColor = AppColors.absent;
        textColor = Colors.white;
        border = null;
      } else {
        backgroundColor = Colors.white;
        textColor = AppColors.textSecondary;
        border = Border.all(color: AppColors.cardBackground, width: 1.2);
      }

      calendarDays.add(
        Container(
          width: 35,
          height: 40,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: border,
            boxShadow: status == null
                ? [
                    BoxShadow(
                      color: AppColors.cardShadow.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              day.toString(),
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Weekday headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((day) => SizedBox(
                    width: 35,
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: calendarDays,
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem('Present', AppColors.present),
        _buildLegendItem('Absent', AppColors.absent),
        _buildLegendItem('Not Taken', AppColors.textSecondary),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
