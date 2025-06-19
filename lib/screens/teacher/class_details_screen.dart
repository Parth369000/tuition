import 'dart:core';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tuition/core/themes/app_colors.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'pdf_viewer_screen.dart';
import 'youtube_player_screen.dart';
import 'widgets/attendance_widgets.dart';
import 'utils/attendance_utils.dart';
import 'utils/material_utils.dart';
import 'package:tuition/widgets/materials/materials_section.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'widgets/test_section.dart';

class ClassDetailsScreen extends StatefulWidget {
  final int userId;
  final int teacherId;
  final String classKey;
  final String subject;
  final String subjectId;
  final String batch;

  const ClassDetailsScreen({
    super.key,
    required this.userId,
    required this.teacherId,
    required this.classKey,
    required this.subject,
    required this.subjectId,
    required this.batch,
  });

  @override
  State<ClassDetailsScreen> createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends State<ClassDetailsScreen> {
  int _selectedIndex = 0;
  List<dynamic> _attendanceRecords = [];
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> materials = [];
  String? selectedClass;
  String? selectedBatch;
  String? selectedSubject;
  String? selectedSubjectId;
  String? selectedMedium;
  DateTime _selectedDate = DateTime.now();

  bool get hasAttendanceForToday {
    final today = DateTime.now().toString().split(' ')[0];
    return _attendanceRecords.any((record) => record['date'] == today);
  }

  @override
  void initState() {
    super.initState();
    selectedClass = widget.classKey;
    selectedBatch = widget.batch;
    selectedSubject = widget.subject;
    selectedSubjectId = widget.subjectId;
    selectedMedium = widget.batch; // Using batch as medium
    _loadAttendance();
    _fetchMaterials();
  }

  // Helper to ensure filePath is a full URL
  String getFullFileUrl(String filePath) {
    if (filePath.startsWith('http')) {
      print(filePath);
      return filePath;
    }
    return 'http://27.116.52.24:8076/${filePath.startsWith('/') ? filePath.substring(1) : filePath}';
  }

  Future<void> _viewMaterial(String filePath,
      {String? category, String? name}) async {
    print('Original filePath: $filePath');
    print('Category: $category');
    if (category == 'file') {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      try {
        final fileName = name ?? path.basename(filePath);
        final downloadedFile =
            await MaterialUtils.downloadPdf(filePath, fileName);

        if (downloadedFile == null) {
          throw Exception('Failed to download file');
        }

        Navigator.of(context).pop(); // Close loading dialog

        // Check file extension to determine if it's an image or PDF
        final extension = path.extension(fileName).toLowerCase();
        if (extension == '.pdf') {
          // Open PDF viewer
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PdfViewerScreen(
                filePath: downloadedFile.path,
                title: name ?? 'PDF Document',
              ),
            ),
          );
        } else if (['.jpg', '.jpeg', '.png', '.gif', '.bmp']
            .contains(extension)) {
          // Open image viewer
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(
                  title: Text(name ?? 'Image'),
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
      } catch (e, stackTrace) {
        print('Error downloading file: $e');
        print('Stack trace: $stackTrace');
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading file: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } else if (category == 'video') {
      print('Opening video: $filePath');
      // Extract video ID from URL
      final videoId = YoutubePlayer.convertUrlToId(filePath);
      if (videoId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid YouTube URL')),
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => YoutubePlayerScreen(
            videoUrl: filePath,
            title: name ?? 'YouTube Video',
          ),
        ),
      );
    } else {
      print('Unknown category: $category');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unknown material type: $category')),
      );
    }
  }

  Future<void> _fetchMaterials() async {
    try {
      final materialsList = await MaterialUtils.fetchMaterials(
        teacherId: widget.teacherId,
        selectedClass: selectedClass ?? '',
        selectedBatch: selectedBatch ?? '',
      );
      setState(() {
        materials = materialsList;
      });
    } catch (e) {
      setState(() {
        materials = [];
      });
    }
  }

  Future<void> _showUploadMaterialDialog() async {
    String? materialType = 'file';
    String? youtubeUrl;
    File? pickedFile;
    bool isUploading = false;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Upload Material'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Radio<String>(
                        value: 'file',
                        groupValue: materialType,
                        onChanged: (val) {
                          setState(() => materialType = val);
                        },
                      ),
                      const Text('PDF'),
                      Radio<String>(
                        value: 'video',
                        groupValue: materialType,
                        onChanged: (val) {
                          setState(() => materialType = val);
                        },
                      ),
                      const Text('YouTube URL'),
                    ],
                  ),
                  if (materialType == 'video')
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'YouTube URL',
                      ),
                      onChanged: (val) => youtubeUrl = val,
                    ),
                  if (materialType == 'file')
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            FilePickerResult? result = await FilePicker.platform
                                .pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['pdf']);
                            if (result != null &&
                                result.files.single.path != null) {
                              setState(() {
                                pickedFile = File(result.files.single.path!);
                              });
                            }
                          },
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Pick PDF File'),
                        ),
                        if (pickedFile != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                                'Selected: ${pickedFile!.path.split('/').last}'),
                          ),
                      ],
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                          setState(() => isUploading = true);
                          if (materialType == 'file') {
                            if (pickedFile == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Please pick a PDF file.')));
                              setState(() => isUploading = false);
                              return;
                            }
                            try {
                              final success = await MaterialUtils.uploadPdf(
                                teacherId: widget.teacherId,
                                selectedClass: selectedClass ?? '',
                                selectedBatch: selectedBatch ?? '',
                                file: pickedFile!,
                              );
                              if (success) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'PDF uploaded successfully!')));
                                _fetchMaterials();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Failed to upload PDF.')));
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')));
                            } finally {
                              setState(() => isUploading = false);
                            }
                          } else if (materialType == 'video') {
                            if (youtubeUrl == null || youtubeUrl!.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Please enter a YouTube URL.')));
                              setState(() => isUploading = false);
                              return;
                            }
                            try {
                              final success = await MaterialUtils.shareVideo(
                                teacherId: widget.teacherId,
                                selectedClass: selectedClass ?? '',
                                selectedBatch: selectedBatch ?? '',
                                videoLink: youtubeUrl!,
                              );
                              if (success) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'YouTube video shared successfully!')));
                                _fetchMaterials();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Failed to share YouTube video.')));
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')));
                            } finally {
                              setState(() => isUploading = false);
                            }
                          }
                        },
                  child: isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Upload'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMaterialsSection() {
    return MaterialsSection(
      materials: materials,
      onViewMaterial: (filePath) {
        // Find the material by filePath to get category and name
        final material = materials.firstWhere(
          (m) => m['filePath'] == filePath || m['videoLink'] == filePath,
          orElse: () => {},
        );

        // Determine the category based on the material type
        String? category;
        if (material['category'] != null) {
          category = material['category'];
        } else if (material['videoLink'] != null) {
          category = 'video';
        } else if (material['filePath'] != null) {
          category = 'file';
        }

        _viewMaterial(
          filePath,
          category: category,
          name: material['name'] ?? material['fileName'] ?? 'Untitled',
        );
      },
      onUploadMaterial: _showUploadMaterialDialog,
    );
  }

  Future<void> _loadAttendance() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final attendanceData = await AttendanceUtils.loadAttendance(
        teacherId: widget.teacherId,
        selectedClass: selectedClass ?? '',
        subjectId: selectedSubjectId ?? '',
      );

      setState(() {
        _attendanceRecords = attendanceData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error in _loadAttendance: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Helper: Stat Box Widget
  Widget _statBox(int value, String label, Color color) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 13, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Helper: Student List Item Widget
  Widget _studentListItem(
      {required int idx, required String name, required bool isPresent}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isPresent
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPresent
              ? AppColors.present.withOpacity(0.3)
              : AppColors.absent.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPresent ? AppColors.present : AppColors.absent,
          child: Text(
            '${idx + 1}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          isPresent ? 'Present' : 'Absent',
          style: TextStyle(
            color: isPresent ? AppColors.present : AppColors.absent,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          isPresent ? Icons.check_circle : Icons.cancel,
          color: isPresent ? AppColors.present : AppColors.absent,
        ),
      ),
    );
  }

  // Helper: Today's Attendance Card
  Widget _todayAttendanceCard(
      List todayRecords, int present, int absent, double percent) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(Icons.calendar_today,
                      color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Today's Attendance",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(
                        DateTime.now().toString().split(' ')[0],
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    '${percent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statBox(present, 'Present', AppColors.present),
                const SizedBox(width: 12),
                _statBox(absent, 'Absent', AppColors.absent),
                const SizedBox(width: 12),
                _statBox(todayRecords.length, 'Total', AppColors.primary),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('Student List',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  )),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: todayRecords.length,
              itemBuilder: (context, idx) {
                final record = todayRecords[idx];
                final studentName =
                    '${record['Student']['fname']} ${record['Student']['lname']}';
                final status = record['status'];
                final isPresent = status == 'present';
                return _studentListItem(
                    idx: idx, name: studentName, isPresent: isPresent);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Take Attendance Card
  Widget _takeAttendanceCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.cardBackground,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await _showTakeAttendanceModal();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.calendar_today,
                    color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Today's Attendance",
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('Tap to take attendance',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.arrow_forward_ios,
                    color: AppColors.primary, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Past Attendance Card

  Widget _pastAttendanceCard(
      String date, int present, int absent, double percent) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(10),
              child:
                  Icon(Icons.access_time, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'Present: $present',
                        style: TextStyle(
                          color: AppColors.present,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Absent: $absent',
                        style: TextStyle(
                          color: AppColors.absent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${percent.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Main Attendance Section (clean)

  Widget _buildAttendanceSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error loading attendance: $_error',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadAttendance,
              icon: Icon(Icons.refresh, size: 16, color: AppColors.primary),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      );
    }

    final today = DateTime.now().toString().split(' ')[0];
    final todayRecords =
        _attendanceRecords.where((record) => record['date'] == today).toList();
    final todayPresent =
        todayRecords.where((r) => r['status'] == 'present').length;
    final todayAbsent =
        todayRecords.where((r) => r['status'] == 'absent').length;
    final todayTotal = todayRecords.length;
    final todayPercent =
        todayTotal > 0 ? (todayPresent / todayTotal) * 100 : 0.0;

    final Map<String, List<dynamic>> groupedRecords = {};
    for (var record in _attendanceRecords) {
      if (record['date'] == today) continue;
      groupedRecords.putIfAbsent(record['date'], () => []).add(record);
    }

    final sortedDates = groupedRecords.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Records',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Show either today's attendance or mark attendance card
          if (todayRecords.isNotEmpty)
            _todayAttendanceCard(
                todayRecords, todayPresent, todayAbsent, todayPercent)
          else
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: AppColors.cardBackground,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  await _showTakeAttendanceModal();
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Icon(Icons.calendar_today,
                            color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Take Today's Attendance",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'No attendance records found. Tap to mark attendance',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.arrow_forward_ios,
                            color: AppColors.primary, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: sortedDates.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.history, color: AppColors.info, size: 48),
                        SizedBox(height: 12),
                        Text(
                          'No past attendance records found.',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.info,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: sortedDates.length,
                    itemBuilder: (context, index) {
                      final date = sortedDates[index];
                      final records = groupedRecords[date]!;
                      final present =
                          records.where((r) => r['status'] == 'present').length;
                      final absent =
                          records.where((r) => r['status'] == 'absent').length;
                      final total = records.length;
                      final percent = total > 0 ? (present / total) * 100 : 0.0;
                      return GestureDetector(
                        onTap: () => _showAttendanceDetailsDialog(
                            context, date, records),
                        child:
                            _pastAttendanceCard(date, present, absent, percent),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAttendanceDetailsDialog(
      BuildContext context, String date, List records) {
    final present = records.where((r) => r['status'] == 'present').length;
    final absent = records.where((r) => r['status'] == 'absent').length;
    final total = records.length;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.background,
                  AppColors.background.withOpacity(0.8)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.calendar_today,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text('Attendance Details',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Colors.white)),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Text('Date: $date',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14)),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statBox(present, 'Present', AppColors.present),
                      _statBox(absent, 'Absent', AppColors.absent),
                      _statBox(total, 'Total', AppColors.primary),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Student List',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary)),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: records.length,
                    itemBuilder: (context, idx) {
                      final record = records[idx];
                      final studentName =
                          '${record['Student']['fname']} ${record['Student']['lname']}';
                      final status = record['status'];
                      final isPresent = status == 'present';
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isPresent
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isPresent
                                ? AppColors.present.withOpacity(0.3)
                                : AppColors.absent.withOpacity(0.3),
                            width: 1.2,
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isPresent
                                ? AppColors.present
                                : AppColors.absent,
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            studentName,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textPrimary),
                          ),
                          subtitle: Row(
                            children: [
                              Text(
                                isPresent ? 'Present' : 'Absent',
                                style: TextStyle(
                                  color: isPresent
                                      ? AppColors.present
                                      : AppColors.absent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          trailing: Icon(
                            isPresent ? Icons.check_circle : Icons.cancel,
                            color: isPresent
                                ? AppColors.present
                                : AppColors.absent,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showTakeAttendanceModal() async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return FutureBuilder<List<dynamic>>(
          future: AttendanceUtils.fetchStudentsForAttendance(
            teacherId: widget.teacherId,
            selectedClass: selectedClass ?? '',
            subjectId: widget.subjectId ?? '',
            medium: selectedMedium ?? '',
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Error'),
                content: Text('Failed to fetch students: ${snapshot.error}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              );
            }

            final students = snapshot.data ?? [];
            final Map<int, bool> attendanceMap = {
              for (var student in students) student['id']: true
            };

            return StatefulBuilder(
              builder: (context, setModalState) {
                bool isSubmitting = false;
                return Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
                  child: StatefulBuilder(
                    builder: (context, setDialogState) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: AppColors.primaryGradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 18),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.calendar_today,
                                        color: Colors.white, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Take Attendance',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.white),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  ),
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Student List',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            Flexible(
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: students.length,
                                itemBuilder: (context, idx) {
                                  final student = students[idx];
                                  final studentName =
                                      '${student['fname']} ${student['lname']}';
                                  final studentId = student['id'] as int;
                                  final isPresent =
                                      attendanceMap[studentId] ?? true;

                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.primaryLight
                                          .withOpacity(0.15),
                                      child: Text(
                                        '${idx + 1}',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      studentName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    trailing: Switch(
                                      value: isPresent,
                                      activeColor: Colors.green,
                                      inactiveThumbColor: Colors.red,
                                      inactiveTrackColor: Colors.red.shade100,
                                      onChanged: (val) {
                                        setModalState(() {
                                          attendanceMap[studentId] = val;
                                        });
                                      },
                                    ),
                                    subtitle: Text(
                                      isPresent ? 'Present' : 'Absent',
                                      style: TextStyle(
                                        color: isPresent
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: isSubmitting
                                      ? null
                                      : () async {
                                          setDialogState(
                                              () => isSubmitting = true);
                                          try {
                                            final result = await AttendanceUtils
                                                .submitAttendance(
                                              teacherId: widget.teacherId,
                                              selectedClass:
                                                  selectedClass ?? '',
                                              subjectId: widget.subjectId ?? '',
                                              attendanceMap: attendanceMap,
                                            );

                                            if (result['success']) {
                                              if (mounted) {
                                                Navigator.of(context).pop();
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Attendance submitted successfully'),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                                _loadAttendance();
                                              }
                                            } else {
                                              throw Exception(
                                                  'Failed to submit attendance: ${result['errors'].join(', ')}');
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text('Error: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          } finally {
                                            if (mounted) {
                                              setDialogState(
                                                  () => isSubmitting = false);
                                            }
                                          }
                                        },
                                  icon: isSubmitting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.save),
                                  label: Text(isSubmitting
                                      ? 'Submitting...'
                                      : 'Submit Attendance'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
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
        title: Row(
          children: [
            Text('Standard $selectedClass ${widget.subject} $selectedBatch'),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildMaterialsSection(),
          _buildAttendanceSection(),
          TestSection(
            teacherId: widget.teacherId,
            selectedClass: selectedClass ?? '',
            selectedBatch: selectedBatch ?? '',
            subjectId: widget.subjectId,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Materials'),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Tests',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: FloatingActionButton(
                onPressed: _showUploadMaterialDialog,
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.upload_file),
              ),
            )
          : null,
    );
  }
}
