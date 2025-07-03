import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import '../../core/themes/app_colors.dart';

class AdminStudentAttendanceReportScreen extends StatefulWidget {
  final int studentId;
  final String studentName;
  final String? studentClass;
  final int? studentDbId;
  final String? fname;
  final String? mname;
  final String? lname;
  final String? contact;
  final String? parentContact;
  final String? bdate;
  final String? board;
  final String? school;
  final String? medium;
  final String? feeTotal;
  const AdminStudentAttendanceReportScreen(
      {Key? key,
      required this.studentId,
      required this.studentName,
      this.studentClass,
      this.studentDbId,
      this.fname,
      this.mname,
      this.lname,
      this.contact,
      this.parentContact,
      this.bdate,
      this.board,
      this.school,
      this.medium,
      this.feeTotal})
      : super(key: key);

  @override
  State<AdminStudentAttendanceReportScreen> createState() =>
      _AdminStudentAttendanceReportScreenState();
}

class _AdminStudentAttendanceReportScreenState
    extends State<AdminStudentAttendanceReportScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> attendanceData = [];

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http.post(
        Uri.parse('http://27.116.52.24:8076/getAttendanceForStudent'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'studentId': widget.studentId}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['errorStatus'] == false && data['data'] != null) {
          setState(() {
            attendanceData = data['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'No attendance data found.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to fetch attendance.';
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

  Map<String, Map<String, int>> _groupAttendanceBySubject() {
    // { subjectName: {present: x, absent: y} }
    final Map<String, Map<String, int>> result = {};
    for (final record in attendanceData) {
      final subject = record['subjectName'] ?? 'Unknown';
      final status = record['status'] ?? 'absent';
      result.putIfAbsent(subject, () => {'present': 0, 'absent': 0});
      result[subject]![status] = (result[subject]![status] ?? 0) + 1;
    }
    return result;
  }

  List<PieChartSectionData> _buildPieSections(Map<String, int> subjectData) {
    final total = (subjectData['present'] ?? 0) + (subjectData['absent'] ?? 0);
    if (total == 0) return [];
    return [
      PieChartSectionData(
        color: Colors.green,
        value: (subjectData['present'] ?? 0).toDouble(),
        radius: 45,
      ),
      PieChartSectionData(
        color: Colors.red,
        value: (subjectData['absent'] ?? 0).toDouble(),
        radius: 40,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupAttendanceBySubject();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attendance Report',
          style: TextStyle(
            fontSize: 17,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
              color: AppColors.primary,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ))
          : _error != null
              ? Center(child: Text(_error!))
              : grouped.isEmpty
                  ? const Center(child: Text('No attendance data.'))
                  : Container(
                      color: AppColors.scaffoldBackground,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Student Details Card
                          Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.only(bottom: 22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Gradient header with initials
                                Container(
                                  width: double.infinity,
                                  height: 60,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primaryDark,
                                        AppColors.primary
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(18),
                                      topRight: Radius.circular(18),
                                    ),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              AppColors.primary,
                                              AppColors.primaryDark
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          (widget.fname != null &&
                                                  widget.fname!.isNotEmpty)
                                              ? widget.fname![0].toUpperCase()
                                              : '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 22,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          [
                                            widget.fname,
                                            widget.mname,
                                            widget.lname
                                          ]
                                              .where((s) =>
                                                  s != null && s.isNotEmpty)
                                              .join(' '),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 19,
                                            letterSpacing: 0.5,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 8,
                                        children: [
                                          if (widget.studentClass != null &&
                                              widget.studentClass!.isNotEmpty)
                                            _InfoChip(
                                                icon: Icons.class_,
                                                label:
                                                    'Class: ${widget.studentClass}'),
                                          if (widget.medium != null &&
                                              widget.medium!.isNotEmpty)
                                            _InfoChip(
                                                icon: Icons.language,
                                                label:
                                                    'Medium: ${widget.medium}'),
                                          if (widget.board != null &&
                                              widget.board!.isNotEmpty)
                                            _InfoChip(
                                                icon: Icons.school,
                                                label:
                                                    'Board: ${widget.board}'),
                                          if (widget.feeTotal != null &&
                                              widget.feeTotal!.isNotEmpty)
                                            _InfoChip(
                                                icon: Icons.attach_money,
                                                label:
                                                    'Fee: ₹${widget.feeTotal}'),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Divider(
                                          color: AppColors.cardBackground,
                                          thickness: 1),
                                      const SizedBox(height: 8),
                                      if (widget.contact != null &&
                                          widget.contact!.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.phone,
                                                  size: 18,
                                                  color: AppColors.primaryDark),
                                              const SizedBox(width: 6),
                                              Text('Contact: ${widget.contact}',
                                                  style: const TextStyle(
                                                      fontSize: 15)),
                                            ],
                                          ),
                                        ),
                                      if (widget.parentContact != null &&
                                          widget.parentContact!.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.family_restroom,
                                                  size: 18,
                                                  color: AppColors.primaryDark),
                                              const SizedBox(width: 6),
                                              Text(
                                                  'Parent: ${widget.parentContact}',
                                                  style: const TextStyle(
                                                      fontSize: 15)),
                                            ],
                                          ),
                                        ),
                                      if (widget.bdate != null &&
                                          widget.bdate!.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.cake,
                                                  size: 18,
                                                  color: AppColors.primaryDark),
                                              const SizedBox(width: 6),
                                              Text('Birthdate: ${widget.bdate}',
                                                  style: const TextStyle(
                                                      fontSize: 15)),
                                            ],
                                          ),
                                        ),
                                      if (widget.school != null &&
                                          widget.school!.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.apartment,
                                                  size: 18,
                                                  color: AppColors.primaryDark),
                                              const SizedBox(width: 6),
                                              Text('School: ${widget.school}',
                                                  style: const TextStyle(
                                                      fontSize: 15)),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Attendance Chart Cards
                          ...grouped.entries.map((entry) {
                            final subject = entry.key;
                            final data = entry.value;
                            final present = data['present'] ?? 0;
                            final absent = data['absent'] ?? 0;
                            final total = present + absent;
                            return Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Vertical accent bar
                                  Container(
                                    width: 6,
                                    height: 140,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.primaryDark
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        bottomLeft: Radius.circular(16),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Pie chart
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 12.0),
                                            child: SizedBox(
                                              width: 90,
                                              height: 90,
                                              child: PieChart(
                                                PieChartData(
                                                  sections:
                                                      _buildPieSections(data),
                                                  centerSpaceRadius: 8,
                                                  sectionsSpace: 3,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          // Subject and summary
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.book,
                                                        color: AppColors
                                                            .primaryDark,
                                                        size: 18),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        subject,
                                                        style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Present: $present / $total',
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.primaryDark,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    _LegendDot(
                                                        color: Colors.green),
                                                    const SizedBox(width: 4),
                                                    const Text('Present',
                                                        style: TextStyle(
                                                            fontSize: 12)),
                                                    const SizedBox(width: 12),
                                                    _LegendDot(
                                                        color: Colors.red),
                                                    const SizedBox(width: 4),
                                                    const Text('Absent',
                                                        style: TextStyle(
                                                            fontSize: 12)),
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
                            );
                          }).toList(),
                        ],
                      ),
                    ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// Add helper widgets for info chips and status chips
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: AppColors.primaryDark),
      label: Text(label, style: const TextStyle(fontSize: 14)),
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }
}
