import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:tuition/core/themes/app_colors.dart';
import 'package:screen_protector/screen_protector.dart';

class TimedPdfViewerScreen extends StatefulWidget {
  final String filePath;
  final String title;
  final DateTime endTime;

  const TimedPdfViewerScreen({
    Key? key,
    required this.filePath,
    required this.title,
    required this.endTime,
  }) : super(key: key);

  @override
  State<TimedPdfViewerScreen> createState() => _TimedPdfViewerScreenState();
}

class _TimedPdfViewerScreenState extends State<TimedPdfViewerScreen> {
  Timer? _endTimer;

  @override
  void initState() {
    super.initState();
    _protectScreen();
    final now = DateTime.now();
    final remaining = widget.endTime.difference(now);
    if (remaining.isNegative) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _redirectToCompleted();
      });
    } else {
      _endTimer = Timer(remaining, _redirectToCompleted);
    }
  }

  Future<void> _protectScreen() async {
    await ScreenProtector.preventScreenshotOn();
  }
  void _redirectToCompleted() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test time is over. Redirecting to Completed Tests.')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _endTimer?.cancel();
    ScreenProtector.preventScreenshotOff();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            )),
        centerTitle: true,
        elevation: 4,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.primaryGradient,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PDFView(
        filePath: widget.filePath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        pageSnap: true,
        fitPolicy: FitPolicy.BOTH,
        preventLinkNavigation: false,
      ),
    );
  }
} 