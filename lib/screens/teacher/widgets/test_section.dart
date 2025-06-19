import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tuition/core/themes/app_colors.dart';
import 'package:intl/intl.dart';

class TestSection extends StatefulWidget {
  final int teacherId;
  final String selectedClass;
  final String selectedBatch;
  final String subjectId;

  const TestSection({
    Key? key,
    required this.teacherId,
    required this.selectedClass,
    required this.selectedBatch,
    required this.subjectId,
  }) : super(key: key);

  @override
  State<TestSection> createState() => _TestSectionState();
}

class _TestSectionState extends State<TestSection>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _availableTests = [];
  List<Map<String, dynamic>> _completedTests = [];
  bool _isLoading = false;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load available tests
      final availableResponse = await http.post(
        Uri.parse('http://27.116.52.24:8076/getAvailableTests'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'teacherId': widget.teacherId,
        }),
      );

      // Load completed tests
      final completedResponse = await http.post(
        Uri.parse('http://27.116.52.24:8076/getPastTests'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'teacherId': widget.teacherId,
        }),
      );

      if (availableResponse.statusCode == 200 &&
          completedResponse.statusCode == 200) {
        final availableData = jsonDecode(availableResponse.body);
        final completedData = jsonDecode(completedResponse.body);

        if (availableData['errorStatus'] == false &&
            completedData['errorStatus'] == false) {
          // Filter available tests
          final availableTests =
              List<Map<String, dynamic>>.from(availableData['data'] ?? []);
          final filteredAvailableTests = availableTests.where((test) {
            return test['class'] == widget.selectedClass &&
                test['subjectId'].toString() == widget.subjectId;
          }).toList();

          // Filter completed tests
          final completedTests =
              List<Map<String, dynamic>>.from(completedData['data'] ?? []);
          final filteredCompletedTests = completedTests.where((test) {
            return test['class'] == widget.selectedClass &&
                test['subjectId'].toString() == widget.subjectId;
          }).toList();

          setState(() {
            _availableTests = filteredAvailableTests;
            _completedTests = filteredCompletedTests;
            _isLoading = false;
          });
        } else {
          throw Exception('Failed to load tests');
        }
      } else {
        throw Exception(
            'Failed to load tests: ${availableResponse.reasonPhrase}');
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading tests: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showUploadTestDialog() async {
    File? selectedFile;
    String? title;
    String? description;
    TimeOfDay? selectedTime;
    String? duration;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Upload Test'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // PDF File Selection
                  ElevatedButton.icon(
                    onPressed: () async {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                      );
                      if (result != null && result.files.single.path != null) {
                        setState(() {
                          selectedFile = File(result.files.single.path!);
                        });
                      }
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Select PDF File'),
                  ),
                  if (selectedFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Selected: ${selectedFile!.path.split('/').last}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Title Input
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Test Title',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => title = value,
                  ),
                  const SizedBox(height: 16),

                  // Description Input
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) => description = value,
                  ),
                  const SizedBox(height: 16),

                  // Time Selection
                  ListTile(
                    title: Text(
                      selectedTime != null
                          ? 'Start Time: ${selectedTime!.format(context)}'
                          : 'Select Start Time',
                      style: TextStyle(
                        color: selectedTime != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                timePickerTheme: TimePickerThemeData(
                                  backgroundColor: Colors.white,
                                  hourMinuteShape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  dayPeriodShape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            selectedTime = picked;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Duration Selection
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Duration (minutes)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        duration = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedFile == null ||
                        title == null ||
                        selectedTime == null ||
                        duration == null
                    ? null
                    : () async {
                        try {
                          final request = http.MultipartRequest(
                            'POST',
                            Uri.parse('http://27.116.52.24:8076/addTest'),
                          );

                          request.headers.addAll({
                            'Content-Type': 'multipart/form-data',
                          });

                          // Add file
                          request.files.add(
                            await http.MultipartFile.fromPath(
                              'questionPaper',
                              selectedFile!.path,
                            ),
                          );

                          // Calculate start and end time
                          final now = DateTime.now();
                          final startTime = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            selectedTime!.hour,
                            selectedTime!.minute,
                          );
                          final endTime = startTime
                              .add(Duration(minutes: int.parse(duration!)));

                          request.fields.addAll({
                            'teacherId': widget.teacherId.toString(),
                            'subjectId': widget.subjectId,
                            'class': widget.selectedClass,
                            'medium': widget.selectedBatch,
                            'title': title!,
                            'description': description ?? '',
                            'startTime': startTime.toUtc().toIso8601String(),
                            'endTime': endTime.toUtc().toIso8601String(),
                          });

                          final streamedResponse = await request.send();
                          final response =
                              await http.Response.fromStream(streamedResponse);
                          print(response.body);

                          if (response.statusCode == 200) {
                            final data = json.decode(response.body);
                            if (data['errorStatus'] == false) {
                              if (mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(data['message'] ??
                                        'Test uploaded successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _loadTests();
                              }
                            } else {
                              throw Exception(
                                  data['message'] ?? 'Failed to upload test');
                            }
                          } else {
                            throw Exception(
                                'Failed to upload test: ${response.reasonPhrase}');
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: const Text('Upload'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<List<dynamic>> _fetchStudents() async {
    try {
      final request = http.Request(
        'POST',
        Uri.parse('http://27.116.52.24:8076/getStudentsForTeacher'),
      );

      request.headers.addAll({
        'Content-Type': 'application/json',
      });

      request.body = json.encode({
        "teacherId": widget.teacherId,
        "class": widget.selectedClass,
        "subjectId": int.parse(widget.subjectId),
        "medium": widget.selectedBatch,
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print('Fetch students response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['errorStatus'] == false) {
          final students = (data['data'] as List).map((student) {
            final Map<String, dynamic> studentData =
                Map<String, dynamic>.from(student);
            studentData.remove('batch');
            return studentData;
          }).toList();
          return students;
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch students');
        }
      } else {
        throw Exception('Failed to fetch students: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error in fetchStudents: $e');
      rethrow;
    }
  }

  Future<void> _showAddMarksDialog(Map<String, dynamic> test) async {
    await showDialog(
      context: context,
      builder: (context) => AddMarksDialog(
        test: test,
        teacherId: widget.teacherId,
        selectedClass: widget.selectedClass,
        selectedBatch: widget.selectedBatch,
        subjectId: widget.subjectId,
      ),
    );
  }

  Widget _buildTestCard(Map<String, dynamic> test, bool isAvailable) {
    final startTime = DateTime.parse(test['startTime']);
    final endTime = DateTime.parse(test['endTime']);
    final now = DateTime.now();
    final isActive =
        isAvailable && now.isAfter(startTime) && now.isBefore(endTime);
    final isUpcoming = isAvailable && now.isBefore(startTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive
              ? Colors.green
              : isUpcoming
                  ? Colors.blue
                  : Colors.grey,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    test['title'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withOpacity(0.1)
                        : isUpcoming
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive
                        ? 'Active'
                        : isUpcoming
                            ? 'Upcoming'
                            : 'Completed',
                    style: TextStyle(
                      color: isActive
                          ? Colors.green
                          : isUpcoming
                              ? Colors.blue
                              : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              test['description'],
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${DateFormat('MMM dd, yyyy HH:mm').format(startTime)} - ${DateFormat('MMM dd, yyyy HH:mm').format(endTime)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isActive)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement test viewing/downloading
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download Test'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              )
            else if (!isAvailable)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddMarksDialog(test),
                  icon: const Icon(Icons.grade),
                  label: const Text('Add Marks'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestList(List<Map<String, dynamic>> tests, bool isAvailable) {
    if (tests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isAvailable ? 'No available tests' : 'No completed tests',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: tests.length,
      itemBuilder: (context, index) {
        return _buildTestCard(tests[index], isAvailable);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTests,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Available Tests'),
                Tab(text: 'Completed Tests'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTestList(_availableTests, true),
                _buildTestList(_completedTests, false),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadTestDialog,
        icon: const Icon(Icons.add),
        label: const Text('Upload Test'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

class AddMarksDialog extends StatefulWidget {
  final Map<String, dynamic> test;
  final int teacherId;
  final String selectedClass;
  final String selectedBatch;
  final String subjectId;

  const AddMarksDialog({
    Key? key,
    required this.test,
    required this.teacherId,
    required this.selectedClass,
    required this.selectedBatch,
    required this.subjectId,
  }) : super(key: key);

  @override
  State<AddMarksDialog> createState() => _AddMarksDialogState();
}

class _AddMarksDialogState extends State<AddMarksDialog> {
  List<dynamic> students = [];
  bool isLoading = true;
  bool isSubmitting = false;
  Map<int, TextEditingController> marksControllers = {};
  Map<int, double> existingMarks = {};

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadExistingMarks() async {
    try {
      final response = await http.post(
        Uri.parse('http://27.116.52.24:8076/getAllMarksForTest'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'testId': widget.test['id'],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['errorStatus'] == false) {
          final marks = List<Map<String, dynamic>>.from(data['data'] ?? []);
          setState(() {
            existingMarks = {
              for (var mark in marks)
                mark['studentId'] as int: (mark['marks'] as num).toDouble()
            };
          });
        }
      }
    } catch (e) {
      print('Error loading existing marks: $e');
    }
  }

  Future<void> _loadStudents() async {
    try {
      final request = http.Request(
        'POST',
        Uri.parse('http://27.116.52.24:8076/getStudentsForTeacher'),
      );

      request.headers.addAll({
        'Content-Type': 'application/json',
      });

      request.body = json.encode({
        "teacherId": widget.teacherId,
        "class": widget.selectedClass,
        "subjectId": int.parse(widget.subjectId),
        "medium": widget.selectedBatch,
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print('Fetch students response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['errorStatus'] == false) {
          final fetchedStudents = (data['data'] as List).map((student) {
            final Map<String, dynamic> studentData =
                Map<String, dynamic>.from(student);
            studentData.remove('batch');
            return studentData;
          }).toList();

          // Load existing marks after getting students
          await _loadExistingMarks();

          if (mounted) {
            setState(() {
              students = fetchedStudents;
              isLoading = false;
            });
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch students');
        }
      } else {
        throw Exception('Failed to fetch students: ${response.reasonPhrase}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching students: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitMarks() async {
    setState(() {
      isSubmitting = true;
    });

    try {
      // Prepare marks data
      final marksData = students.map((student) {
        final studentId = student['id'] as int;
        final marksText = marksControllers[studentId]?.text ?? '';
        final marks = double.tryParse(marksText) ?? 0.0;

        return {
          'studentId': studentId,
          'marks': marks,
        };
      }).toList();

      // Make API request
      final request = http.Request(
        'POST',
        Uri.parse('http://27.116.52.24:8076/addOrUpdateTestMarks'),
      );

      request.headers.addAll({
        'Content-Type': 'application/json',
      });

      request.body = json.encode({
        'testId': widget.test['id'],
        'marks': marksData,
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['errorStatus'] == false) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    data['data']['message'] ?? 'Marks submitted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to submit marks');
        }
      } else {
        throw Exception('Failed to submit marks: ${response.reasonPhrase}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting marks: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Marks'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.test['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final studentId = student['id'] as int;
                        marksControllers.putIfAbsent(
                          studentId,
                          () => TextEditingController(
                            text: existingMarks[studentId]?.toString() ?? '',
                          ),
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      AppColors.primary.withOpacity(0.1),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: AppColors.primary,
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
                                        '${student['fname']} ${student['lname']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller: marksControllers[studentId],
                                        decoration: const InputDecoration(
                                          labelText: 'Marks',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isSubmitting ? null : _submitMarks,
          child: isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Submit Marks'),
        ),
      ],
    );
  }
}
