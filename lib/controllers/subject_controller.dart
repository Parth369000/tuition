import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/subject.dart';
import '../core/config/api_config.dart';

class SubjectController {
  Future<List<Subject>> getSubjects() async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/getData'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({"table": "Subject"}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch subjects: ${response.statusCode}');
      }

      final responseData = json.decode(response.body);

      if (responseData['errorStatus'] == false) {
        final List<dynamic> subjectsJson = responseData['data'] ?? [];
        return subjectsJson.map((json) => Subject.fromJson(json)).toList();
      } else {
        throw Exception(responseData['message'] ?? 'Failed to fetch subjects');
      }
    } on FormatException {
      throw Exception('Invalid response format from server');
    } on http.ClientException {
      throw Exception('Network error: Please check your connection');
    } catch (e) {
      throw Exception('Error fetching subjects: $e');
    }
  }
}
