import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../models/teacher.dart';
import '../models/teacher_class.dart';
import 'package:get/get.dart';

class TeacherController extends GetxController {
  Future<List<Teacher>> getAllTeachers() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/getData'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"table": "Teacher"}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to load teachers: ${response.statusCode}');
      }

      final Map<String, dynamic> data = json.decode(response.body);
      if (data['errorStatus'] == false) {
        final List<dynamic> teachersData = data['data'] ?? [];
        final List<Teacher> teachers = teachersData
            .map((json) => Teacher.fromJson(json))
            .toList();

        for (var teacher in teachers) {
          teacher.classes = await getTeacherClasses(teacher.id);
        }

        return teachers;
      } else {
        throw Exception(data['message'] ?? 'Failed to load teachers');
      }
    } on FormatException {
      throw Exception('Invalid response format from server');
    } on http.ClientException {
      throw Exception('Network error: Please check your connection');
    } catch (e) {
      throw Exception('Error loading teachers: $e');
    }
  }

  Future<List<TeacherClass>> getTeacherClasses(int teacherId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/getClassesForTeacher'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"teacherId": teacherId}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to load teacher classes: ${response.statusCode}');
      }

      final Map<String, dynamic> data = json.decode(response.body);
      if (data['errorStatus'] == false) {
        final List<dynamic> classesData = data['data'] ?? [];
        return classesData.map((json) => TeacherClass.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load teacher classes');
      }
    } on FormatException {
      throw Exception('Invalid response format from server');
    } on http.ClientException {
      throw Exception('Network error: Please check your connection');
    } catch (e) {
      throw Exception('Error loading teacher classes: $e');
    }
  }

  Future<Teacher?> getTeacherById(int id) async {
    try {
      final teachers = await getAllTeachers();
      return teachers.firstWhere((teacher) => teacher.id == id);
    } catch (e) {
      throw Exception('Error getting teacher by ID: $e');
    }
  }

  Future<Teacher?> getTeacherByUserId(int userId) async {
    try {
      final teachers = await getAllTeachers();
      return teachers.firstWhere((teacher) => teacher.userid == userId);
    } catch (e) {
      throw Exception('Error getting teacher by user ID: $e');
    }
  }

  Future<List<Teacher>> searchTeachers(String query) async {
    try {
      final teachers = await getAllTeachers();
      final lowercaseQuery = query.toLowerCase();
      return teachers.where((teacher) {
        return teacher.fname.toLowerCase().contains(lowercaseQuery) ||
            teacher.lname.toLowerCase().contains(lowercaseQuery) ||
            teacher.contact.contains(query);
      }).toList();
    } catch (e) {
      throw Exception('Error searching teachers: $e');
    }
  }

  Future<List<TeacherClass>> getClassesForTeacher(int teacherId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/getTeacherClasses/$teacherId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['errorStatus'] == false) {
          final List<dynamic> classes = data['data'];
          return classes.map((c) => TeacherClass.fromJson(c)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load teacher classes');
        }
      } else {
        throw Exception('Failed to load teacher classes: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error loading teacher classes: $e');
    }
  }

  Future<Map<String, dynamic>> getAttendance({
    required int teacherId,
    required String classId,
    required int subjectId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/getAttendanceHistory'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'teacherId': teacherId,
          'class': classId,
          'subjectId': subjectId,
          'startDate': startDate.toIso8601String().split('T')[0],
          'endDate': endDate.toIso8601String().split('T')[0],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['errorStatus'] == false) {
          return {
            'status': 'success',
            'data': data['data'],
          };
        } else {
          return {
            'status': 'error',
            'message': data['message'] ?? 'Failed to load attendance history',
          };
        }
      } else {
        return {
          'status': 'error',
          'message': 'Failed to load attendance history: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Error loading attendance history: $e',
      };
    }
  }
}
