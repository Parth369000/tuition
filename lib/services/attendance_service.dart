import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';

class AttendanceService {
  static const String baseUrl = 'http://27.116.52.24:8076';

  // Get classes for a teacher
  static Future<List<Map<String, dynamic>>> getClassesForTeacher({
    required int teacherId,
  }) async {
    try {
      print('Getting classes for teacher ID: $teacherId');

      var headers = {'Content-Type': 'application/json'};
      var request =
          http.Request('POST', Uri.parse('$baseUrl/getClassesForTeacher'));
      request.body = json.encode({
        "teacherId": teacherId,
      });
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      print('GetClassesForTeacher response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);

        print('GetClassesForTeacher response: $data');

        if (data['errorStatus'] == false) {
          final classesList = data['data'] as List;
          print('Loaded ${classesList.length} classes for teacher');
          return classesList.cast<Map<String, dynamic>>().toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load classes');
        }
      } else {
        throw Exception('Failed to load classes: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error loading classes for teacher: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> getStudentsForTeacher({
    required int teacherId,
    required String className,
    required int subjectId,
    required String medium,
  }) async {
    try {
      var headers = {'Content-Type': 'application/json'};

      var request =
          http.Request('POST', Uri.parse('$baseUrl/getStudentsForTeacher'));
      request.body = json.encode({
        "teacherId": teacherId,
        "class": className,
        "subjectId": subjectId,
        "medium": medium,
      });
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);

        if (data['errorStatus'] == false) {
          final studentsList = data['data'] as List;
          print('Loaded ${studentsList.length} students');
          return studentsList;
        } else {
          throw Exception(data['message'] ?? 'Failed to load students');
        }
      } else {
        throw Exception('Failed to load students: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error loading students: $e');
      rethrow;
    }
  }

  // Get attendance records for a date range
  static Future<List<Map<String, dynamic>>> getAttendanceRecords({
    required int teacherId,
    required String className,
    required int subjectId,
    required String medium,
    required String startDate,
    required String endDate,
  }) async {
    try {
      print('Getting attendance records for:');
      print('Teacher ID: $teacherId');
      print('Class: $className');
      print('Subject ID: $subjectId');
      print('Medium: $medium');
      print('Start Date: $startDate');
      print('End Date: $endDate');

      var headers = {'Content-Type': 'application/json'};
      var request = http.Request('POST', Uri.parse('$baseUrl/getAttendance'));
      request.body = json.encode({
        "teacherId": "",
        "class": className,
        "subjectId": subjectId,
        "medium": "",
        "startDate": startDate,
        "endDate": endDate,
      });
      request.headers.addAll(headers);

      print('GetAttendance request body: ${json.encode(request.body)}');

      http.StreamedResponse response = await request.send();

      print('GetAttendance response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);

        print('GetAttendance response: $data');

        if (data['errorStatus'] == false) {
          final records = data['data'] as List? ?? [];
          print('Found ${records.length} attendance records');

          // Transform the data to include student name
          final transformedRecords = records.map((record) {
            final recordMap = record as Map<String, dynamic>;
            final student = recordMap['Student'] as Map<String, dynamic>? ?? {};
            return {
              ...recordMap,
              'studentName':
                  '${student['fname'] ?? ''} ${student['lname'] ?? ''}'.trim(),
              'studentId': recordMap['studentId'],
              'status': recordMap['status'],
              'date': recordMap['date'],
            };
          }).toList();

          return transformedRecords;
        } else {
          print('No attendance records found for the specified criteria');
          return [];
        }
      } else {
        throw Exception(
            'Failed to get attendance records: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error getting attendance records: $e');
      rethrow;
    }
  }

  // Submit attendance records
  static Future<Map<String, dynamic>> submitAttendance({
    required String teacherId,
    required String studentId,
    required String date,
    required String status,
    required String subjectId,
    required String medium,
  }) async {
    try {
      print('Submitting attendance for student: $studentId');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/markAttendance'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'teacherId': teacherId,
          'studentId': studentId,
          'date': date,
          'status': status,
          'subjectId': subjectId,
          'medium': medium,
        }),
      );

      print('Submit attendance response status: ${response.statusCode}');
      print('Submit attendance response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to submit attendance: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error submitting attendance: $e');
      rethrow;
    }
  }

  // Check if attendance already exists for a specific date
  static Future<bool> checkAttendanceExists({
    required String teacherId,
    required String className,
    required String subjectId,
    required String medium,
    required String date,
  }) async {
    try {
      print('Checking attendance existence for:');
      print('Teacher ID: $teacherId');
      print('Class: $className');
      print('Subject ID: $subjectId');
      print('Medium: $medium');
      print('Date: $date');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/getAttendance'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'teacherId': teacherId,
          'class': className,
          'subjectId': subjectId,
          'medium': medium,
          'date': date,
        }),
      );

      print('Check attendance response status: ${response.statusCode}');
      print('Check attendance response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if attendance exists
        if (data is Map<String, dynamic>) {
          if (data.containsKey('errorStatus')) {
            // If errorStatus is false, attendance exists
            return data['errorStatus'] == false;
          }
        }
        return false;
      } else {
        print('Error checking attendance: ${response.reasonPhrase}');
        return false;
      }
    } catch (e) {
      print('Error checking attendance existence: $e');
      return false;
    }
  }

  // Get attendance statistics for a date range
  static Future<Map<String, dynamic>> getAttendanceStatistics({
    required int teacherId,
    required String className,
    required int subjectId,
    required String medium,
    required String startDate,
    required String endDate,
  }) async {
    try {
      print('Getting attendance statistics for date range:');
      print('Teacher ID: $teacherId');
      print('Class: $className');
      print('Subject ID: $subjectId');
      print('Medium: $medium');
      print('Start Date: $startDate');
      print('End Date: $endDate');

      final records = await getAttendanceRecords(
        teacherId: teacherId,
        className: className,
        subjectId: subjectId,
        medium: medium,
        startDate: startDate,
        endDate: endDate,
      );

      // Calculate statistics
      final totalRecords = records.length;
      final presentCount =
          records.where((record) => record['status'] == 'present').length;
      final absentCount =
          records.where((record) => record['status'] == 'absent').length;
      final attendanceRate =
          totalRecords > 0 ? (presentCount / totalRecords) * 100 : 0;

      return {
        'totalRecords': totalRecords,
        'presentCount': presentCount,
        'absentCount': absentCount,
        'attendanceRate': attendanceRate.roundToDouble(),
        'dateRange': {
          'startDate': startDate,
          'endDate': endDate,
        },
      };
    } catch (e) {
      print('Error getting attendance statistics: $e');
      rethrow;
    }
  }

  // Export attendance records (placeholder for future implementation)
  static Future<String> exportAttendanceRecords({
    required int teacherId,
    required String className,
    required int subjectId,
    required String medium,
    required String startDate,
    required String endDate,
    String format = 'csv',
  }) async {
    try {
      print('Exporting attendance records...');

      // Get all records for the date range
      final records = await getAttendanceStatistics(
        teacherId: teacherId,
        className: className,
        subjectId: subjectId,
        medium: medium,
        startDate: startDate,
        endDate: endDate,
      );

      // TODO: Implement actual export functionality
      // This would typically generate a CSV or PDF file

      return 'Attendance records exported successfully';
    } catch (e) {
      print('Error exporting attendance records: $e');
      rethrow;
    }
  }
}
