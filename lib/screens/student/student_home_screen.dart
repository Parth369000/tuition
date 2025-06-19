import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../login_screen.dart';
import '../teacher/pdf_viewer_screen.dart';
import '../teacher/youtube_player_screen.dart';
import 'student_profile_screen.dart';
import 'package:tuition/core/themes/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class StudentHomeScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;
  final Map<String, dynamic> student;
  final List<dynamic> enrolledSubjects;

  const StudentHomeScreen({
    Key? key,
    required this.token,
    required this.user,
    required this.student,
    required this.enrolledSubjects,
  }) : super(key: key);

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  List<dynamic> _materials = [];
  List<dynamic> _attendance = [];
  List<Map<String, dynamic>> _availableTests = [];
  List<Map<String, dynamic>> _completedTests = [];
  bool _isLoading = false;
  bool _isLoadingAttendance = false;
  bool _isLoadingTests = false;
  String? _error;
  String? _attendanceError;
  String? _testError;
  int _selectedIndex = 0;
  int _selectedSubjectIndex = 0;
  bool _showSubjectCards = true;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadMaterials() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      var headers = {
        'Content-Type': 'application/json',
      };

      var request = http.Request(
        'POST',
        Uri.parse('http://27.116.52.24:8076/material/getMaterials'),
      );

      request.body = json.encode({
        "class": widget.student['class'].toString(),
        "batch": widget.student['batch'].toString(),
        "subjectId": widget.enrolledSubjects[_selectedSubjectIndex]['subjectId']
            .toString(),
      });
      request.headers.addAll(headers);

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);
      print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _materials = data['data'] ?? [];
        });
      } else {
        setState(() {
          _error = 'Failed to load materials: ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading materials: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _isLoadingAttendance = true;
      _attendanceError = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://27.116.52.24:8076/getAttendanceForStudent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'studentId': widget.student['id'],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['errorStatus'] == false) {
          setState(() {
            _attendance = data['data'] ?? [];
          });
        } else {
          setState(() {
            _attendanceError = 'Failed to load attendance data';
          });
        }
      } else {
        setState(() {
          _attendanceError =
              'Failed to load attendance: ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        _attendanceError = 'Error loading attendance: $e';
      });
    } finally {
      setState(() {
        _isLoadingAttendance = false;
      });
    }
  }

  Future<void> _loadTests() async {
    setState(() {
      _isLoadingTests = true;
      _testError = null;
    });

    try {
      // Get the selected subject ID
      final selectedSubjectId = widget.enrolledSubjects[_selectedSubjectIndex]
              ['subjectId']
          .toString();
      print('Loading tests for subject ID: $selectedSubjectId');

      // Load available tests
      final availableResponse = await http.post(
        Uri.parse('http://27.116.52.24:8076/getAvailableTests'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'studentId': widget.student['id'],
        }),
      );

      // Load completed tests
      final completedResponse = await http.post(
        Uri.parse('http://27.116.52.24:8076/getPastTests'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'studentId': widget.student['id'],
        }),
      );

      // Load test marks
      final marksResponse = await http.post(
        Uri.parse('http://27.116.52.24:8076/getStudentTestMarks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'studentId': widget.student['id'],
        }),
      );

      if (availableResponse.statusCode == 200 &&
          completedResponse.statusCode == 200 &&
          marksResponse.statusCode == 200) {
        final availableData = jsonDecode(availableResponse.body);
        final completedData = jsonDecode(completedResponse.body);
        final marksData = jsonDecode(marksResponse.body);

        if (availableData['errorStatus'] == false &&
            completedData['errorStatus'] == false &&
            marksData['errorStatus'] == false) {
          // Create a map of test marks for easy lookup
          final Map<int, Map<String, dynamic>> marksMap = {};
          for (var mark in marksData['data']) {
            marksMap[mark['testId']] = mark;
          }

          // Filter tests for the selected subject
          final availableTests =
              List<Map<String, dynamic>>.from(availableData['data'] ?? [])
                  .where((test) =>
                      test['subjectId'].toString() == selectedSubjectId)
                  .toList();

          final completedTests =
              List<Map<String, dynamic>>.from(completedData['data'] ?? [])
                  .where((test) =>
                      test['subjectId'].toString() == selectedSubjectId)
                  .toList();

          print('Filtered available tests: ${availableTests.length}');
          print('Filtered completed tests: ${completedTests.length}');

          // Add marks data to completed tests
          for (var test in completedTests) {
            final testId = test['id'];
            if (marksMap.containsKey(testId)) {
              test['marks'] = marksMap[testId]!['marks'];
              test['teacherName'] = marksMap[testId]!['teacherName'];
            }
          }

          setState(() {
            _availableTests = availableTests;
            _completedTests = completedTests;
            _isLoadingTests = false;
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
        _testError = 'Error loading tests: $e';
        _isLoadingTests = false;
      });
    }
  }

  void _logout() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Navigate to login screen and clear the stack
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCards() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: widget.enrolledSubjects.length,
      itemBuilder: (context, index) {
        final subject = widget.enrolledSubjects[index];
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedSubjectIndex = index;
                _showSubjectCards = false;
              });
              _loadMaterials();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.8),
                    AppColors.primary,
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getSubjectIcon(subject['subjectName']),
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subject['subjectName'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getSubjectIcon(String subjectName) {
    switch (subjectName.toLowerCase()) {
      case 'physics':
        return Icons.science;
      case 'chemistry':
        return Icons.science_outlined;
      case 'biology':
        return Icons.biotech;
      case 'mathematics':
        return Icons.calculate;
      case 'english':
        return Icons.language;
      case 'gujarati':
        return Icons.translate;
      case 'social science':
        return Icons.public;
      default:
        return Icons.book;
    }
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _showSubjectCards = true;
                _materials = [];
              });
            },
            icon: const Icon(Icons.arrow_back),
            color: AppColors.primary,
          ),
          Text(
            widget.enrolledSubjects[_selectedSubjectIndex]['subjectName'],
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsSection() {
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
              style: TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMaterials,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_materials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: AppColors.info, size: 48),
            const SizedBox(height: 12),
            Text(
              'No materials available for ${widget.enrolledSubjects[_selectedSubjectIndex]['subjectName']}',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.info,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _materials.length,
      itemBuilder: (context, index) {
        final material = _materials[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: AppColors.cardBackground,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                material['category'] == 'file'
                    ? Icons.picture_as_pdf
                    : Icons.video_library,
                color: AppColors.primary,
              ),
            ),
            title: Text(
              material['fileName'] ?? material['category'] ?? 'Untitled',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              material['category'] ?? 'Unknown type',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            onTap: () {
              if (material['category'] == 'file') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PdfViewerScreen(
                      filePath: material['filePath'] ?? '',
                      title: material['name'] ?? 'PDF Document',
                    ),
                  ),
                );
              } else if (material['category'] == 'video') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => YoutubePlayerScreen(
                      videoUrl: material['videoLink'] ?? '',
                      title: material['name'] ?? 'Video',
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Unknown material type'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildAttendanceSection() {
    if (_isLoadingAttendance) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_attendanceError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _attendanceError!,
              style: TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAttendance,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Filter attendance for the selected subject
    final subjectAttendance = _attendance.where((record) {
      return record['subjectName'] ==
          widget.enrolledSubjects[_selectedSubjectIndex]['subjectName'];
    }).toList();

    if (subjectAttendance.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, color: AppColors.info, size: 48),
            const SizedBox(height: 12),
            Text(
              'No attendance records for ${widget.enrolledSubjects[_selectedSubjectIndex]['subjectName']}',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.info,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Calculate attendance statistics
    final totalClasses = subjectAttendance.length;
    final presentClasses = subjectAttendance
        .where((record) => record['status'] == 'present')
        .length;
    final attendancePercentage =
        (presentClasses / totalClasses * 100).toStringAsFixed(1);

    return Column(
      children: [
        // Attendance Statistics Card
        Card(
          margin: const EdgeInsets.all(16),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Attendance Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Total Classes', totalClasses.toString()),
                    _buildStatItem('Present', presentClasses.toString()),
                    _buildStatItem('Percentage', '$attendancePercentage%'),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Attendance List
        Expanded(
          child: ListView.builder(
            itemCount: subjectAttendance.length,
            itemBuilder: (context, index) {
              final record = subjectAttendance[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: record['status'] == 'present'
                          ? Colors.green.withOpacity(0.12)
                          : Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      record['status'] == 'present'
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: record['status'] == 'present'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  title: Text(
                    'Date: ${record['date']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Status: ${record['status'].toUpperCase()}',
                    style: TextStyle(
                      color: record['status'] == 'present'
                          ? Colors.green
                          : Colors.red,
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

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTestCard(Map<String, dynamic> test, bool isAvailable) {
    final startTime = DateTime.parse(test['startTime']);
    final endTime = DateTime.parse(test['endTime']);
    final now = DateTime.now();
    final isActive =
        isAvailable && now.isAfter(startTime) && now.isBefore(endTime);
    final isUpcoming = isAvailable && now.isBefore(startTime);
    final hasMarks = !isAvailable && test['marks'] != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive
              ? Colors.green
              : isUpcoming
                  ? Colors.blue
                  : hasMarks
                      ? Colors.green
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
                            : hasMarks
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive
                        ? 'Active'
                        : isUpcoming
                            ? 'Upcoming'
                            : hasMarks
                                ? 'Graded'
                                : 'Completed',
                    style: TextStyle(
                      color: isActive
                          ? Colors.green
                          : isUpcoming
                              ? Colors.blue
                              : hasMarks
                                  ? Colors.green
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
            if (hasMarks) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Teacher: ${test['teacherName']}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.grade, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Marks: ${test['marks']}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (!isAvailable) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hourglass_empty,
                        size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    const Text(
                      'Marks Pending',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (isActive || !isAvailable) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          // Show loading indicator
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Loading question paper...'),
                              duration: Duration(seconds: 1),
                            ),
                          );

                          // Get the question paper path from the test data
                          final questionPaperPath = test['questionPaperPath'];
                          if (questionPaperPath == null ||
                              questionPaperPath.toString().isEmpty) {
                            throw Exception('Question paper not available');
                          }

                          // Construct the full URL for the question paper
                          final questionPaperUrl =
                              'http://27.116.52.24:8076/getAvailableTests/$questionPaperPath';
                          print(
                              'Loading question paper from: $questionPaperUrl');

                          // Download the PDF file
                          final response =
                              await http.get(Uri.parse(questionPaperUrl));
                          if (response.statusCode == 200) {
                            // Get temporary directory
                            final tempDir = await getTemporaryDirectory();
                            final file =
                                File('${tempDir.path}/question_paper.pdf');

                            // Write the PDF to the file
                            await file.writeAsBytes(response.bodyBytes);

                            // Navigate to PDF viewer
                            if (mounted) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => Scaffold(
                                    appBar: AppBar(
                                      title: Text(test['title']),
                                      backgroundColor: AppColors.primary,
                                    ),
                                    body: PDFView(
                                      filePath: file.path,
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
                            }
                          } else {
                            throw Exception(
                                'Failed to download question paper');
                          }
                        } catch (e) {
                          print('Error loading question paper: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Error loading question paper: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon:
                          Icon(isActive ? Icons.visibility : Icons.description),
                      label: Text(isActive
                          ? 'View Question Paper'
                          : 'View Question Paper'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isActive ? Colors.green : AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
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

  Widget _buildTestsSection() {
    if (_isLoadingTests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_testError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _testError!,
              style: TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTests,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppColors.primary,
            child: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: [
                Tab(text: 'Available Tests'),
                Tab(text: 'Completed Tests'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildTestList(_availableTests, true),
                _buildTestList(_completedTests, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: false,
        title: const Text('Student Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                color: AppColors.primary,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentProfileScreen(),
                ),
              );
            },
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _showSubjectCards
          ? _buildSubjectCards()
          : Column(
              children: [
                _buildBackButton(),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      _buildMaterialsSection(),
                      _buildAttendanceSection(),
                      _buildTestsSection(),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _showSubjectCards
          ? null
          : BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.book),
                  label: 'Materials',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today),
                  label: 'Attendance',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.assignment),
                  label: 'Tests',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textSecondary,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                  if (index == 1) {
                    _loadAttendance();
                  } else if (index == 2) {
                    _loadTests();
                  }
                });
              },
            ),
    );
  }
}
