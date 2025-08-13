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
import 'package:tuition/screens/teacher/utils/material_utils.dart';
import 'package:path/path.dart' as path;
import 'package:tuition/models/subject.dart';
import 'package:tuition/controllers/subject_controller.dart';

class AdminMaterialsScreen extends StatefulWidget {
  const AdminMaterialsScreen({Key? key}) : super(key: key);

  @override
  State<AdminMaterialsScreen> createState() => _AdminMaterialsScreenState();
}

class _AdminMaterialsScreenState extends State<AdminMaterialsScreen>
    with SingleTickerProviderStateMixin {
  // Show only unique classes
  final List<String> _classes = ['7', '8', '9', '10'];

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
        final downloadedFile = await MaterialUtils.downloadMaterial(
          filePath,
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
            itemCount: _classes.length,
            itemBuilder: (context, idx) {
              final className = _classes[idx];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MaterialListScreen(
                        className: className,
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
                          className,
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
  final Function(Map<String, dynamic>) onViewMaterial;

  const MaterialListScreen({
    Key? key,
    required this.className,
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
  Map<String, List<Map<String, dynamic>>> groupedByBatch = {};
  Map<int, String> subjectIdToName = {};
  bool _isSubjectsLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubjectsAndMaterials();
  }

  Future<void> _fetchSubjectsAndMaterials() async {
    setState(() {
      _isLoading = true;
      _isSubjectsLoading = true;
      _error = null;
    });
    try {
      // Fetch subjects
      final subjects = await SubjectController().getSubjects();
      subjectIdToName = {for (var s in subjects) s.id: s.name};
      _isSubjectsLoading = false;
      // Fetch materials
      final result = await ApiService().getMaterials(
        teacherId: 2,
        className: widget.className,
      );
      materials = result;
      // Group materials by batch
      groupedByBatch = {};
      for (final m in materials) {
        final batch = m.batch ?? '';
        if (batch.isNotEmpty) {
          groupedByBatch.putIfAbsent(batch, () => []);
          groupedByBatch[batch]!.add(m.toMap());
        }
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load materials: $e';
        _isLoading = false;
        _isSubjectsLoading = false;
      });
    }
  }

  void _onUploadMaterial() async {
    File ufile = File('');
    String videoLink = '';
    String fileName = '';
    String selectedType = 'file';
    Subject? selectedSubject;
    List<Subject> subjects = [];
    bool isLoadingSubjects = true;
    String? subjectError;
    String? selectedMedium;
    final List<String> mediums = ['English', 'Gujarati'];

    await showModalBottomSheet(
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
              // Fetch subjects on first build
              if (isLoadingSubjects) {
                SubjectController().getSubjects().then((list) {
                  setModalState(() {
                    subjects = list;
                    isLoadingSubjects = false;
                  });
                }).catchError((e) {
                  setModalState(() {
                    subjectError = e.toString();
                    isLoadingSubjects = false;
                  });
                });
              }
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
                            // Medium Dropdown
                            DropdownButtonFormField<String>(
                              value: selectedMedium,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Select Medium',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              items: mediums.map((medium) {
                                return DropdownMenuItem<String>(
                                  value: medium,
                                  child: Text(medium),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setModalState(() {
                                  selectedMedium = val;
                                });
                              },
                            ),
                            const SizedBox(height: 18),
                            // Subject Dropdown
                            isLoadingSubjects
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : subjectError != null
                                    ? Text(
                                        'Failed to load subjects: ' +
                                            subjectError!,
                                        style:
                                            const TextStyle(color: Colors.red))
                                    : DropdownButtonFormField<Subject>(
                                        value: selectedSubject,
                                        isExpanded: true,
                                        decoration: InputDecoration(
                                          labelText: 'Select Subject',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        items: subjects.map((subject) {
                                          return DropdownMenuItem<Subject>(
                                            value: subject,
                                            child: Text(subject.name),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          setModalState(() {
                                            selectedSubject = val;
                                          });
                                        },
                                      ),
                            const SizedBox(height: 18),
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
                                              if (selectedMedium == null) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'Please select a medium.')),
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
                                    if (selectedMedium == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Please select a medium.')),
                                      );
                                      return;
                                    }
                                    if (selectedSubject == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Please select a subject.')),
                                      );
                                      return;
                                    }
                                    if (videoLink.trim().isNotEmpty) {
                                      Navigator.pop(context);
                                      await _uploadVideo(
                                          videoLink.trim(),
                                          fileName,
                                          selectedSubject,
                                          selectedMedium);
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
                                    if (selectedMedium == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Please select a medium.')),
                                      );
                                      return;
                                    }
                                    if (selectedSubject == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Please select a subject.')),
                                      );
                                      return;
                                    }
                                    Navigator.pop(context);
                                    _uploadFile(ufile, fileName,
                                        selectedSubject, selectedMedium);
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

  Future<void> _uploadFile(
      File file, String fileName, Subject? subject, String? medium) async {
    if (subject == null || medium == null) return;
    try {
      final batch = "$medium-${subject.id}";
      final uploaded = await ApiService().uploadMaterialFile(
        teacherId: 2,
        className: widget.className,
        batch: batch,
        file: file,
        fileName: fileName,
      );
      if (uploaded != null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Material uploaded successfully')));
        _fetchSubjectsAndMaterials(); // Refresh materials and subjects
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload material')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _uploadVideo(String videoLink, String fileName, Subject? subject,
      String? medium) async {
    if (subject == null || medium == null) return;
    try {
      final batch = "$medium-${subject.id}";
      final uploaded = await ApiService().shareVideoLink(
        teacherId: 2,
        className: widget.className,
        batch: batch,
        videoLink: videoLink,
        fileName: fileName,
      );
      if (uploaded != null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video shared successfully')));
        _fetchSubjectsAndMaterials(); // Refresh materials and subjects
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
          'Materials: ${widget.className}',
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
      body: _isLoading || _isSubjectsLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)))
              : groupedByBatch.isEmpty
                  ? const Center(child: Text('No Materials available'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: groupedByBatch.entries.map((batchEntry) {
                        final batch = batchEntry.key;
                        final mats = batchEntry.value;
                        // Parse medium and subjectId
                        final parts = batch.split('-');
                        String batchDisplay = batch;
                        if (parts.length == 2) {
                          final medium = parts[0];
                          final subjectId = int.tryParse(parts[1]);
                          final subjectName = subjectIdToName[subjectId] ??
                              'Subject $subjectId';
                          batchDisplay = '$medium - $subjectName';
                        }
                        return Card(
                          margin: const EdgeInsets.only(bottom: 24),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ListTile(
                            leading:
                                Icon(Icons.label, color: AppColors.primary),
                            title: Text(
                              batchDisplay,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                                '${mats.length} file${mats.length == 1 ? '' : 's'}'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BatchMaterialsScreen(
                                    batchName: batchDisplay,
                                    materials: mats,
                                    onViewMaterial: widget.onViewMaterial,
                                    onUploadMaterial: _onUploadMaterial,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ),
    );
  }
}

class BatchMaterialsScreen extends StatelessWidget {
  final String batchName;
  final List<Map<String, dynamic>> materials;
  final Function(Map<String, dynamic>) onViewMaterial;
  final VoidCallback onUploadMaterial;

  const BatchMaterialsScreen({
    Key? key,
    required this.batchName,
    required this.materials,
    required this.onViewMaterial,
    required this.onUploadMaterial,
  }) : super(key: key);

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: MaterialsSection(
          materials: materials,
          onViewMaterial: onViewMaterial,
          onUploadMaterial: onUploadMaterial,
        ),
      ),
    );
  }
}
