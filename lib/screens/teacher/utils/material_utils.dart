import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class MaterialUtils {
  static String getFullFileUrl(String filePath) {
    if (filePath.startsWith('http')) {
      return filePath;
    }
    return 'http://27.116.52.24:8076/${filePath.startsWith('/') ? filePath.substring(1) : filePath}';
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

  static Future<bool> uploadPdf({
    required int teacherId,
    required String selectedClass,
    required String selectedBatch,
    required File file,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://27.116.52.24:8076/material/upload'),
      );
      request.fields['teacherId'] = teacherId.toString();
      request.fields['class'] = selectedClass;
      request.fields['batch'] = selectedBatch;
      request.fields['category'] = 'file';
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
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<File?> downloadPdf(String filePath, String fileName) async {
    try {
      // Clean up the filePath and construct the URL properly
      String cleanPath = filePath.startsWith('/') ? filePath.substring(1) : filePath;
      // Remove any double slashes
      cleanPath = cleanPath.replaceAll(RegExp(r'\/+'), '/');

      // Split the path into segments and encode each segment
      final pathSegments = cleanPath.split('/');
      final encodedSegments = pathSegments
          .map((segment) => Uri.encodeComponent(segment))
          .toList();

      // Reconstruct the path with encoded segments
      final encodedPath = encodedSegments.join('/');
      // Use the correct server URL
      final fullUrl = 'http://27.116.52.24:8076/$encodedPath';

      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {
          'Accept': '*/*',
          'Content-Type': '*/*',
        },
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        if (bytes.isEmpty) {
          throw Exception('Downloaded file is empty');
        }

        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$fileName');

        await tempFile.writeAsBytes(bytes, flush: true);

        if (!await tempFile.exists()) {
          throw Exception('Failed to save file locally');
        }

        return tempFile;
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      print('Error downloading PDF: $e');
      rethrow;
    }
  }
}
