import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/themes/app_colors.dart';
import '../../widgets/liquid_glass_painter.dart';

class StudentReportScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? student;
  final List<dynamic>? enrolledSubjects;

  const StudentReportScreen({
    Key? key,
    this.user,
    this.student,
    this.enrolledSubjects,
  }) : super(key: key);

  @override
  State<StudentReportScreen> createState() => _StudentReportScreenState();
}

class _StudentReportScreenState extends State<StudentReportScreen> {
  bool _loadingAttendance = true;
  bool _loadingTests = true;
  String? _attendanceError;
  String? _testError;
  List<dynamic> _attendanceData = [];
  List<dynamic> _testMarks = [];

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
    _fetchTestMarks();
  }

  Future<void> _fetchAttendance() async {
    setState(() {
      _loadingAttendance = true;
      _attendanceError = null;
    });
    try {
      final response = await http.post(
        Uri.parse('http://27.116.52.24:8076/getAttendanceForStudent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'studentId': widget.student?['id']}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['errorStatus'] == false) {
          setState(() {
            _attendanceData = data['data'] ?? [];
          });
        } else {
          setState(() {
            _attendanceError = 'Failed to load attendance data.';
          });
        }
      } else {
        setState(() {
          _attendanceError = 'Failed: ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        _attendanceError = 'Error: $e';
      });
    } finally {
      setState(() {
        _loadingAttendance = false;
      });
    }
  }

  Future<void> _fetchTestMarks() async {
    setState(() {
      _loadingTests = true;
      _testError = null;
    });
    try {
      final response = await http.post(
        Uri.parse('http://27.116.52.24:8076/getStudentTestMarks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'studentId': widget.student?['id']}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['errorStatus'] == false) {
          setState(() {
            _testMarks = data['data'] ?? [];
          });
        } else {
          setState(() {
            _testError = 'Failed to load test marks.';
          });
        }
      } else {
        setState(() {
          _testError = 'Failed: ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        _testError = 'Error: $e';
      });
    } finally {
      setState(() {
        _loadingTests = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student ?? {};
    final subjects = widget.enrolledSubjects ?? [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Report'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchAttendance();
          await _fetchTestMarks();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Academic Info
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(22),
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.13),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(14),
                        child: const Icon(Icons.school,
                            color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Academic Information',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _infoRow('Name',
                      '${student['fname'] ?? ''} ${student['mname'] ?? ''} ${student['lname'] ?? ''}'),
                  const SizedBox(height: 6),
                  _infoRow('Board', student['board'] ?? '-'),
                  const SizedBox(height: 6),
                  _infoRow('School', student['school'] ?? '-'),
                  const SizedBox(height: 6),
                  _infoRow('Medium', student['medium'] ?? '-'),
                  const SizedBox(height: 6),
                  _infoRow('Class', student['class'] ?? '-'),
                  const SizedBox(height: 6),
                  _infoRow('Batch', student['batch'] ?? '-'),
                  const SizedBox(height: 6),
                  _infoRow(
                      'Total Fee',
                      student['feeTotal'] != null
                          ? '₹${NumberFormat('#,##0').format(int.tryParse(student['feeTotal'].toString()) ?? 0)}'
                          : '-'),
                ],
              ),
            ),
            // Attendance Report
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: const Icon(Icons.pie_chart,
                            color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Attendance Report',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _loadingAttendance
                      ? const Center(child: CircularProgressIndicator())
                      : _attendanceError != null
                          ? _errorWidget(_attendanceError!,
                              onRetry: _fetchAttendance)
                          : _attendanceData.isEmpty
                              ? _emptyWidget('No attendance data found')
                              : _attendanceCharts(_attendanceData, subjects),
                ],
              ),
            ),
            // Test Report
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: const Icon(Icons.bar_chart,
                            color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Test Report',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _loadingTests
                      ? const Center(child: CircularProgressIndicator())
                      : _testError != null
                          ? _errorWidget(_testError!, onRetry: _fetchTestMarks)
                          : _testMarks.isEmpty
                              ? _emptyWidget('No test marks found')
                              : _testBarChart(_testMarks, subjects),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceCharts(List<dynamic> data, List<dynamic> subjects) {
    // Group by subject (only present)
    final Map<String, int> subjectCounts = {};
    int presentCount = 0;
    int absentCount = 0;
    for (var entry in data) {
      final subject = entry['subjectName'] ?? 'Unknown';
      final isPresent =
          (entry['status'] ?? '').toString().toLowerCase() == 'present';
      if (isPresent) {
        subjectCounts[subject] = (subjectCounts[subject] ?? 0) + 1;
        presentCount++;
      } else {
        absentCount++;
      }
    }
    final int totalRecords = data.length;
    final int totalPresent = presentCount;
    final int totalAbsent = absentCount;
    final double percentPresent =
        totalRecords > 0 ? (totalPresent / totalRecords) * 100 : 0.0;
    // For demo, assume total possible is 100 per subject (or you can adjust if you have real total sessions)
    final int totalSubjects = subjectCounts.length;
    final int totalPossible = totalSubjects > 0 ? totalSubjects * 100 : 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subject-wise attendance pie chart
        Text(
          'Subject-wise Attendance',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sections: subjectCounts.entries.map((e) {
                final color = _subjectColor(e.key);
                return PieChartSectionData(
                  color: color,
                  value: e.value.toDouble(),
                  title: '${e.key}\n${e.value}',
                  radius: 60,
                  titleStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 30,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: subjectCounts.keys.map((subject) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _subjectColor(subject),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                Text(subject, style: TextStyle(color: AppColors.textPrimary)),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        // Overall attendance pie chart
        Text(
          'Overall Attendance',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  color: Colors.green,
                  value: totalPresent.toDouble(),
                  title: 'Present\n$totalPresent',
                  radius: 48,
                  titleStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                PieChartSectionData(
                  color: Colors.redAccent,
                  value: totalAbsent > 0
                      ? totalAbsent.toDouble()
                      : 0.1, // show a sliver if 0
                  title: 'Absent\n$totalAbsent',
                  radius: 48,
                  titleStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Total Attendance Records: $totalRecords',
          style: TextStyle(
              color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          'Present: $totalPresent',
          style: TextStyle(
            color: AppColors.success,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Attendance: ${percentPresent.toStringAsFixed(1)}%',
          style: TextStyle(
            color: AppColors.success,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _testBarChart(List<dynamic> data, List<dynamic> subjects) {
    // Group marks by subject
    final Map<String, List<int>> subjectMarks = {};
    for (var entry in data) {
      final subject = entry['subjectName'] ?? 'Unknown';
      final marks = entry['marks'] ?? 0;
      subjectMarks.putIfAbsent(subject, () => []).add(marks);
    }
    final subjectList = subjectMarks.keys.toList();
    final maxY = 30.0;
    // Calculate overall
    int totalObtained = 0;
    int totalPossible = 0;
    for (var marks in subjectMarks.values) {
      totalObtained += marks.fold(0, (a, b) => a + b);
      totalPossible += marks.length * 30;
    }
    final double overallPercent =
        totalPossible > 0 ? (totalObtained / totalPossible) * 100 : 0.0;
    Color percentColor = overallPercent >= 75
        ? AppColors.success
        : overallPercent >= 50
            ? AppColors.primary
            : AppColors.error;
    // Assign visually distinct colors for up to 3 subjects
    List<Color> barColors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success
    ];
    Color getBarColor(int i) => barColors[i % barColors.length];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subject-wise Test Report
        Text(
          'Subject-wise Test Report',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 1,
            constraints: const BoxConstraints(maxWidth: 370),
            height: 350,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                maxY: maxY,
                minY: 0,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        if (value % 10 == 0) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= subjectList.length)
                          return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            subjectList[idx],
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.cardBackground,
                    strokeWidth: 1,
                  ),
                ),
                barGroups: List.generate(subjectList.length, (i) {
                  final marks = subjectMarks[subjectList[i]]!;
                  final avg = marks.isNotEmpty
                      ? marks.reduce((a, b) => a + b) / marks.length
                      : 0.0;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: avg,
                        color: getBarColor(i),
                        width: 15,
                        borderRadius: BorderRadius.circular(8),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: AppColors.primary.withOpacity(0.05),
                        ),
                        rodStackItems: [],
                        borderSide: BorderSide.none,
                      ),
                    ],
                    showingTooltipIndicators: [0],
                    barsSpace: 8,
                  );
                }),
              ),
              swapAnimationDuration: const Duration(milliseconds: 500),
              swapAnimationCurve: Curves.easeOutCubic,
            ),
          ),
        ),
        const SizedBox(height: 15),
        Center(
          child: Wrap(
            spacing: 20,
            runSpacing: 8,
            children: List.generate(subjectList.length, (i) {
              final subject = subjectList[i];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: getBarColor(i),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(subject, style: TextStyle(color: AppColors.textPrimary)),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 24),
        // Overall Test Report
        Text(
          'Overall Test Report',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Total Marks Obtained: $totalObtained / $totalPossible',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Overall Percentage: ${overallPercent.toStringAsFixed(1)}%',
          style: TextStyle(
            color: percentColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ],
    );
  }

  Color _subjectColor(String subject) {
    // Assign a unique color per subject
    final colors = [
      Colors.blueAccent,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.redAccent,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];
    final idx = subject.hashCode.abs() % colors.length;
    return colors[idx];
  }

  Widget _errorWidget(String error, {VoidCallback? onRetry}) {
    return Column(
      children: [
        Icon(Icons.error_outline, color: AppColors.error, size: 32),
        const SizedBox(height: 8),
        Text(error, style: TextStyle(color: AppColors.error)),
        if (onRetry != null)
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
      ],
    );
  }

  Widget _emptyWidget(String message) {
    return Column(
      children: [
        Icon(Icons.info_outline, color: AppColors.textSecondary, size: 32),
        const SizedBox(height: 8),
        Text(message, style: TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}
