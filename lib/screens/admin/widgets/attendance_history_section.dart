import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../../../controllers/teacher_controller.dart';
import '../../../models/teacher.dart';
import '../../../models/teacher_class.dart';
import '../../../core/themes/app_colors.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:get/get.dart';
import '../../../controllers/subject_controller.dart';
import '../../../models/subject.dart';

class AttendanceHistorySection extends StatefulWidget {
  const AttendanceHistorySection({Key? key}) : super(key: key);

  @override
  State<AttendanceHistorySection> createState() =>
      _AttendanceHistorySectionState();
}

class _AttendanceHistorySectionState extends State<AttendanceHistorySection> {
  final List<String> _classes = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10'
  ];
  String? _selectedClass;
  String? _selectedSubject;
  List<Map<String, dynamic>> _subjects = [];
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  List<dynamic> _attendanceRecords = [];
  bool _isLoading = false;
  String? _error;
  final TextEditingController _subjectController = TextEditingController();

  // Calendar related variables
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};

  @override
  void initState() {
    super.initState();
    _subjectController.addListener(_onSubjectChanged);
    _loadSubjects();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  void _onSubjectChanged() {
    setState(() {
      _selectedSubject = _subjectController.text;
    });
  }

  Future<void> _loadSubjects() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      var headers = {'Content-Type': 'application/json'};
      var request =
          http.Request('POST', Uri.parse('http://27.116.52.24:8076/getData'));
      request.body = json.encode({"table": "Subject"});
      request.headers.addAll(headers);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['errorStatus'] == false) {
          setState(() {
            _subjects = List<Map<String, dynamic>>.from(data['data'] ?? []);
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = data['message'] ?? 'Failed to load subjects';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load subjects: ${response.reasonPhrase}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load subjects: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _onClassSelected(String? className) async {
    setState(() {
      _selectedClass = className;
      _selectedSubject = null;
      _subjects = [];
    });

    if (className != null) {
      await _fetchSubjects(className);
    }
  }

  Future<void> _fetchSubjects(String className) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      var headers = {'Content-Type': 'application/json'};
      var request =
          http.Request('POST', Uri.parse('http://27.116.52.24:8076/getData'));
      request.body = json.encode({"table": "Subject"});
      request.headers.addAll(headers);

      print('Fetching subjects for class: $className');
      print('Request body: ${request.body}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['errorStatus'] == false) {
          final subjects = List<Map<String, dynamic>>.from(data['data'] ?? []);
          print('Loaded subjects: $subjects');
          setState(() {
            _subjects = subjects;
            _isLoading = false;
            // Reset subject selection when subjects are loaded
            _selectedSubject = null;
            _subjectController.clear();
          });
        } else {
          setState(() {
            _error = data['message'] ?? 'Failed to load subjects';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load subjects: ${response.reasonPhrase}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching subjects: $e');
      setState(() {
        _error = 'Failed to load subjects: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAttendanceHistory() async {
    if (_selectedClass == null) {
      setState(() {
        _error = 'Please select a class';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      var headers = {'Content-Type': 'application/json'};
      var request = http.Request(
          'POST', Uri.parse('http://27.116.52.24:8076/getAttendance'));
      request.body = json.encode({
        "teacherId": 2,
        "class": _selectedClass!,
        "subjectId":
            _selectedSubject != null ? int.parse(_selectedSubject!) : 0,
        "medium": "",
        "startDate": _startDate.toIso8601String().split('T')[0],
        "endDate": _endDate.toIso8601String().split('T')[0]
      });
      request.headers.addAll(headers);

      print('Request body: ${request.body}'); // Debug print

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response body: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['errorStatus'] == false) {
          setState(() {
            _attendanceRecords = data['data'] ?? [];
            _isLoading = false;
            // Check for specific message about no students found
            if (data['msg']?.toString().toLowerCase().contains(
                    'No students found for this teacher in the given class/batch/subject/medium.') ==
                true) {
              _error =
                  'No students found for this teacher in the given class/batch/subject/medium.';
            } else {
              _error = null;
            }
          });
        } else {
          setState(() {
            _error = data['msg'] ?? 'Failed to load attendance history';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error =
              'Failed to load attendance history: ${response.reasonPhrase}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _loadAttendanceHistory: $e'); // Debug print
      setState(() {
        _error = 'Failed to load attendance history: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _showFilterDialog() async {
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Attendance',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Class Selection
                  _buildDropdown<String>(
                    value: _selectedClass,
                    items: _classes,
                    hint: 'Select Class',
                    onChanged: (className) async {
                      if (className != null) {
                        await _fetchSubjects(className);
                        setDialogState(() {
                          _selectedClass = className;
                        });
                      }
                    },
                    itemBuilder: (className) => className,
                  ),
                  const SizedBox(height: 16),
                  // Subject Selection (only shown if class is selected)
                  if (_selectedClass != null)
                    _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : _buildDropdown<Map<String, dynamic>>(
                            value:
                                _selectedSubject != null && _subjects.isNotEmpty
                                    ? _subjects.firstWhere(
                                        (subject) =>
                                            subject['id'].toString() ==
                                            _selectedSubject,
                                        orElse: () => _subjects.first,
                                      )
                                    : null,
                            items: _subjects,
                            hint: 'Select Subject',
                            onChanged: (subject) {
                              if (subject != null) {
                                setDialogState(() {
                                  _selectedSubject = subject['id'].toString();
                                  _subjectController.text =
                                      subject['id'].toString();
                                });
                                setState(() {
                                  _selectedSubject = subject['id'].toString();
                                  _subjectController.text =
                                      subject['id'].toString();
                                });
                              }
                            },
                            itemBuilder: (subject) =>
                                subject['name'] ?? 'Unknown Subject',
                          ),
                  const SizedBox(height: 16),
                  // Date Selection
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start Date',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: AppColors.primary,
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
                                  setDialogState(() {
                                    _startDate = picked;
                                  });
                                  setState(() {
                                    _startDate = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat('dd/MM/yyyy')
                                          .format(_startDate),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.calendar_today,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'End Date',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate,
                                  firstDate: _startDate,
                                  lastDate: DateTime.now(),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: AppColors.primary,
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
                                  setDialogState(() {
                                    _endDate = picked;
                                  });
                                  setState(() {
                                    _endDate = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(_endDate),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.calendar_today,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            _selectedClass = null;
                            _selectedSubject = null;
                            _subjects = [];
                            _startDate = DateTime.now()
                                .subtract(const Duration(days: 30));
                            _endDate = DateTime.now();
                          });
                          setState(() {
                            _selectedClass = null;
                            _selectedSubject = null;
                            _subjects = [];
                            _startDate = DateTime.now()
                                .subtract(const Duration(days: 30));
                            _endDate = DateTime.now();
                          });
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Reset',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if (_selectedClass == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a class'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          await _loadAttendanceHistory();
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Apply Filters'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                onPressed: _showFilterDialog,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else if (_error != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _error!.toLowerCase().contains('no students found')
                        ? Icons.people_outline
                        : Icons.error_outline,
                    color: Colors.white.withOpacity(0.7),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else if (_attendanceRecords.isEmpty)
            const Center(
              child: Text(
                'No attendance records found',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _attendanceRecords.length,
                itemBuilder: (context, index) {
                  final record = _attendanceRecords[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    record['studentName'] ?? 'Unknown Student',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Roll No: ${record['rollNo'] ?? 'N/A'}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: (record['status']
                                                ?.toString()
                                                .toLowerCase() ==
                                            'present'
                                        ? Colors.green
                                        : Colors.red)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: (record['status']
                                                  ?.toString()
                                                  .toLowerCase() ==
                                              'present'
                                          ? Colors.green
                                          : Colors.red)
                                      .withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                record['status']?.toString().toUpperCase() ??
                                    'UNKNOWN',
                                style: TextStyle(
                                  color: record['status']
                                              ?.toString()
                                              .toLowerCase() ==
                                          'present'
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Date: ${DateFormat('dd MMM yyyy').format(DateTime.parse(record['date'] ?? DateTime.now().toIso8601String()))}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStat(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<T> items,
    required String hint,
    required Function(T?) onChanged,
    required String Function(T) itemBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: DropdownButton<T>(
        value: value,
        hint: Text(
          hint,
          style: const TextStyle(color: Colors.white70),
        ),
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: AppColors.primary,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        style: const TextStyle(color: Colors.white),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              itemBuilder(item),
              style: const TextStyle(color: Colors.white),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _processAttendanceData() {
    _events.clear();
    for (var record in _attendanceRecords) {
      final date = DateTime.parse(record['date']);
      final key = DateTime(date.year, date.month, date.day);

      if (!_events.containsKey(key)) {
        _events[key] = [];
      }
      _events[key]!.add(record);
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }
}
