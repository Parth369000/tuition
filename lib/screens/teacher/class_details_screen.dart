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
import '../../widgets/custom_bottom_navigation.dart';

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
  bool _isRefreshing = false;

  bool get hasAttendanceForToday {
    final today = DateTime.now().toString().split(' ')[0];
    return _attendanceRecords.any((record) => record['date'] == today);
  }

  @override
  void initState() {
    super.initState();
    selectedClass = widget.classKey;
    selectedBatch = widget.subjectId;
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

  // Helper to extract YouTube video ID from various URL formats
  String? extractYouTubeVideoId(String url) {
    // First try the built-in method
    String? videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId != null) {
      return videoId;
    }

    // Handle live stream URLs and other formats
    final patterns = [
      // Live stream format: https://www.youtube.com/live/VIDEO_ID
      RegExp(r'youtube\.com/live/([a-zA-Z0-9_-]+)'),
      // Standard format: https://www.youtube.com/watch?v=VIDEO_ID
      RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]+)'),
      // Short format: https://youtu.be/VIDEO_ID
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]+)'),
      // Embed format: https://www.youtube.com/embed/VIDEO_ID
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]+)'),
      // Live stream with feature: https://www.youtube.com/live/VIDEO_ID?feature=shared
      RegExp(r'youtube\.com/live/([a-zA-Z0-9_-]+)\?'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }

    return null;
  }

  Future<void> _viewMaterial(Map<String, dynamic> material,
      {String? category, String? name}) async {
    final filePath = material['filePath'] ?? '';
    final videoLink = material['videoLink'] ?? '';
    print('Original filePath: $filePath');
    print('Category: $category');
    if (category == 'file') {
      double progress = 0.0;
      final extension = path.extension(name ?? filePath).toLowerCase();
      String progressMessage = 'Downloading file...';
      if (extension == '.pdf') {
        progressMessage = 'Downloading PDF...';
      } else if (['.jpg', '.jpeg', '.png', '.gif', '.bmp']
          .contains(extension)) {
        progressMessage = 'Downloading image...';
      }
      // Show progress dialog
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
        final fileName = name ?? path.basename(filePath);
        final downloadedFile = await MaterialUtils.downloadPdf(
          filePath,
          fileName,
          onProgress: (p) {
            progress = p;
            // Update the dialog
            if (Navigator.of(context).canPop()) {
              (context as Element).markNeedsBuild();
            }
          },
        );

        if (downloadedFile == null || !await downloadedFile.exists()) {
          Navigator.of(context).pop(); // Close progress dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File not found after download!')),
          );
          return;
        }

        Navigator.of(context).pop(); // Close progress dialog

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
      } catch (e) {
        Navigator.of(context).pop(); // Close progress dialog if error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } else if (category == 'video') {
      // Open YouTube player
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => YoutubePlayerScreen(
            videoUrl: videoLink,
            title: name ?? 'Video',
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
        selectedBatch: selectedBatch ?? 'A',
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
    String? videoTitle;
    File? pickedFile;
    bool isUploading = false;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              title: Text('Upload Material',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  )),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Radio<String>(
                        value: 'file',
                        groupValue: materialType,
                        onChanged: (val) {
                          setState(() => materialType = val);
                        },
                        activeColor: AppColors.secondary,
                      ),
                      Text('PDF',
                          style: TextStyle(color: AppColors.textPrimary)),
                      Radio<String>(
                        value: 'video',
                        groupValue: materialType,
                        onChanged: (val) {
                          setState(() => materialType = val);
                        },
                        activeColor: AppColors.secondary,
                      ),
                      Text('YouTube URL',
                          style: TextStyle(color: AppColors.textPrimary)),
                    ],
                  ),
                  if (materialType == 'video') ...[
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Video Title',
                        hintText: 'Enter video title',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => videoTitle = val,
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'YouTube URL',
                        hintText: 'https://www.youtube.com/watch?v=...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => youtubeUrl = val,
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ],
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
                          icon: Icon(Icons.attach_file,
                              color: AppColors.secondary),
                          label: Text('Pick PDF File',
                              style: TextStyle(color: AppColors.secondary)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                AppColors.secondary.withOpacity(0.08),
                            foregroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        if (pickedFile != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Selected: ${pickedFile!.path.split('/').last}',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel',
                      style: TextStyle(color: AppColors.secondary)),
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
                            if (videoTitle == null || videoTitle!.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Please enter a video title.')));
                              setState(() => isUploading = false);
                              return;
                            }
                            try {
                              final success = await MaterialUtils.shareVideo(
                                teacherId: widget.teacherId,
                                selectedClass: selectedClass ?? '',
                                selectedBatch: selectedBatch ?? '',
                                videoLink: youtubeUrl!,
                                videoTitle: videoTitle!,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Upload',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
      onViewMaterial: (material) {
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
          material,
          category: category,
          name: material['fileName'] ?? material['videoLink'] ?? 'Untitled',
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
        color: color.withOpacity(0.2),
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

  // Helper: Today's Attendance Card (summary, tap to view details)
  Widget _todayAttendanceSummaryCard(
      List todayRecords, int present, int absent, double percent, String date) {
    return GestureDetector(
      onTap: () => _showAttendanceDetailsDialog(context, date, todayRecords),
      child: Card(
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
                      color: AppColors.secondary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Icon(Icons.calendar_today,
                        color: AppColors.secondary, size: 28),
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
                          date,
                          style: TextStyle(
                              fontSize: 13, color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      '${percent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _statBox(present, 'Present', AppColors.present),
                  const SizedBox(width: 12),
                  _statBox(absent, 'Absent', AppColors.absent),
                  const SizedBox(width: 12),
                  _statBox(todayRecords.length, 'Total', AppColors.primary),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              Center(
                child: Text(
                  'Tap to view student list',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
                color: AppColors.secondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(10),
              child:
                  Icon(Icons.access_time, color: AppColors.secondary, size: 24),
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
                      Icon(Icons.check_circle,
                          color: AppColors.present, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Present: $present',
                        style: TextStyle(
                          color: AppColors.present,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.cancel, color: AppColors.absent, size: 16),
                      const SizedBox(width: 4),
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
                color: AppColors.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${percent.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: AppColors.secondary,
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
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 16),
          // Show either today's attendance summary or mark attendance card
          if (todayRecords.isNotEmpty)
            _todayAttendanceSummaryCard(
                todayRecords, todayPresent, todayAbsent, todayPercent, today)
          else
            Card(
              elevation: 4,
              shadowColor: AppColors.secondary.withOpacity(0.10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  await _showTakeAttendanceModal();
                },
                child: Container(
                  color: AppColors.cardSurface,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 20),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Icon(Icons.calendar_today,
                              color: AppColors.secondary, size: 28),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Take Attendance",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: AppColors.secondary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'No attendance records found. Tap to mark attendance',
                                style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        AppColors.secondary.withOpacity(0.85)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Icon(Icons.arrow_forward_ios,
                              color: AppColors.secondary, size: 20),
                        ),
                      ],
                    ),
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
                      children: [
                        Icon(Icons.history,
                            color: AppColors.secondary, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'No past attendance records found.',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
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
          backgroundColor: AppColors.cardBackground,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
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
                          color: AppColors.secondary.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.calendar_today,
                            color: AppColors.secondary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text('Attendance Details',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: AppColors.secondary)),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.secondary),
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
                              color: AppColors.secondary, fontSize: 14)),
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
                              ? AppColors.present.withOpacity(0.08)
                              : AppColors.absent.withOpacity(0.08),
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
    DateTime selectedAttendanceDate = DateTime.now();
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.08),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.secondary, AppColors.primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.only(
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
                                  color: Colors.white.withOpacity(0.18),
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
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        ),
                        // Date Picker Row
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              const Text(
                                'Date:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedAttendanceDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      selectedAttendanceDate = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.secondary.withOpacity(0.13),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.date_range,
                                          color: AppColors.secondary, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${selectedAttendanceDate.year}-${selectedAttendanceDate.month.toString().padLeft(2, '0')}-${selectedAttendanceDate.day.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Student List',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textPrimary,
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

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.secondary
                                            .withOpacity(0.06),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          AppColors.secondary.withOpacity(0.13),
                                      child: Text(
                                        '${idx + 1}',
                                        style: TextStyle(
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      studentName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    subtitle: Text(
                                      isPresent ? 'Present' : 'Absent',
                                      style: TextStyle(
                                        color: isPresent
                                            ? AppColors.success
                                            : AppColors.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    trailing: Switch(
                                      value: isPresent,
                                      activeColor: AppColors.success,
                                      inactiveThumbColor: AppColors.error,
                                      inactiveTrackColor:
                                          AppColors.error.withOpacity(0.1),
                                      onChanged: (val) {
                                        setModalState(() {
                                          attendanceMap[studentId] = val;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      setModalState(() => isSubmitting = true);
                                      try {
                                        final result = await AttendanceUtils
                                            .submitAttendance(
                                          teacherId: widget.teacherId,
                                          selectedClass: selectedClass ?? '',
                                          subjectId: widget.subjectId ?? '',
                                          attendanceMap: attendanceMap,
                                          date: selectedAttendanceDate,
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
                                                    AppColors.success,
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
                                              backgroundColor: AppColors.error,
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setModalState(
                                              () => isSubmitting = false);
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: isSubmitting
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
                                  : const Text('Submit Attendance',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _refreshPage() async {
    setState(() => _isRefreshing = true);
    await Future.wait([
      _loadAttendance(),
      _fetchMaterials(),
    ]);
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2A4759), // dark blue-gray
                Color(0xFF1E3440), // darker blue-gray
                Color(0xFF152A35), // deepest blue-gray
              ],
            ),
          ),
        ),
        elevation: 4,
        title: Row(
          children: [
            Text('Std ${selectedClass}th ${widget.subject}',
                style: TextStyle(
                  color: AppColors.surface,
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    _buildMaterialsSection(),
                    _buildAttendanceSection(),
                    TestSection(
                      teacherId: widget.teacherId,
                      selectedClass: selectedClass ?? '',
                      selectedBatch: selectedBatch ?? '',
                      subjectId: widget.subjectId,
                      medium: selectedMedium ?? '',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: CustomBottomNavigation(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
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
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _showUploadMaterialDialog,
              backgroundColor: AppColors.secondary,
              child: const Icon(Icons.upload_file, color: Colors.white),
            )
          : null,
    );
  }
}
