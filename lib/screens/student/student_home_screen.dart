import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import '../login_screen.dart';
import '../teacher/pdf_viewer_screen.dart';
import '../teacher/youtube_player_screen.dart';
import 'student_profile_screen.dart';
import 'package:tuition/core/themes/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter/rendering.dart';
import '../../widgets/custom_bottom_navigation.dart';
import 'student_report_screen.dart';
import '../../widgets/liquid_glass_painter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../teacher/utils/material_utils.dart';
import 'package:path/path.dart' as path;
import 'timed_pdf_viewer_screen.dart';
import 'package:tuition/controllers/subject_controller.dart';

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
  bool _showTuitionMaterialList = false;
  // Tuition Material State
  List<dynamic> _tuitionMaterials = [];
  bool _isLoadingTuitionMaterials = false;
  String? _tuitionMaterialError;
  Map<int, String> _subjectIdToName = {};
  bool _isSubjectsLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubjectsAndMaterials();
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
        "batch": widget.enrolledSubjects[_selectedSubjectIndex]['subjectId']
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

          // Debug: Print all available tests before filtering
          final allAvailableTests =
              List<Map<String, dynamic>>.from(availableData['data'] ?? []);
          final allCompletedTests =
              List<Map<String, dynamic>>.from(completedData['data'] ?? []);

          print(
              'Total available tests before filtering: ${allAvailableTests.length}');
          print(
              'Total completed tests before filtering: ${allCompletedTests.length}');

          // Check if there are no tests at all
          if (allAvailableTests.isEmpty && allCompletedTests.isEmpty) {
            print('No tests found for this student');
            setState(() {
              _availableTests = [];
              _completedTests = [];
              _isLoadingTests = false;
            });
            return;
          }

          // Print subject IDs in available tests
          for (var test in allAvailableTests) {
            print(
                'Available test - ID: ${test['id']}, Subject ID: ${test['subjectId']}, Title: ${test['title']}');
          }

          // Print subject IDs in completed tests
          for (var test in allCompletedTests) {
            print(
                'Completed test - ID: ${test['id']}, Subject ID: ${test['subjectId']}, Title: ${test['title']}');
          }

          // Filter tests for the selected subject
          final availableTests = allAvailableTests.where((test) {
            final testSubjectId = test['subjectId']?.toString() ?? '';
            final matches = testSubjectId == selectedSubjectId;
            print(
                'Available test filtering - Test Subject ID: $testSubjectId, Selected: $selectedSubjectId, Matches: $matches');
            return matches;
          }).toList();

          final completedTests = allCompletedTests.where((test) {
            final testSubjectId = test['subjectId']?.toString() ?? '';
            final matches = testSubjectId == selectedSubjectId;
            print(
                'Completed test filtering - Test Subject ID: $testSubjectId, Selected: $selectedSubjectId, Matches: $matches');
            return matches;
          }).toList();

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

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // Navigate to login screen and clear the stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _fetchTuitionMaterials() async {
    setState(() {
      _isLoadingTuitionMaterials = true;
      _tuitionMaterialError = null;
    });
    try {
      var headers = {'Content-Type': 'application/json'};
      var request = http.Request(
        'POST',
        Uri.parse('http://27.116.52.24:8076/material/getMaterials'),
      );
      request.body = json.encode({
        "teacherId": 2,
        "class": widget.student['class'].toString(),
        // No batch in request
      });
      request.headers.addAll(headers);
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['errorStatus'] == false) {
          setState(() {
            _tuitionMaterials = data['data'] ?? [];
            print('Student medium: ${widget.student['medium']}');
            print('Fetched tuition materials: ${_tuitionMaterials.toString()}');
            for (final m in _tuitionMaterials) {
              print('Material batch: ${m['batch']}');
            }
          });
        } else {
          setState(() {
            _tuitionMaterialError = 'Failed to load tuition materials.';
          });
        }
      } else {
        setState(() {
          _tuitionMaterialError = 'Failed to load tuition materials: '
              '${response.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        _tuitionMaterialError = 'Error loading tuition materials: $e';
      });
    } finally {
      setState(() {
        _isLoadingTuitionMaterials = false;
      });
    }
  }

  Future<void> _fetchSubjectsAndMaterials() async {
    setState(() {
      _isSubjectsLoading = true;
    });
    try {
      final subjects = await SubjectController().getSubjects();
      setState(() {
        _subjectIdToName = {for (var s in subjects) s.id: s.name};
        _isSubjectsLoading = false;
      });
      await _fetchTuitionMaterials();
    } catch (e) {
      setState(() {
        _isSubjectsLoading = false;
      });
      await _fetchTuitionMaterials();
    }
  }

  Widget _buildSubjectCards() {
    // Insert Tuition Material as the first card
    final List<Map<String, dynamic>> displaySubjects = [
      {
        'isTuitionMaterial': true,
        'subjectName': 'Tuition Material',
        'icon': Icons.folder_special_rounded,
      },
      ...widget.enrolledSubjects.map((s) {
        final map = Map<String, dynamic>.from(s);
        map['isTuitionMaterial'] = false;
        return map;
      }).toList(),
    ];
    return Container(
      color: AppColors.scaffoldBackground,
      child: GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
        ),
        itemCount: displaySubjects.length,
        itemBuilder: (context, index) {
          final subject = displaySubjects[index];
          if (subject['isTuitionMaterial'] == true) {
            // Tuition Material card
            return GestureDetector(
              onTap: () {
                setState(() {
                  _showTuitionMaterialList = true;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: Colors.white.withOpacity(0.65),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.10),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.folder_special_rounded,
                        size: 36,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tuition Material',
                      style: const TextStyle(
                        color: Color(0xFF2A4759),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.white,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          } else {
            // Subject card (unchanged)
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSubjectIndex =
                      index - 1; // -1 because of tuition card
                  _showSubjectCards = false;
                });
                _loadMaterials();
                _loadTests();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: Colors.white.withOpacity(0.65),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.10),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _getSubjectIcon(subject['subjectName']),
                        size: 36,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      subject['subjectName'],
                      style: const TextStyle(
                        color: Color(0xFF2A4759),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.white,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildTuitionMaterialList() {
    final String studentMedium =
        (widget.student['medium']?.toString() ?? '').trim().toLowerCase();
    if (_isSubjectsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    // Group by unique batch for the student's medium
    Map<String, List<dynamic>> groupedByBatch = {};
    for (final m in _tuitionMaterials) {
      final batch = (m['batch'] ?? '').trim();
      if (batch.toLowerCase().startsWith('$studentMedium-')) {
        groupedByBatch.putIfAbsent(batch, () => []);
        groupedByBatch[batch]!.add(m);
      }
    }
    print('Grouped batches: ${groupedByBatch.keys.toList()}');
    if (groupedByBatch.isEmpty) {
      return Center(
        child: Text(
          'No tuition materials available.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(18),
      children: groupedByBatch.entries.map((entry) {
        final batch = entry.key;
        final mats = entry.value;
        final parts = batch.split('-');
        String batchDisplay = batch;
        if (parts.length == 2) {
          final medium = parts[0];
          final subjectId = int.tryParse(parts[1]);
          final subjectName =
              _subjectIdToName[subjectId] ?? 'Subject $subjectId';
          batchDisplay = '$medium - $subjectName';
        }
        return Card(
          margin: const EdgeInsets.only(bottom: 24),
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: ListTile(
            leading: Icon(Icons.label, color: AppColors.primary),
            title: Text(
              batchDisplay,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text('${mats.length} file${mats.length == 1 ? '' : 's'}'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => _BatchMaterialsScreen(
                    batchName: batchDisplay,
                    materials: mats,
                  ),
                ),
              );
            },
          ),
        );
      }).toList(),
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

  Widget _buildMaterialsSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_materials.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          decoration: BoxDecoration(
            color: AppColors.cardBackground.withOpacity(0.98),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.info_outline,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 22),
              Text(
                'No materials available for',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                widget.enrolledSubjects[_selectedSubjectIndex]['subjectName'],
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMaterials,
      color: AppColors.primary,
      backgroundColor: AppColors.cardBackground,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _materials.length,
        itemBuilder: (context, index) {
          final material = _materials[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  if (material['category'] == 'file') {
                    double progress = 0.0;
                    final fileName = material['fileName'] ??
                        path.basename(material['filePath']);
                    final extension = path.extension(fileName).toLowerCase();
                    String progressMessage = 'Downloading file...';
                    if (extension == '.pdf') {
                      progressMessage = 'Downloading PDF...';
                    } else if (['.jpg', '.jpeg', '.png', '.gif', '.bmp']
                        .contains(extension)) {
                      progressMessage = 'Downloading image...';
                    }
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
                      final downloadedFile =
                          await MaterialUtils.downloadMaterial(
                        material['filePath'],
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
                      if (extension == '.pdf') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PdfViewerScreen(
                              filePath: downloadedFile.path,
                              title: fileName,
                            ),
                          ),
                        );
                      } else if (['.jpg', '.jpeg', '.png', '.gif', '.bmp']
                          .contains(extension)) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              appBar: AppBar(
                                title: Text(fileName),
                                backgroundColor: AppColors.primary,
                              ),
                              body: InteractiveViewer(
                                minScale: 0.5,
                                maxScale: 4.0,
                                child: Center(
                                  child: Image.file(
                                    downloadedFile,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      } else {
                        throw Exception('Unsupported file type: $extension');
                      }
                    } catch (e) {
                      Navigator.of(context)
                          .pop(); // Close progress dialog if error
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
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
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          material['category'] == 'file'
                              ? Icons.picture_as_pdf
                              : Icons.video_library,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              material['fileName'] ??
                                  material['category'] ??
                                  'Untitled',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              material['category'] ?? 'Unknown type',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.iconSecondary,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
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

    return RefreshIndicator(
      onRefresh: _loadAttendance,
      color: AppColors.primary,
      backgroundColor: AppColors.cardBackground,
      child: ListView(
        children: [
          // Attendance Statistics Card
          Container(
            margin: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Overview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            totalClasses.toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Total Classes',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            presentClasses.toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Present',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '$attendancePercentage%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: double.tryParse(attendancePercentage) !=
                                          null &&
                                      double.parse(attendancePercentage) >= 75
                                  ? AppColors.success
                                  : AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Percentage',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Attendance List
          ...subjectAttendance.map((record) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: record['status'] == 'present'
                              ? AppColors.success
                              : AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          record['status'] == 'present'
                              ? Icons.check
                              : Icons.close,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date: ${record['date']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Status: ${record['status'].toUpperCase()}',
                              style: TextStyle(
                                color: record['status'] == 'present'
                                    ? AppColors.success
                                    : AppColors.error,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
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
    final hasMarks = !isAvailable && test['marks'] != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              test['title'] ?? 'Test',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF2A4759),
              ),
            ),
            const SizedBox(height: 8),
            if (test['description'] != null &&
                test['description'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  test['description'],
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 16, color: AppColors.iconSecondary.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text(
                  '${DateFormat('MMM dd, yyyy HH:mm').format(startTime)} - ${DateFormat('MMM dd, yyyy HH:mm').format(endTime)}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (isAvailable &&
                !isUpcoming &&
                (test['questionPaperPath'] != null &&
                    test['questionPaperPath'].toString().isNotEmpty)) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Loading question paper...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      final questionPaperPath = test['questionPaperPath'];
                      if (questionPaperPath == null ||
                          questionPaperPath.toString().isEmpty) {
                        throw Exception('Question paper not available');
                      }
                      final questionPaperUrl =
                          'http://27.116.52.24:8076/$questionPaperPath';
                      print('Loading question paper from: $questionPaperUrl');
                      final response =
                          await http.get(Uri.parse(questionPaperUrl));
                      if (response.statusCode == 200) {
                        final tempDir = await getTemporaryDirectory();
                        final file = File('${tempDir.path}/question_paper.pdf');
                        await file.writeAsBytes(response.bodyBytes);
                        final fileName = test['title'] != null
                            ? '${test['title']}.pdf'
                            : 'test.pdf';
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TimedPdfViewerScreen(
                              filePath: file.path,
                              title: fileName,
                              endTime: endTime,
                            ),
                          ),
                        );
                      } else {
                        throw Exception('Failed to download question paper');
                      }
                    } catch (e) {
                      print('Error loading question paper: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error loading question paper: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.description,
                      color: Colors.white, size: 18),
                  label: const Text('View Question Paper',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
            if (!isAvailable && test['marks'] == null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 15, color: AppColors.error),
                    const SizedBox(width: 4),
                    Text(
                      'Marks not uploaded',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!isAvailable && test['marks'] != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.grade, size: 15, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      'Marks: ${test['marks']}',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Loading question paper...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      final questionPaperPath = test['questionPaperPath'];
                      if (questionPaperPath == null ||
                          questionPaperPath.toString().isEmpty) {
                        throw Exception('Question paper not available');
                      }
                      final questionPaperUrl =
                          'http://27.116.52.24:8076/$questionPaperPath';
                      print('Loading question paper from: $questionPaperUrl');
                      final response =
                          await http.get(Uri.parse(questionPaperUrl));
                      if (response.statusCode == 200) {
                        final tempDir = await getTemporaryDirectory();
                        final file = File('${tempDir.path}/question_paper.pdf');
                        await file.writeAsBytes(response.bodyBytes);
                        final fileName = test['title'] != null
                            ? '${test['title']}.pdf'
                            : 'test.pdf';
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PdfViewerScreen(
                              filePath: file.path,
                              title: fileName,
                            ),
                          ),
                        );
                      } else {
                        throw Exception('Failed to download question paper');
                      }
                    } catch (e) {
                      print('Error loading question paper: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error loading question paper: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.description,
                      color: Colors.white, size: 18),
                  label: const Text('View Question Paper',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
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
              color: AppColors.iconSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              isAvailable ? 'No available tests' : 'No completed tests',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTests,
      color: AppColors.primary,
      backgroundColor: AppColors.cardBackground,
      child: ListView.builder(
        itemCount: tests.length,
        itemBuilder: (context, index) {
          return _buildTestCard(tests[index], isAvailable);
        },
      ),
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
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

  String _getInitials(Map<String, dynamic> student) {
    final fname = student['fname'] ?? '';
    final lname = student['lname'] ?? '';
    if (fname.isNotEmpty && lname.isNotEmpty) {
      return fname[0].toUpperCase() + lname[0].toUpperCase();
    } else if (fname.isNotEmpty) {
      return fname[0].toUpperCase();
    } else {
      return 'S';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        flexibleSpace: Container(
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
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: _showTuitionMaterialList
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _showTuitionMaterialList = false;
                  });
                },
              )
            : null,
        title: _showTuitionMaterialList
            ? const Text(
                'Tuition Material',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              )
            : _showSubjectCards
                ? const Text(
                    'Student Dashboard',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _showSubjectCards = true;
                            _materials = [];
                          });
                        },
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.enrolledSubjects[_selectedSubjectIndex]
                            ['subjectName'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
        backgroundColor: Colors.transparent,
        elevation: 4,
        actions: [
          // Report Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Material(
              color: AppColors.primary.withOpacity(0.13),
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentReportScreen(
                        user: widget.user,
                        student: widget.student,
                        enrolledSubjects: widget.enrolledSubjects,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Row(
                    children: const [
                      Icon(Icons.bar_chart, color: AppColors.primary, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Report',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Profile Avatar
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (context) {
                    return SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 24, horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.person,
                                  color: AppColors.primary),
                              title: const Text('Profile'),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StudentProfileScreen(
                                      user: widget.user,
                                      student: widget.student,
                                      enrolledSubjects: widget.enrolledSubjects,
                                    ),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.logout,
                                  color: AppColors.error),
                              title: const Text('Logout'),
                              onTap: () {
                                Navigator.pop(context);
                                _logout();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: Text(
                  _getInitials(widget.student),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _showTuitionMaterialList
          ? (_isLoadingTuitionMaterials
              ? const Center(child: CircularProgressIndicator())
              : _tuitionMaterialError != null
                  ? Center(
                      child: Text(
                        _tuitionMaterialError!,
                        style: TextStyle(color: AppColors.error),
                      ),
                    )
                  : _tuitionMaterials.isEmpty
                      ? Center(
                          child: Text(
                            'No tuition materials available.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : _buildTuitionMaterialList())
          : _showSubjectCards
              ? _buildSubjectCards()
              : Column(
                  children: [
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
      bottomNavigationBar: _showSubjectCards || _showTuitionMaterialList
          ? null
          : CustomBottomNavigation(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                  if (index == 0) {
                    _loadMaterials();
                  } else if (index == 1) {
                    _loadAttendance();
                  } else if (index == 2) {
                    _loadTests();
                  }
                });
              },
              items: [
                BottomNavigationItem(
                  icon: Icons.menu_book_outlined,
                  label: 'Materials',
                ),
                BottomNavigationItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Attendance',
                ),
                BottomNavigationItem(
                  icon: Icons.assignment_outlined,
                  label: 'Tests',
                ),
              ],
            ),
    );
  }
}

class _BatchMaterialsScreen extends StatelessWidget {
  final String batchName;
  final List<dynamic> materials;
  const _BatchMaterialsScreen(
      {Key? key, required this.batchName, required this.materials})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(batchName),
        backgroundColor: Colors.transparent,
        elevation: 4,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF2A4759),
                Color(0xFF1E3440),
                Color(0xFF152A35),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ),
      backgroundColor: AppColors.scaffoldBackground,
      body: ListView.separated(
        padding: const EdgeInsets.all(18),
        itemCount: materials.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final material = materials[index];
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                // (reuse your existing onTap logic for opening files/videos)
                if (material['category'] == 'file' &&
                    material['filePath'] != null) {
                  double progress = 0.0;
                  final fileName = material['fileName'] ??
                      path.basename(material['filePath']);
                  final extension = path.extension(fileName).toLowerCase();
                  String progressMessage = 'Downloading file...';
                  if (extension == '.pdf') {
                    progressMessage = 'Downloading PDF...';
                  } else if (['.jpg', '.jpeg', '.png', '.gif', '.bmp']
                      .contains(extension)) {
                    progressMessage = 'Downloading image...';
                  }
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
                                Text('${(progress * 100).toStringAsFixed(0)}%'),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                  try {
                    final downloadedFile = await MaterialUtils.downloadMaterial(
                      material['filePath'],
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
                    if (extension == '.pdf') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PdfViewerScreen(
                            filePath: downloadedFile.path,
                            title: fileName,
                          ),
                        ),
                      );
                    } else if (['.jpg', '.jpeg', '.png', '.gif', '.bmp']
                        .contains(extension)) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(
                              title: Text(fileName),
                              backgroundColor: AppColors.primary,
                            ),
                            body: InteractiveViewer(
                              minScale: 0.5,
                              maxScale: 4.0,
                              child: Center(
                                child: Image.file(
                                  downloadedFile,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    } else {
                      throw Exception('Unsupported file type: $extension');
                    }
                  } catch (e) {
                    Navigator.of(context)
                        .pop(); // Close progress dialog if error
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                } else if (material['category'] == 'video' &&
                    material['videoLink'] != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => YoutubePlayerScreen(
                        videoUrl: material['videoLink'] ?? '',
                        title: material['fileName'] ?? 'Video',
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Unknown or missing material type'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        material['category'] == 'file'
                            ? Icons.picture_as_pdf
                            : Icons.video_library,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        material['fileName'] ??
                            material['category'] ??
                            'Untitled',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        color: AppColors.iconSecondary, size: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
