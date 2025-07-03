import 'package:flutter/material.dart';
import 'package:tuition/core/themes/app_colors.dart';
import 'package:tuition/widgets/materials/materials_section.dart';
import 'package:tuition/core/services/api_service.dart';
import 'package:tuition/models/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'dart:ui';
import 'package:tuition/widgets/liquid_glass_painter.dart';
import 'package:tuition/screens/teacher/youtube_player_screen.dart';
import 'package:tuition/screens/teacher/pdf_viewer_screen.dart';
import 'package:tuition/screens/teacher/utils/file_download_utils.dart';
import 'package:path/path.dart' as path;

class AdminMaterialsScreen extends StatefulWidget {
  const AdminMaterialsScreen({Key? key}) : super(key: key);

  @override
  State<AdminMaterialsScreen> createState() => _AdminMaterialsScreenState();
}

class _AdminMaterialsScreenState extends State<AdminMaterialsScreen>
    with SingleTickerProviderStateMixin {
  final List<Map<String, String>> _classBatchCombos = [
    {'class': '7', 'batch': 'English'},
    {'class': '7', 'batch': 'Gujarati'},
    {'class': '8', 'batch': 'English'},
    {'class': '8', 'batch': 'Gujarati'},
    {'class': '9', 'batch': 'English'},
    {'class': '9', 'batch': 'Gujarati'},
    {'class': '10', 'batch': 'English'},
    {'class': '10', 'batch': 'Gujarati'},
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onViewMaterial(Map<String, dynamic> material) async {
    if ((material['category'] == 'video' ||
        (material['videoLink'] ?? '').isNotEmpty)) {
      // Open YouTube player
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => YoutubePlayerScreen(
            videoUrl: material['videoLink'],
            title: material['fileName'] ?? 'Video',
          ),
        ),
      );
    } else if ((material['category'] == 'file' ||
        (material['filePath'] ?? '').isNotEmpty)) {
      final filePath = material['filePath'];
      final fileName = material['fileName'] ?? path.basename(filePath ?? '');
      final extension = path.extension(fileName).toLowerCase();
      String progressMessage = 'Downloading file...';
      if (extension == '.pdf') {
        progressMessage = 'Downloading PDF...';
      } else if (['.jpg', '.jpeg', '.png', '.gif', '.bmp']
          .contains(extension)) {
        progressMessage = 'Downloading image...';
      }
      double progress = 0.0;
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
        // Ensure filePath is a full URL
        String fileUrl = filePath;
        if (!fileUrl.startsWith('http')) {
          fileUrl =
              'http://27.116.52.24:8076/uploads/material${fileUrl.startsWith('/') ? fileUrl.substring(1) : fileUrl}';
        }
        final downloadedFile = await FileDownloadUtils.downloadFile(
          fileUrl,
          fileName,
          onProgress: (p) {
            progress = p;
            if (Navigator.of(context).canPop()) {
              (context as Element).markNeedsBuild();
            }
          },
        );
        if (downloadedFile == null || !await downloadedFile.exists()) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File not found after download!')),
          );
          return;
        }
        Navigator.of(context).pop(); // Close progress dialog
        if (extension == '.pdf') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PdfViewerScreen(
                filePath: downloadedFile.path,
                title: fileName,
              ),
            ),
          );
        } else if (['.jpg', '.jpeg', '.png', '.gif', '.bmp']
            .contains(extension)) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
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
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid material.')),
      );
    }
  }

  void _onUploadMaterial() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow.withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Gradient header
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF2A4759),
                      Color(0xFFF79B72),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.upload_file, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Upload Material',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Select a class/batch to upload material.',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Container(
        color: AppColors.scaffoldBackground,
        child: SafeArea(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.4,
            ),
            itemCount: _classBatchCombos.length,
            itemBuilder: (context, idx) {
              final combo = _classBatchCombos[idx];
              final label = '${combo['class']} ${combo['batch']}';
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MaterialListScreen(
                        className: combo['class']!,
                        batch: combo['batch']!,
                        onViewMaterial: _onViewMaterial,
                        onUploadMaterial: _onUploadMaterial,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cardShadow.withOpacity(0.13),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Orange accent bar
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 7,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(18),
                              bottomLeft: Radius.circular(18),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class MaterialListScreen extends StatefulWidget {
  final String className;
  final String batch;
  final Function(Map<String, dynamic>) onViewMaterial;

  const MaterialListScreen({
    Key? key,
    required this.className,
    required this.batch,
    required this.onViewMaterial,
    required void Function() onUploadMaterial,
  }) : super(key: key);

  @override
  State<MaterialListScreen> createState() => _MaterialListScreenState();
}

class _MaterialListScreenState extends State<MaterialListScreen> {
  List<MaterialModel> materials = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMaterials();
  }

  Future<void> _fetchMaterials() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await ApiService().getMaterials(
        teacherId: 2,
        className: widget.className,
        batch: widget.batch,
      );
      setState(() {
        materials = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load materials: $e';
        _isLoading = false;
      });
    }
  }

  void _onUploadMaterial() async {
    File ufile = File('');
    String videoLink = '';
    String fileName = '';
    String selectedType = 'file';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cardShadow.withOpacity(0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gradient header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 18, horizontal: 20),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF2A4759),
                              Color(0xFFF79B72),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.upload_file,
                                color: Colors.white, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Upload Material',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              decoration: InputDecoration(
                                labelText: 'Title',
                                labelStyle: const TextStyle(
                                    color: AppColors.textSecondary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: AppColors.cardBackground),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: AppColors.primary, width: 2),
                                ),
                              ),
                              style:
                                  const TextStyle(color: AppColors.textPrimary),
                              onChanged: (val) {
                                fileName = val.toString();
                              },
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: selectedType == 'file'
                                      ? ElevatedButton.icon(
                                          icon: const Icon(Icons.upload_file,
                                              color: Colors.white),
                                          label: const Text('Upload PDF/Image'),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14),
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: () {
                                            setState(() async {
                                              if (fileName.trim().isEmpty) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'Please enter a title.')),
                                                );
                                                return;
                                              }
                                              FilePickerResult? result =
                                                  await FilePicker.platform
                                                      .pickFiles(
                                                type: FileType.custom,
                                                allowedExtensions: [
                                                  'pdf',
                                                  'png',
                                                  'jpg',
                                                  'jpeg'
                                                ],
                                              );
                                              if (result != null &&
                                                  result.files.single.path !=
                                                      null) {
                                                ufile = File(
                                                    result.files.single.path!);
                                              }
                                            });
                                          },
                                        )
                                      : OutlinedButton.icon(
                                          icon: const Icon(Icons.upload_file,
                                              color: AppColors.primary),
                                          label: const Text('Upload PDF/Image',
                                              style: TextStyle(
                                                  color: AppColors.primary)),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14),
                                            side: const BorderSide(
                                                color: AppColors.primary,
                                                width: 1.5),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: () {
                                            setModalState(() {
                                              selectedType = 'file';
                                            });
                                          },
                                        ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: selectedType == 'video'
                                      ? ElevatedButton.icon(
                                          icon: const Icon(Icons.video_library,
                                              color: Colors.white),
                                          label: const Text('YouTube Video'),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14),
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: () {
                                            setModalState(() {
                                              selectedType = 'video';
                                            });
                                          },
                                        )
                                      : OutlinedButton.icon(
                                          icon: const Icon(Icons.video_library,
                                              color: AppColors.primary),
                                          label: const Text('YouTube Video',
                                              style: TextStyle(
                                                  color: AppColors.primary)),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14),
                                            side: const BorderSide(
                                                color: AppColors.primary,
                                                width: 1.5),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: () {
                                            setModalState(() {
                                              selectedType = 'video';
                                            });
                                          },
                                        ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            if (selectedType == 'video')
                              TextField(
                                decoration: InputDecoration(
                                  labelText: 'YouTube Video Link',
                                  labelStyle: const TextStyle(
                                      color: AppColors.textSecondary),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: AppColors.cardBackground),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: AppColors.primary, width: 2),
                                  ),
                                ),
                                style: const TextStyle(
                                    color: AppColors.textPrimary),
                                onChanged: (val) {
                                  videoLink = val;
                                },
                              ),
                            if (selectedType == 'video')
                              const SizedBox(height: 12),
                            if (selectedType == 'video')
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Share Video'),
                                  onPressed: () async {
                                    if (fileName.trim().isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Please enter a title.')),
                                      );
                                      return;
                                    }
                                    if (videoLink.trim().isNotEmpty) {
                                      Navigator.pop(context);
                                      await _uploadVideo(
                                          videoLink.trim(), fileName);
                                    }
                                  },
                                ),
                              ),
                            if (selectedType == 'file')
                              const SizedBox(height: 12),
                            if (selectedType == 'file')
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Upload PDF/Image'),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    _uploadFile(ufile, fileName);
                                  },
                                ),
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
        );
      },
    );
  }

  Future<void> _uploadFile(File file, String fileName) async {
    try {
      final uploaded = await ApiService().uploadMaterialFile(
        teacherId: 2,
        className: widget.className,
        batch: widget.batch,
        file: file,
        fileName: fileName,
      );
      if (uploaded != null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Material uploaded successfully')));
        _fetchMaterials();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload material')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _uploadVideo(String videoLink, String fileName) async {
    try {
      final uploaded = await ApiService().shareVideoLink(
        teacherId: 2,
        className: widget.className,
        batch: widget.batch,
        videoLink: videoLink,
        fileName: fileName,
      );
      if (uploaded != null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video shared successfully')));
        _fetchMaterials();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to share video')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.scaffoldBackground,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Materials: ${widget.className} ${widget.batch}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file,
                color: AppColors.primary, size: 28),
            tooltip: 'Upload Material',
            onPressed: _onUploadMaterial,
          ),
        ],
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)))
              : materials.isEmpty
                  ? const Center(child: Text('No Materials available'))
                  : MaterialsSection(
                      materials: materials.map((m) => m.toMap()).toList(),
                      onViewMaterial: widget.onViewMaterial,
                      onUploadMaterial: _onUploadMaterial,
                    ),
    );
  }
}
