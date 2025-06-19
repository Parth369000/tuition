class ApiConfig {
  static const String baseUrl = 'http://27.116.52.24:8076';

  // Auth endpoints
  static const String login = '/login';

  // Teacher endpoints
  static const String getAllTeachers = '/getData';
  static const String addTeacher = '/addTeacher';
  static const String assignTeacher = '/assignTeachers';
  static const String getClassesForTeacher = '/getClassesForTeacher';
  static const String getStudentsForTeacher = '/getStudentsForTeacher';

  // Attendence endpoints
  static const String getAttendance = '/getAttendance';
  static const String markAttendance = '/markAttendance';
  static const String markAllPresent = '/markAllPresent';
  static const String getAttendanceForStudent = '/getAttendanceForStudent';

  // Test endpoints
  static const String getAvailableTests = '/getAvailableTests';
  static const String addTest = '/addTest';
  static const String getPastTests = '/getPastTests';

  // marks endpoints
  static const String addOrUpdateTestMarks = '/addOrUpdateTestMarks';
  static const String getStudentTestMarks = '/getStudentTestMarks';
  static const String getAllMarksForTest = '/getAllMarksForTest';


  // Student endpoints
  static const String getAllStudents = '/getAllStudents';
  static const String addStudent = '/addStudent';

  // static const String updateStudent = '/updateStudent';
  // static const String deleteStudent = '/deleteStudent';

  // Admin endpoints
  // static const String getDashboardStats = '/getDashboardStats';
  // static const String getAttendanceStats = '/getAttendanceStats';

  // Material endpoints
  static const String uploadFileMaterial = '/material/upload';
  static const String getMaterials = '/material/getMaterials';
  static const String uploadVideoMaterial = '/material/shareVideo';

  // Error messages
  static const String networkError =
      'Network error. Please check your connection.';
  static const String timeoutError = 'Request timed out. Please try again.';
  static const String serverError = 'Server error. Please try again later.';

  // Helper methods
  static String getUrl(String endpoint) => '$baseUrl$endpoint';

  static Map<String, String> getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory ApiResponse.success(T data) {
    return ApiResponse(
      success: true,
      data: data,
    );
  }

  factory ApiResponse.error(String error) {
    return ApiResponse(
      success: false,
      error: error,
    );
  }
}
