import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/student.dart';

class StudentService {
  // http://192.168.201.130:3690
  //http://192.168.29.73:3690/
  // http://27.116.52.24:8076
  static const String baseUrl = 'http://27.116.52.24:8076';

  Future<List<Student>> getAllStudents() async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/getAllStudents'));

      if (response.statusCode == 200) {
        // Parse the response body as JSON
        final dynamic jsonResponse = json.decode(response.body);
        print('Response type: ${jsonResponse.runtimeType}');
        print('Response data: $jsonResponse');

        // Check if the response has the expected structure
        if (jsonResponse is Map<String, dynamic> &&
            jsonResponse.containsKey('data')) {
          final dynamic data = jsonResponse['data'];
          print('Data type: ${data.runtimeType}');

          if (data is List) {
            return data.map((json) => Student.fromJson(json)).toList();
          } else {
            throw Exception('Invalid data format: Expected a list of students');
          }
        } else {
          throw Exception('Invalid response format: Expected data field');
        }
      } else {
        throw Exception('Failed to load students: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAllStudents: $e');
      if (e is FormatException) {
        throw Exception('Invalid response format from server');
      } else {
        throw Exception('Error fetching students: $e');
      }
    }
  }

  Future<bool> addStudent({
    required String studentClass,
    required String batch,
    required String feePaid,
    required String feeTotal,
    required String bdate,
    required String address,
    required String board,
    required String school,
    required String fname,
    required String mname,
    required String lname,
    required String medium,
    required String contact,
    required String parentContact,
    File? image,
  }) async {
    try {
      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/addStudent'));

      // Add text fields
      request.fields.addAll({
        'studentClass': studentClass,
        'batch': batch,
        'feePaid': feePaid,
        'feeTotal': feeTotal,
        'bdate': bdate,
        'address': address,
        'board': board,
        'school': school,
        'fname': fname,
        'mname': mname,
        'lname': lname,
        'medium': medium,
        'contact': contact,
        'parentContact': parentContact,
      });

      // Add image if provided
      if (image != null) {
        // Get file extension and determine MIME type
        final extension = image.path.split('.').last.toLowerCase();
        String mimeType;
        switch (extension) {
          case 'jpg':
          case 'jpeg':
            mimeType = 'image/jpeg';
            break;
          case 'png':
            mimeType = 'image/png';
            break;
          default:
            throw Exception('Unsupported image format');
        }

        // Create multipart file with correct MIME type
        final multipartFile = await http.MultipartFile.fromPath(
          'image',
          image.path,
          contentType: MediaType.parse(mimeType),
        );
        request.files.add(multipartFile);
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);

        // Check for error status in response
        if (jsonResponse['errorStatus'] == false) {
          // Success case
          final data = jsonResponse['data'];
          if (data != null && data['message'] != null) {
            print('Success message: ${data['message']}');
            return true;
          }
        } else {
          // Error case
          final errorMessage =
              jsonResponse['message'] ?? 'Failed to add student';
          throw Exception(errorMessage);
        }
      }

      throw Exception(
          'Failed to add student: ${response.statusCode} - $responseBody');
    } catch (e) {
      print('Error in addStudent: $e');
      throw Exception('Failed to add student: $e');
    }
  }
}
