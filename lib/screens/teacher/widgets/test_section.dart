import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tuition/core/themes/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../../../screens/teacher/utils/material_utils.dart';

class TestSection extends StatefulWidget {
  final int teacherId;
  final String selectedClass;
  final String selectedBatch;
  final String subjectId;
  final String medium;

  const TestSection({
    Key? key,
    required this.teacherId,
    required this.selectedClass,
    required this.selectedBatch,
    required this.subjectId,
    required this.medium,
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
    print(widget.medium);
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
          final now = DateTime.now();
          final allTests =
              List<Map<String, dynamic>>.from(availableData['data'] ?? []);
          final completedTestsRaw =
              List<Map<String, dynamic>>.from(completedData['data'] ?? []);

          final filteredAvailableTests = allTests.where((test) {
            final matchesClass = test['class'] == widget.selectedClass &&
                test['subjectId'].toString() == widget.subjectId;
            final endTime = DateTime.parse(test['endTime']);
            return matchesClass && now.isBefore(endTime);
          }).toList();

          final filteredCompletedTests = [
            ...allTests.where((test) {
              final matchesClass = test['class'] == widget.selectedClass &&
                  test['subjectId'].toString() == widget.subjectId;
              final endTime = DateTime.parse(test['endTime']);
              return matchesClass && !now.isBefore(endTime);
            }),
            ...completedTestsRaw.where((test) {
              return test['class'] == widget.selectedClass &&
                  test['subjectId'].toString() == widget.subjectId;
            }),
          ];

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
            backgroundColor: AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Upload Test',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.textPrimary,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PDF File Selection
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 18),
                    ),
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
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.picture_as_pdf,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                selectedFile!.path.split('/').last,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  // Title Input
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Test Title',
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    style: TextStyle(color: AppColors.textPrimary),
                    onChanged: (value) => title = value,
                  ),
                  const SizedBox(height: 16),
                  // Description Input
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Description',
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    style: TextStyle(color: AppColors.textPrimary),
                    maxLines: 3,
                    onChanged: (value) => description = value,
                  ),
                  const SizedBox(height: 16),
                  // Time Selection
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      selectedTime != null
                          ? 'Start Time: ${selectedTime!.format(context)}'
                          : 'Select Start Time',
                      style: TextStyle(
                        color: selectedTime != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.access_time,
                          color: AppColors.primary),
                      onPressed: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                timePickerTheme: TimePickerThemeData(
                                  backgroundColor: AppColors.cardBackground,
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
                    decoration: InputDecoration(
                      labelText: 'Duration (minutes)',
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      labelStyle: TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    style: TextStyle(color: AppColors.textPrimary),
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
            actionsPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel',
                    style: TextStyle(color: AppColors.textSecondary)),
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
                            'medium': widget.medium,
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
                                    backgroundColor: AppColors.success,
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
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
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
        "medium": widget.medium,
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
        medium: widget.medium,
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

    // Harmonious color scheme
    Color statusColor = isActive
        ? AppColors.success
        : isUpcoming
            ? AppColors.primary
            : AppColors.secondary;
    Color statusBgColor = isActive
        ? AppColors.success
        : isUpcoming
            ? AppColors.primary
            : AppColors.secondary;
    String statusText = isActive
        ? 'Active'
        : isUpcoming
            ? 'Upcoming'
            : 'Completed';

    return Card(
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppColors.primary.withOpacity(0.10),
          width: 1.2,
        ),
      ),
      elevation: 6,
      color: AppColors.cardBackground,
      shadowColor: AppColors.primary.withOpacity(0.10),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    test['title'],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              test['description'],
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.access_time, size: 18, color: AppColors.textPrimary),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('MMM dd, yyyy HH:mm').format(startTime)} - ${DateFormat('MMM dd, yyyy HH:mm').format(endTime)}',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (isAvailable)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final startTime = DateTime.parse(test['startTime']);
                    if (now.isBefore(startTime)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('This test will be available at '
                              '${DateFormat('MMM dd, yyyy HH:mm').format(startTime)}'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }
                    // Download and view PDF functionality
                    double progress = 0.0;
                    final fileName = test['title'] != null
                        ? '${test['title']}.pdf'
                        : 'test.pdf';
                    String progressMessage = 'Downloading test PDF...';
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) {
                        return StatefulBuilder(
                          builder: (context, setState) {
                            return AlertDialog(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(progressMessage),
                                  const SizedBox(height: 20),
                                  LinearProgressIndicator(value: progress),
                                  const SizedBox(height: 10),
                                  Text(
                                      '${(progress * 100).toStringAsFixed(0)}%'),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                    try {
                      // Use MaterialUtils.downloadMaterial for the question paper
                      final filePath = test['questionPaperPath'] ?? '';
                      debugPrint('Teacher test filePath: $filePath');
                      debugPrint(
                          'Teacher test Download URL:  {MaterialUtils.getFullFileUrl(filePath)}');
                      final downloadedFile =
                          await MaterialUtils.downloadMaterial(
                        filePath,
                        fileName,
                        onProgress: (p) {
                          progress = p;
                          if (Navigator.of(context).canPop()) {
                            (context as Element).markNeedsBuild();
                          }
                        },
                      );
                      Navigator.of(context).pop(); // Close progress dialog
                      if (downloadedFile == null ||
                          !await downloadedFile.exists()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('File not found after download!')),
                        );
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(
                              title: Text(fileName),
                              backgroundColor: AppColors.primary,
                            ),
                            body: PDFView(
                              filePath: downloadedFile.path,
                              enableSwipe: true,
                              swipeHorizontal: false,
                              autoSpacing: true,
                              pageFling: true,
                              pageSnap: true,
                              fitPolicy: FitPolicy.BOTH,
                              preventLinkNavigation: false,
                            ),
                          ),
                        ),
                      );
                    } catch (e) {
                      Navigator.of(context)
                          .pop(); // Close progress dialog if error
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: const Text('Download Test'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _showAddMarksDialog(test),
                  icon: const Icon(Icons.grade, color: Colors.white),
                  label: const Text('Add Marks',
                      style: TextStyle(color: Colors.white)),
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
              color: AppColors.scaffoldBackground,
            ),
            const SizedBox(height: 16),
            Text(
              isAvailable ? 'No available tests' : 'No completed tests',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.scaffoldBackground,
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
              style: const TextStyle(color: AppColors.error),
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
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(
        children: [
          Container(
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
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              indicatorColor: AppColors.primary,
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
                RefreshIndicator(
                  onRefresh: _loadTests,
                  color: AppColors.primary,
                  backgroundColor: AppColors.cardBackground,
                  child: _buildTestList(_availableTests, true),
                ),
                RefreshIndicator(
                  onRefresh: _loadTests,
                  color: AppColors.primary,
                  backgroundColor: AppColors.cardBackground,
                  child: _buildTestList(_completedTests, false),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadTestDialog,
        icon: const Icon(Icons.add, color: AppColors.surface),
        label: const Text('Upload Test',
            style: TextStyle(
              color: AppColors.surface,
            )),
        backgroundColor: AppColors.secondary,
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
  final String medium;

  const AddMarksDialog({
    Key? key,
    required this.test,
    required this.teacherId,
    required this.selectedClass,
    required this.selectedBatch,
    required this.subjectId,
    required this.medium,
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
      print(
          'Params: teacherId=${widget.teacherId}, class=${widget.selectedClass}, subjectId=${widget.subjectId}, medium=${widget.medium}');
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
        "medium": widget.medium,
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
            backgroundColor: AppColors.error,
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
                backgroundColor: AppColors.success,
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
            backgroundColor: AppColors.error,
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
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Padding(
        padding: const EdgeInsets.only(top: 12.0, bottom: 0),
        child: Text(
          'Add Marks',
          style: TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.65,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Text(
                    widget.test['title'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: students.isEmpty
                        ? Center(
                            child: Text('No students found for this test.',
                                style:
                                    TextStyle(color: AppColors.textSecondary)))
                        : ListView.builder(
                            itemCount: students.length,
                            itemBuilder: (context, index) {
                              final student = students[index];
                              final studentId = student['id'] as int;
                              marksControllers.putIfAbsent(
                                studentId,
                                () => TextEditingController(
                                  text: existingMarks[studentId]?.toString() ??
                                      '',
                                ),
                              );
                              return Card(
                                color: AppColors.surface,
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: AppColors.secondary,
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${student['fname']} ${student['lname']}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            TextField(
                                              controller:
                                                  marksControllers[studentId],
                                              decoration: InputDecoration(
                                                prefixIcon: Icon(Icons.grade,
                                                    color: AppColors.secondary),
                                                labelText: 'Marks',
                                                labelStyle: TextStyle(
                                                    color: AppColors
                                                        .textSecondary),
                                                filled: true,
                                                fillColor:
                                                    AppColors.cardBackground,
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                        horizontal: 12),
                                              ),
                                              style: TextStyle(
                                                  color: AppColors.textPrimary),
                                              keyboardType:
                                                  TextInputType.number,
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
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed:
                    isSubmitting ? null : () => Navigator.of(context).pop(),
                child: Text('Cancel',
                    style: TextStyle(color: AppColors.secondary)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submitMarks,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Submit Marks',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
