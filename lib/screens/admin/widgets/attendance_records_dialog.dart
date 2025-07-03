import 'package:flutter/material.dart';
import '../../../controllers/teacher_controller.dart';
import '../../../models/teacher.dart';
import '../../../services/attendance_service.dart';
import '../../../widgets/attendance_ui_utils.dart';

class AttendanceRecordsDialog extends StatefulWidget {
  const AttendanceRecordsDialog({Key? key}) : super(key: key);

  @override
  _AttendanceRecordsDialogState createState() =>
      _AttendanceRecordsDialogState();
}

class _AttendanceRecordsDialogState extends State<AttendanceRecordsDialog> {
  // Filter options
  Teacher? selectedTeacher;
  Map<String, dynamic>? selectedClassData;
  DateTime? startDate;
  DateTime? endDate;
  String? selectedStatus; // 'all', 'present', 'absent'

  // Data lists
  List<Teacher> teachers = [];
  List<dynamic> teacherClasses = [];
  List<dynamic> attendanceRecords = [];
  List<dynamic> filteredRecords = [];

  // Loading states
  bool isLoadingTeachers = false;
  bool isLoadingClasses = false;
  bool isLoadingRecords = false;
  String? error;

  // Filter states
  bool showAdvancedFilters = false;
  bool isFiltering = false;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
    // Set default date range to current month
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, 1);
    endDate = DateTime(now.year, now.month + 1, 0);
  }

  Future<void> _loadTeachers() async {
    setState(() {
      isLoadingTeachers = true;
    });
    try {
      teachers = await TeacherController().getAllTeachers();
    } catch (e) {
      setState(() {
        error = 'Error loading teachers: $e';
      });
    }
    setState(() {
      isLoadingTeachers = false;
    });
  }

  Future<void> _onTeacherSelected(Teacher? teacher) async {
    setState(() {
      selectedTeacher = teacher;
      selectedClassData = null;
      teacherClasses = [];
      isLoadingClasses = true;
    });

    if (teacher != null) {
      try {
        teacherClasses = await AttendanceService.getClassesForTeacher(
          teacherId: teacher.id,
        );
        print(
            'Loaded ${teacherClasses.length} classes for teacher ${teacher.id}');
      } catch (e) {
        setState(() {
          error = 'Error loading classes: $e';
        });
        teacherClasses = [];
      }
    }
    setState(() {
      isLoadingClasses = false;
    });
  }

  Future<void> _onClassSelected(dynamic classData) async {
    setState(() {
      selectedClassData = classData as Map<String, dynamic>?;
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF667eea),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
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
        context,
        'Please select all required filters',
        isError: true,
      );
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
        startDate: startDate!.toIso8601String().split('T')[0],
        endDate: endDate!.toIso8601String().split('T')[0],
      );

      setState(() {
        attendanceRecords = records;
        filteredRecords = records;
      });

      print('Loaded ${records.length} attendance records');

      // Apply current filters
      _applyFilters();
    } catch (e) {
      setState(() {
        error = 'Error loading attendance records: $e';
        attendanceRecords = [];
        filteredRecords = [];
      });
      print('Error loading attendance records: $e');
    } finally {
      setState(() {
        isLoadingRecords = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      isFiltering = true;
    });

    List<dynamic> filtered = List.from(attendanceRecords);

    // Apply status filter
    if (selectedStatus != null && selectedStatus != 'all') {
      filtered = filtered
          .where((record) => record['status'] == selectedStatus)
          .toList();
    }

    setState(() {
      filteredRecords = filtered;
      isFiltering = false;
    });
  }

  void _clearFilters() {
    setState(() {
      selectedStatus = null;
      filteredRecords = attendanceRecords;
    });
  }

  void _exportRecords() {
    // TODO: Implement export functionality
    AttendanceUIUtils.showSnackBar(
      context,
      'Export functionality will be implemented soon',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Enhanced Header Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Enhanced Icon Container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.1)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.history,
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
                            'Attendance Records',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Filter and view attendance history',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Enhanced Close Button
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Enhanced Filter Section
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Filter Controls
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Date Range Selection
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE3F2FD), Color(0xFFF3E5F5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: Colors.blue.withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.date_range,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Date Range',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    Text(
                                      startDate != null && endDate != null
                                          ? '${startDate!.day}/${startDate!.month}/${startDate!.year} - ${endDate!.day}/${endDate!.month}/${endDate!.year}'
                                          : 'Select date range',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.blue, Color(0xFF1976D2)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _selectDateRange,
                                    borderRadius: BorderRadius.circular(8),
                                    child: const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Teacher Selection
                        AttendanceUIUtils.buildFilterCard(
                          title: 'Teacher',
                          icon: Icons.person,
                          isLoading: isLoadingTeachers,
                          child: DropdownButton<Teacher>(
                            isExpanded: true,
                            value: selectedTeacher,
                            hint: const Text('Choose teacher',
                                style: TextStyle(fontSize: 14)),
                            items: teachers
                                .map((t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t.fullName,
                                          style: const TextStyle(fontSize: 14)),
                                    ))
                                .toList(),
                            onChanged: _onTeacherSelected,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Class Selection
                        if (selectedTeacher != null)
                          AttendanceUIUtils.buildFilterCard(
                            title: 'Class & Subject',
                            icon: Icons.school,
                            isLoading: isLoadingClasses,
                            child: DropdownButton<dynamic>(
                              isExpanded: true,
                              value: selectedClassData,
                              hint: const Text('Choose class and subject',
                                  style: TextStyle(fontSize: 14)),
                              items: teacherClasses
                                  .map((c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(
                                            '${c['class']} - ${c['subjectName']} (${c['medium']})',
                                            style:
                                                const TextStyle(fontSize: 14)),
                                      ))
                                  .toList(),
                              onChanged: _onClassSelected,
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Action Buttons Row
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4CAF50),
                                      Color(0xFF45A049)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _loadAttendanceRecords,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (isLoadingRecords)
                                            const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            )
                                          else
                                            const Icon(Icons.search,
                                                color: Colors.white, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            isLoadingRecords
                                                ? 'Loading...'
                                                : 'Search Records',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2196F3),
                                    Color(0xFF1976D2)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      showAdvancedFilters =
                                          !showAdvancedFilters;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Icon(
                                      showAdvancedFilters
                                          ? Icons.filter_list_off
                                          : Icons.filter_list,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Advanced Filters
                        if (showAdvancedFilters) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.tune,
                                        color: Colors.orange[700], size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Advanced Filters',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Status Filter
                                DropdownButtonFormField<String>(
                                  value: selectedStatus,
                                  decoration: const InputDecoration(
                                    labelText: 'Status Filter',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'all', child: Text('All')),
                                    DropdownMenuItem(
                                        value: 'present',
                                        child: Text('Present Only')),
                                    DropdownMenuItem(
                                        value: 'absent',
                                        child: Text('Absent Only')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedStatus = value;
                                    });
                                    _applyFilters();
                                  },
                                ),
                                const SizedBox(height: 12),
                                // Filter Actions
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _clearFilters,
                                        icon: const Icon(Icons.clear),
                                        label: const Text('Clear Filters'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[600],
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _exportRecords,
                                        icon: const Icon(Icons.download),
                                        label: const Text('Export'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange[600],
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Results Section
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildResultsSection(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              error!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAttendanceRecords,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (selectedClassData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Select filters to view attendance records',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (isLoadingRecords) {
      return const Center(child: CircularProgressIndicator());
    }

    if (attendanceRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No attendance records found',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different date range or criteria',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Summary
    final presentCount =
        filteredRecords.where((record) => record['status'] == 'present').length;
    final absentCount =
        filteredRecords.where((record) => record['status'] == 'absent').length;
    final totalCount = filteredRecords.length;

    return Column(
      children: [
        // Summary Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Column(
            children: [
              // Filter Info
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Showing ${filteredRecords.length} of ${attendanceRecords.length} records',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Summary Cards
              Row(
                children: [
                  AttendanceUIUtils.buildSummaryCardForStatistics(
                    label: 'Total',
                    count: totalCount,
                    color: Colors.blue,
                    icon: Icons.people,
                  ),
                  const SizedBox(width: 12),
                  AttendanceUIUtils.buildSummaryCardForStatistics(
                    label: 'Present',
                    count: presentCount,
                    color: Colors.green,
                    icon: Icons.check_circle,
                  ),
                  const SizedBox(width: 12),
                  AttendanceUIUtils.buildSummaryCardForStatistics(
                    label: 'Absent',
                    count: absentCount,
                    color: Colors.red,
                    icon: Icons.cancel,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Records List
        Expanded(
          child: isFiltering
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredRecords.length,
                  itemBuilder: (context, index) {
                    final record = filteredRecords[index];
                    final studentName = record['studentName'] ?? 'Unknown';
                    final status = record['status'] ?? 'unknown';
                    final isPresent = status == 'present';
                    final date = record['date'] ?? 'Unknown';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isPresent
                              ? [Colors.white, Color(0xFFF8FFF8)]
                              : [Colors.white, Color(0xFFFFF8F8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isPresent
                              ? Colors.green.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isPresent ? Colors.green : Colors.grey)
                                .withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isPresent
                                  ? [Colors.green, Color(0xFF4CAF50)]
                                  : [Colors.grey, Color(0xFF757575)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (isPresent ? Colors.green : Colors.grey)
                                    .withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white,
                            child: Text(
                              studentName.isNotEmpty
                                  ? studentName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: isPresent ? Colors.green : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          studentName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'ID: ${record['studentId'] ?? 'N/A'}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Date: $date',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isPresent
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isPresent
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            isPresent ? 'Present' : 'Absent',
                            style: TextStyle(
                              color: isPresent ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
