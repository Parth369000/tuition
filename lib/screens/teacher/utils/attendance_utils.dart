import 'dart:convert';
import 'package:http/http.dart' as http;

class AttendanceUtils {
  static Future<List<dynamic>> fetchStudentsForAttendance({
    required int teacherId,
    required String selectedClass,
    required String subjectId,
    required String medium,
  }) async {
    try {
      // http://27.116.52.24:8076/

      final request = http.Request(
        'POST',
        Uri.parse('http://27.116.52.24:8076/getStudentsForTeacher'),
      );

      request.headers.addAll({
        'Content-Type': 'application/json',
      });

      request.body = json.encode({
        "teacherId": teacherId,
        "class": selectedClass,
        "subjectId": int.parse(subjectId),
        "medium": medium,
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print('Fetch students response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['errorStatus'] == false) {
          // Process the student list and remove batch field
          final students = (data['data'] as List).map((student) {
            final Map<String, dynamic> studentData =
                Map<String, dynamic>.from(student);
            studentData.remove('batch'); // Remove batch field
            return studentData;
          }).toList();
          return students;
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch students');
        }
      } else {
        throw Exception('Failed to fetch students: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error in fetchStudentsForAttendance: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> loadAttendance({
    required int teacherId,
    required String selectedClass,
    required String subjectId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final request = http.Request(
        'POST',
        Uri.parse('http://27.116.52.24:8076/getAttendance'),
      );

      request.headers.addAll({
        'Content-Type': 'application/json',
      });

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        "teacherId": teacherId,
        "class": selectedClass,
        "subjectId": int.parse(subjectId),
      };
      print(requestBody.toString());
      // Add optional date parameters if provided
      if (startDate != null) {
        requestBody["startDate"] = startDate;
      }
      if (endDate != null) {
        requestBody["endDate"] = endDate;
      }

      request.body = json.encode(requestBody);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print('Get attendance response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['errorStatus'] == true &&
            data['msg'] == 'No attendance records found') {
          return []; // Return empty list for no records
        }
        if (data['errorStatus'] == false) {
          return data['data'] ?? [];
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch attendance');
        }
      } else {
        throw Exception('Failed to fetch attendance: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error in loadAttendance: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> submitAttendance({
    required int teacherId,
    required String selectedClass,
    required String subjectId,
    required Map<int, bool> attendanceMap,
  }) async {
    try {
      final results = <Map<String, dynamic>>[];
      final errors = <String>[];
      final today = DateTime.now().toString().split(' ')[0];

      // Mark attendance for each student
      for (var entry in attendanceMap.entries) {
        try {
          final result = await markAttendance(
            teacherId: teacherId,
            studentId: entry.key,
            status: entry.value ? "present" : "absent",
            date: today,
            subjectId: int.parse(subjectId),
          );
          results.add(result['data']);
        } catch (e) {
          errors.add('Failed to mark attendance for student ${entry.key}: $e');
        }
      }

      return {
        'success': errors.isEmpty,
        'data': results,
        'errors': errors,
      };
    } catch (e) {
      print('Error in submitAttendance: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> markAllPresent({
    required int teacherId,
    required String selectedClass,
    required String date,
    required int subjectId,
    required String medium,
  }) async {
    try {
      final request = http.Request(
        'POST',
        Uri.parse('http://27.116.52.24:8076/markAllPresent'),
      );

      request.headers.addAll({
        'Content-Type': 'application/json',
      });

      request.body = json.encode({
        "teacherId": teacherId,
        "class": selectedClass,
        "date": date,
        "subjectId": subjectId,
        "medium": medium,
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print('Mark all present response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['errorStatus'] == false) {
          return {
            'success': true,
            'message': data['data']['message'],
            'markedCount': data['data']['markedCount'],
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to mark all present');
        }
      } else {
        throw Exception('Failed to mark all present: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error in markAllPresent: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> markAttendance({
    required int teacherId,
    required int studentId,
    required String status,
    required String date,
    required int subjectId,
  }) async {
    try {
      final request = http.Request(
        'POST',
        Uri.parse('http://27.116.52.24:8076/markAttendance'),
      );

      request.headers.addAll({
        'Content-Type': 'application/json',
      });

      request.body = json.encode({
        "teacherId": teacherId,
        "studentId": studentId,
        "date": date,
        "status": status,
        "subjectId": subjectId,
      });
      print(request.body.toString());
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print('Mark attendance response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['errorStatus'] == false) {
          return {
            'success': true,
            'data': data['data'],
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to mark attendance');
        }
      } else {
        throw Exception('Failed to mark attendance: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error in markAttendance: $e');
      rethrow;
    }
  }
}
