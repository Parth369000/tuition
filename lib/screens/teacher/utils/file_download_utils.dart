import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class FileDownloadUtils {
  /// Downloads a file (PDF, image, etc.) from [fileUrl] and saves it as [fileName] in the temp directory.
  /// Returns the downloaded File, or null if failed. Calls [onProgress] with progress (0.0-1.0) if provided.
  static Future<File?> downloadFile(String fileUrl, String fileName,
      {void Function(double progress)? onProgress}) async {
    try {
      final uri = Uri.parse(fileUrl);
      final response = await http.Client().send(http.Request('POST', uri));
      if (response.statusCode == 200) {
        final contentLength = response.contentLength ?? 0;
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(path.join(tempDir.path, fileName));
        final sink = tempFile.openWrite();
        int received = 0;
        await for (final chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (onProgress != null && contentLength > 0) {
            onProgress(received / contentLength);
          }
        }
        await sink.close();
        if (!await tempFile.exists()) {
          throw Exception('Failed to save file locally');
        }
        return tempFile;
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      print('Error downloading file: $e');
      return null;
    }
  }
}
