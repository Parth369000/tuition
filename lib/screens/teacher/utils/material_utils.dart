import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class MaterialUtils {
  static String getFullFileUrl(String filePath) {
    // Remove leading slash if present
    String cleanPath =
        filePath.startsWith('/') ? filePath.substring(1) : filePath;
    cleanPath = cleanPath.replaceAll(RegExp(r'/+'), '/');
    final pathSegments = cleanPath.split('/');
    final encodedSegments =
        pathSegments.map((segment) => Uri.encodeComponent(segment)).toList();
    final encodedPath = encodedSegments.join('/');

    // Only prepend 'uploads/material/' if not already present
    if (cleanPath.startsWith('uploads/material/')) {
      return 'http://27.116.52.24:8076/$encodedPath';
    } else {
      return 'http://27.116.52.24:8076/uploads/material/$encodedPath';
    }
  }

  static Future<List<Map<String, dynamic>>> fetchMaterials({
    required int teacherId,
    required String selectedClass,
    required String selectedBatch,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('http://27.116.52.24:8076/material/getMaterials'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'teacherId': teacherId,
          'class': selectedClass,
          'batch': selectedBatch,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['errorStatus'] == false && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<bool> uploadMaterial({
    required int teacherId,
    required String selectedClass,
    required String selectedBatch,
    required File file,
    String category = 'file', // 'file' for PDF, 'image' for images
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://27.116.52.24:8076/material/upload'),
      );
      request.fields['teacherId'] = teacherId.toString();
      request.fields['class'] = selectedClass;
      request.fields['batch'] = selectedBatch;
      request.fields['category'] = category;
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );
      var response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> shareVideo({
    required int teacherId,
    required String selectedClass,
    required String selectedBatch,
    required String videoLink,
    required String videoTitle,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('http://27.116.52.24:8076/material/shareVideo'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'teacherId': teacherId.toString(),
          'class': selectedClass,
          'batch': selectedBatch,
          'videoLink': videoLink,
          'category': 'video',
          'fileName': videoTitle,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<File?> downloadMaterial(String filePath, String fileName,
      {void Function(double progress)? onProgress}) async {
    File? tempFile;
    IOSink? sink;
    try {
      final fullUrl = getFullFileUrl(filePath);
      final request = http.Request('GET', Uri.parse(fullUrl));
      final response = await request.send();

      if (response.statusCode == 200) {
        final contentLength = response.contentLength ?? 0;
        final tempDir = await getTemporaryDirectory();
        tempFile = File('${tempDir.path}/$fileName');
        sink = tempFile.openWrite();
        int received = 0;

        await for (final chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (onProgress != null && contentLength > 0) {
            onProgress(received / contentLength);
          }
        }
        await sink.close();
        sink = null;

        if (!await tempFile.exists()) {
          debugPrint('Failed to save file locally');
          return null;
        }
        return tempFile;
      } else {
        debugPrint('Failed to download file: HTTP ${response.statusCode}');
        return null;
      }
    } catch (e, stack) {
      debugPrint('Error downloading material: $e\n$stack');
      return null;
    } finally {
      if (sink != null) {
        await sink.close();
      }
    }
  }
}
