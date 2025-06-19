class AppConstants {
  // API Timeouts
  static const int apiTimeout = 30; // seconds

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'app_theme';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 20;
  static const int minPhoneLength = 10;
  static const int maxPhoneLength = 15;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
  ];
  static const List<String> allowedDocumentTypes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  ];

  // Error Messages
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'Please check your internet connection.';
  static const String sessionExpired =
      'Your session has expired. Please login again.';
  static const String invalidCredentials = 'Invalid phone number or password.';
  static const String fileTooLarge = 'File size should be less than 10MB.';
  static const String invalidFileType =
      'Invalid file type. Please select a valid file.';

  // Success Messages
  static const String loginSuccess = 'Login successful.';
  static const String logoutSuccess = 'Logged out successfully.';
  static const String updateSuccess = 'Updated successfully.';
  static const String deleteSuccess = 'Deleted successfully.';
  static const String uploadSuccess = 'Uploaded successfully.';

  // App Info
  static const String appName = 'Tuition Management';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'A comprehensive tuition management system';
}
