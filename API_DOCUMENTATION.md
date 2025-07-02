# Tuition Management System - API Documentation

A comprehensive Flutter application for managing tuition classes, students, teachers, and study materials with role-based access control.

## Table of Contents

1. [Project Overview](#project-overview)
2. [Core Architecture](#core-architecture)
3. [API Configuration](#api-configuration)
4. [Core Services](#core-services)
5. [Data Models](#data-models)
6. [Controllers (State Management)](#controllers-state-management)
7. [UI Components & Widgets](#ui-components--widgets)
8. [Screens & Navigation](#screens--navigation)
9. [Themes & Styling](#themes--styling)
10. [Utilities](#utilities)
11. [Usage Examples](#usage-examples)
12. [Installation & Setup](#installation--setup)

---

## Project Overview

### Application Structure
```
lib/
├── core/                 # Core configurations and utilities
├── controllers/          # State management controllers
├── models/              # Data models
├── screens/             # UI screens (role-based)
├── services/            # API services
├── widgets/             # Reusable UI components
└── main.dart           # Application entry point
```

### Key Features
- **Multi-role Authentication**: Admin, Teacher, Student access levels
- **Student Management**: Registration, attendance, test management
- **Teacher Management**: Class assignment, material upload, attendance marking
- **Material Management**: PDF and video content support
- **Analytics Dashboard**: Comprehensive reporting system

---

## Core Architecture

### Main Application Entry Point

#### `MyApp` Class
**File**: `lib/main.dart`

```dart
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context)
}
```

**Purpose**: Root application widget with theme and navigation configuration.

**Features**:
- Light/Dark theme support
- System theme mode detection
- Navigation to SplashScreen

**Usage**:
```dart
void main() {
  runApp(const MyApp());
}
```

---

## API Configuration

### `ApiConfig` Class
**File**: `lib/core/config/api_config.dart`

#### Static Properties

| Property | Type | Description |
|----------|------|-------------|
| `baseUrl` | `String` | Base API endpoint URL |
| `login` | `String` | Authentication endpoint |
| `getAllTeachers` | `String` | Fetch all teachers endpoint |
| `addTeacher` | `String` | Add new teacher endpoint |
| `assignTeacher` | `String` | Assign teacher to class endpoint |
| `getAttendance` | `String` | Fetch attendance records endpoint |
| `markAttendance` | `String` | Mark student attendance endpoint |
| `getAllStudents` | `String` | Fetch all students endpoint |
| `addStudent` | `String` | Add new student endpoint |
| `uploadFileMaterial` | `String` | Upload file materials endpoint |
| `getMaterials` | `String` | Fetch study materials endpoint |

#### Methods

##### `getUrl(String endpoint)`
Returns complete URL by combining base URL with endpoint.

**Parameters**:
- `endpoint`: API endpoint path

**Returns**: Complete URL string

**Example**:
```dart
String loginUrl = ApiConfig.getUrl(ApiConfig.login);
// Returns: "http://27.116.52.24:8076/login"
```

##### `getHeaders({String? token})`
Generates HTTP headers for API requests.

**Parameters**:
- `token` (optional): Authentication token

**Returns**: Map of HTTP headers

**Example**:
```dart
Map<String, String> headers = ApiConfig.getHeaders(token: "your_token");
```

### `ApiResponse<T>` Class
Generic response wrapper for API calls.

#### Properties
- `success`: Boolean indicating request success
- `data`: Response data (generic type T)
- `error`: Error message if request failed

#### Factory Constructors

##### `ApiResponse.success(T data)`
Creates successful response wrapper.

##### `ApiResponse.error(String error)`
Creates error response wrapper.

**Example**:
```dart
ApiResponse<List<Student>> response = ApiResponse.success(studentList);
if (response.success) {
  List<Student> students = response.data!;
}
```

---

## Core Services

### `ApiService` Class
**File**: `lib/core/services/api_service.dart`

Singleton HTTP client service for API communication.

#### Methods

##### `post<T>(String endpoint, {Map<String, String>? headers, Map<String, dynamic>? body, T Function(Map<String, dynamic>)? fromJson})`

Performs HTTP POST request with JSON parsing.

**Parameters**:
- `endpoint`: API endpoint path
- `headers` (optional): Custom HTTP headers
- `body` (optional): Request body data
- `fromJson` (optional): JSON parsing function

**Returns**: `Future<ApiResponse<T>>`

**Example**:
```dart
ApiService apiService = ApiService();
ApiResponse<Student> response = await apiService.post<Student>(
  ApiConfig.addStudent,
  body: studentData,
  fromJson: (json) => Student.fromJson(json),
);
```

### `StudentService` Class
**File**: `lib/services/student_service.dart`

Service class for student-related API operations.

#### Methods

##### `getAllStudents()`
Fetches all students from the server.

**Returns**: `Future<List<Student>>`

**Throws**: Exception on network or parsing errors

**Example**:
```dart
StudentService service = StudentService();
try {
  List<Student> students = await service.getAllStudents();
} catch (e) {
  print('Error: $e');
}
```

##### `addStudent({required String studentClass, required String batch, ...})`
Adds a new student with multipart form data support.

**Parameters**:
- `studentClass`: Student's class/grade
- `batch`: Batch name
- `feePaid`: Amount of fees paid
- `feeTotal`: Total fees amount
- `bdate`: Birth date
- `address`: Student address
- `board`: Education board
- `school`: School name
- `fname`, `mname`, `lname`: Student names
- `medium`: Language medium
- `contact`: Student contact
- `parentContact`: Parent contact
- `image` (optional): Profile image file

**Returns**: `Future<bool>`

**Example**:
```dart
bool success = await service.addStudent(
  studentClass: "10",
  batch: "Morning",
  fname: "John",
  lname: "Doe",
  // ... other required fields
);
```

---

## Data Models

### `Student` Class
**File**: `lib/models/student.dart`

Represents a student entity with complete profile information.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `int` | Unique student identifier |
| `name` | `String` | Full name |
| `userid` | `String` | Login username |
| `password` | `String` | Login password |
| `studentClass` | `String` | Class/Grade |
| `batch` | `String` | Batch name |
| `fname` | `String` | First name |
| `mname` | `String` | Middle name |
| `lname` | `String` | Last name |
| `contact` | `String` | Contact number |
| `parentContact` | `String` | Parent contact |
| `school` | `String` | School name |
| `board` | `String` | Education board |
| `medium` | `String` | Language medium |
| `address` | `String` | Address |
| `bdate` | `String` | Birth date |
| `feePaid` | `String` | Fees paid |
| `feeTotal` | `String` | Total fees |
| `image` | `String?` | Profile image URL |

#### Methods

##### `Student.fromJson(Map<String, dynamic> json)`
Factory constructor for JSON deserialization.

##### `toJson()`
Converts student object to JSON map.

**Example**:
```dart
// From JSON
Student student = Student.fromJson(jsonData);

// To JSON
Map<String, dynamic> json = student.toJson();
```

### `Teacher` Class
**File**: `lib/models/teacher.dart`

Represents a teacher entity.

#### Properties
- `id`: Unique teacher identifier
- `fname`: First name
- `mname`: Middle name (optional)
- `lname`: Last name
- `contact`: Contact number
- `userid`: User ID (optional)
- `createdAt`: Creation timestamp
- `updatedAt`: Last update timestamp
- `classes`: Associated classes (optional)

#### Computed Properties

##### `fullName`
Returns formatted full name.

**Example**:
```dart
Teacher teacher = Teacher.fromJson(jsonData);
String name = teacher.fullName; // "John Doe"
```

### `Subject` Class
**File**: `lib/models/subject.dart`

Represents an academic subject.

#### Properties
- `id`: Unique subject identifier
- `name`: Subject name
- `createdAt`: Creation timestamp
- `updatedAt`: Last update timestamp

### `Attendance` Class
**File**: `lib/models/attendance.dart`

Represents attendance record with nested student information.

#### Properties
- `id`: Attendance record ID
- `date`: Attendance date
- `status`: Attendance status
- `student`: Associated student object

**Example**:
```dart
Attendance record = Attendance.fromJson(jsonData);
String studentName = record.student.fullName;
```

---

## Controllers (State Management)

### `StudentController` Class
**File**: `lib/controllers/student_controller.dart`

Manages student-related state and operations using ChangeNotifier pattern.

#### Properties

##### State Properties
- `isLoading`: Loading state indicator
- `studentImage`: Selected student image file
- `currentStep`: Current form step (0-2)
- `error`: Error message
- `students`: List of all students
- `groupedStudents`: Students grouped by class and batch

##### Form Controllers
- `studentClassController`: Class input controller
- `batchController`: Batch input controller
- `feePaidController`: Fee paid input controller
- `feeTotalController`: Total fee input controller
- `birthdateController`: Birth date input controller
- `addressController`: Address input controller
- `boardController`: Board input controller
- `schoolController`: School input controller
- `fnameController`: First name input controller
- `mnameController`: Middle name input controller
- `lnameController`: Last name input controller
- `mediumController`: Medium input controller
- `contactController`: Contact input controller
- `parentContactController`: Parent contact input controller

##### Subject Selection
- `selectedSubjects`: List of selected subject IDs

#### Methods

##### `setImage(File? image)`
Sets the student profile image.

**Parameters**:
- `image`: Image file or null to clear

##### `nextStep()` / `previousStep()`
Navigate between form steps.

##### `submitForm()`
Submits the complete student form with validation.

**Process**:
1. Validates subject selection
2. Creates request body
3. Sends POST request to API
4. Handles success/error responses
5. Navigates to admin home on success

**Example**:
```dart
StudentController controller = StudentController();
controller.selectedSubjects.addAll([1, 2, 3]);
await controller.submitForm();
```

##### `fetchStudents()`
Fetches all students and groups them by class and batch.

##### `resetForm()`
Clears all form fields and resets state.

##### `showSnackBar(String message, {bool isError = false})`
Displays user feedback messages.

**Example Usage**:
```dart
class StudentFormScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StudentController(),
      child: Consumer<StudentController>(
        builder: (context, controller, child) {
          return Scaffold(
            body: controller.isLoading 
              ? CircularProgressIndicator()
              : YourFormWidget(),
          );
        },
      ),
    );
  }
}
```

---

## UI Components & Widgets

### `CustomBottomNavigation` Class
**File**: `lib/widgets/custom_bottom_navigation.dart`

A glassmorphic bottom navigation bar with role-based navigation items.

#### Properties
- `currentIndex`: Currently selected tab index
- `onTap`: Callback for tab selection
- `items`: List of navigation items

#### Features
- Glassmorphic design with backdrop blur
- Gradient background
- Customizable navigation items
- Glass-style borders and effects

**Example**:
```dart
CustomBottomNavigation(
  currentIndex: _selectedIndex,
  onTap: (index) => setState(() => _selectedIndex = index),
  items: NavigationItems.adminItems,
)
```

### `BottomNavigationItem` Class
Represents a single navigation item.

#### Properties
- `icon`: IconData for the item
- `label`: Display label

### `NavigationItems` Class
Provides predefined navigation items for different user roles.

#### Static Methods

##### `adminItems`
Returns navigation items for admin users.
- Students
- Teachers
- Attendance

##### `teacherItems`
Returns navigation items for teachers.
- Classes
- Students
- Attendance

##### `studentItems`
Returns navigation items for students.
- Classes
- Assignments
- Attendance

**Example**:
```dart
List<BottomNavigationItem> items = NavigationItems.teacherItems;
```

### `LiquidGlassPainter` Class
**File**: `lib/widgets/liquid_glass_painter.dart`

Custom painter for creating liquid glass visual effects.

#### Methods
##### `paint(Canvas canvas, Size size)`
Renders the liquid glass effect on the provided canvas.

##### `shouldRepaint(CustomPainter oldDelegate)`
Determines if repainting is necessary.

---

## Screens & Navigation

### Authentication Screens

#### `SplashScreen`
**File**: `lib/screens/splash_screen.dart`
- Initial loading screen
- App initialization
- Auto-navigation to login

#### `LoginScreen`
**File**: `lib/screens/login_screen.dart`
- User authentication
- Role-based login
- Input validation

### Admin Screens

#### `AdminHomeScreen`
**File**: `lib/screens/admin/admin_home_screen.dart`
- Student management dashboard
- Teacher assignment interface
- System analytics

#### `ClassStudentListScreen`
**File**: `lib/screens/admin/class_student_list_screen.dart`
- Class-wise student listing
- Student detail management
- Batch organization

### Teacher Screens

#### `TeacherHomeScreen`
**File**: `lib/screens/teacher/teacher_home_screen.dart`
- Teacher dashboard
- Class overview
- Quick actions

#### `TeacherDashboard`
**File**: `lib/screens/teacher/teacher_dashboard.dart`
- Analytics and statistics
- Performance metrics
- Class insights

#### `ClassDetailsScreen`
**File**: `lib/screens/teacher/class_details_screen.dart`
- Detailed class information
- Student management
- Material sharing

#### `TeacherProfileScreen`
**File**: `lib/screens/teacher/teacher_profile_screen.dart`
- Teacher profile management
- Personal information editing
- Settings

### Student Screens

#### `StudentHomeScreen`
**File**: `lib/screens/student/student_home_screen.dart`
- Student dashboard
- Available materials
- Upcoming classes

#### `StudentProfileScreen`
**File**: `lib/screens/student/student_profile_screen.dart`
- Student profile information
- Academic details
- Progress tracking

### Media Viewer Screens

#### `PDFViewerScreen`
**File**: `lib/screens/student/pdf_viewer_screen.dart` & `lib/screens/teacher/pdf_viewer_screen.dart`
- PDF document viewing
- Study material access
- Download functionality

#### `VideoPlayerScreen`
**File**: `lib/screens/student/video_player_screen.dart`
- Video content playback
- Educational content access

#### `YoutubePlayerScreen`
**File**: `lib/screens/teacher/youtube_player_screen.dart`
- YouTube video integration
- Educational video sharing

---

## Themes & Styling

### `AppTheme` Class
**File**: `lib/core/themes/app_theme.dart`

Provides consistent theming across the application.

#### Static Properties
- `lightTheme`: Light theme configuration
- `darkTheme`: Dark theme configuration

### `AppColors` Class
**File**: `lib/core/themes/app_colors.dart`

Centralized color definitions for consistent UI.

#### Color Properties
- `primaryGradient`: Primary gradient colors
- `glassBackground`: Glass effect background
- `glassBorder`: Glass effect border color

**Example**:
```dart
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system,
)
```

---

## Utilities

### `AppConstants` Class
**File**: `lib/core/constants/app_constants.dart`

Application-wide constants and configuration values.

#### Categories

##### API Configuration
- `apiTimeout`: Request timeout duration (30 seconds)

##### Storage Keys
- `tokenKey`: Authentication token storage key
- `userKey`: User data storage key
- `themeKey`: Theme preference storage key

##### Validation Rules
- `minPasswordLength`: Minimum password length (6)
- `maxPasswordLength`: Maximum password length (20)
- `minPhoneLength`: Minimum phone number length (10)
- `maxPhoneLength`: Maximum phone number length (15)

##### File Upload Limits
- `maxFileSize`: Maximum file size (10MB)
- `allowedImageTypes`: Supported image formats
- `allowedDocumentTypes`: Supported document formats

##### Messages
- Error messages for common scenarios
- Success messages for operations
- User feedback messages

**Example**:
```dart
// Validation
if (password.length < AppConstants.minPasswordLength) {
  showError(AppConstants.invalidCredentials);
}

// File validation
if (file.lengthSync() > AppConstants.maxFileSize) {
  showError(AppConstants.fileTooLarge);
}
```

### `AppUtils` Class
**File**: `lib/core/utils/app_utils.dart`

Utility functions for common operations.

---

## Usage Examples

### Complete Student Registration Flow

```dart
class StudentRegistrationExample extends StatefulWidget {
  @override
  _StudentRegistrationExampleState createState() => _StudentRegistrationExampleState();
}

class _StudentRegistrationExampleState extends State<StudentRegistrationExample> {
  late StudentController _controller;

  @override
  void initState() {
    super.initState();
    _controller = StudentController();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<StudentController>(
        builder: (context, controller, child) {
          return Scaffold(
            appBar: AppBar(title: Text('Student Registration')),
            body: Stepper(
              currentStep: controller.currentStep,
              onStepTapped: (step) {
                // Navigate to specific step
              },
              steps: [
                // Step 1: Personal Information
                Step(
                  title: Text('Personal Info'),
                  content: Column(
                    children: [
                      TextFormField(
                        controller: controller.fnameController,
                        decoration: InputDecoration(labelText: 'First Name'),
                      ),
                      TextFormField(
                        controller: controller.lnameController,
                        decoration: InputDecoration(labelText: 'Last Name'),
                      ),
                      // ... other fields
                    ],
                  ),
                ),
                
                // Step 2: Academic Information
                Step(
                  title: Text('Academic Info'),
                  content: Column(
                    children: [
                      TextFormField(
                        controller: controller.studentClassController,
                        decoration: InputDecoration(labelText: 'Class'),
                      ),
                      // ... subject selection widget
                    ],
                  ),
                ),
                
                // Step 3: Contact & Fee Information
                Step(
                  title: Text('Contact & Fees'),
                  content: Column(
                    children: [
                      TextFormField(
                        controller: controller.contactController,
                        decoration: InputDecoration(labelText: 'Contact'),
                      ),
                      TextFormField(
                        controller: controller.feeTotalController,
                        decoration: InputDecoration(labelText: 'Total Fees'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: controller.isLoading ? null : () async {
                if (controller.currentStep == 2) {
                  await controller.submitForm();
                } else {
                  controller.nextStep();
                }
              },
              child: controller.isLoading 
                ? CircularProgressIndicator()
                : Icon(Icons.navigate_next),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### API Service Usage

```dart
class ApiUsageExample {
  final ApiService _apiService = ApiService();
  
  Future<void> fetchAndDisplayStudents() async {
    try {
      // Using the generic API service
      ApiResponse<List<Student>> response = await _apiService.post<List<Student>>(
        ApiConfig.getAllStudents,
        fromJson: (json) => (json['data'] as List)
            .map((item) => Student.fromJson(item))
            .toList(),
      );
      
      if (response.success) {
        List<Student> students = response.data!;
        print('Fetched ${students.length} students');
      } else {
        print('Error: ${response.error}');
      }
    } catch (e) {
      print('Exception: $e');
    }
  }
  
  Future<void> addNewStudent() async {
    try {
      // Using specific student service
      StudentService studentService = StudentService();
      
      bool success = await studentService.addStudent(
        studentClass: "10",
        batch: "Morning",
        feePaid: "5000",
        feeTotal: "10000",
        bdate: "2005-01-15",
        address: "123 Main St",
        board: "CBSE",
        school: "ABC School",
        fname: "John",
        mname: "M",
        lname: "Doe",
        medium: "English",
        contact: "9876543210",
        parentContact: "9876543211",
      );
      
      if (success) {
        print('Student added successfully');
      }
    } catch (e) {
      print('Failed to add student: $e');
    }
  }
}
```

### Custom Navigation Implementation

```dart
class MainNavigationExample extends StatefulWidget {
  @override
  _MainNavigationExampleState createState() => _MainNavigationExampleState();
}

class _MainNavigationExampleState extends State<MainNavigationExample> {
  int _selectedIndex = 0;
  String userRole = 'admin'; // This would come from authentication
  
  List<Widget> get _screens {
    switch (userRole) {
      case 'admin':
        return [AdminHomeScreen(), TeacherManagementScreen(), AttendanceScreen()];
      case 'teacher':
        return [TeacherHomeScreen(), ClassDetailsScreen(), AttendanceScreen()];
      case 'student':
        return [StudentHomeScreen(), AssignmentScreen(), AttendanceScreen()];
      default:
        return [AdminHomeScreen()];
    }
  }
  
  List<BottomNavigationItem> get _navigationItems {
    switch (userRole) {
      case 'admin':
        return NavigationItems.adminItems;
      case 'teacher':
        return NavigationItems.teacherItems;
      case 'student':
        return NavigationItems.studentItems;
      default:
        return NavigationItems.adminItems;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: _navigationItems,
      ),
    );
  }
}
```

---

## Installation & Setup

### Prerequisites
- Flutter SDK 3.2.3 or higher
- Dart SDK (compatible version)
- Android Studio / VS Code
- Git

### Dependencies

#### Core Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
  http: ^1.4.0
  get: ^4.7.2
  path: ^1.8.3
  path_provider: ^2.1.2
```

#### UI & Media Dependencies
```yaml
  google_fonts: ^6.2.1
  flutter_svg: ^2.1.0
  table_calendar: ^3.1.3
  liquid_glass_renderer: ^0.1.1-dev.6
  flutter_pdfview: ^1.4.0+1
  youtube_player_flutter: ^9.1.1
  webview_flutter: ^4.13.0
```

#### Form & File Handling
```yaml
  flutter_form_builder: ^10.0.1
  form_builder_validators: ^11.1.2
  file_picker: ^10.1.9
  image_picker: ^1.1.2
  permission_handler: ^12.0.0+1
  url_launcher: ^6.3.1
  app_settings: ^6.1.1
```

### Installation Steps

1. **Clone the repository**
```bash
git clone <repository-url>
cd tuition
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure API endpoint**
Update `lib/core/config/api_config.dart`:
```dart
static const String baseUrl = 'YOUR_API_ENDPOINT';
```

4. **Run the application**
```bash
flutter run
```

### Environment Configuration

#### Development Environment
```dart
// lib/core/config/api_config.dart
static const String baseUrl = 'http://localhost:8076';
```

#### Production Environment
```dart
// lib/core/config/api_config.dart
static const String baseUrl = 'https://your-production-api.com';
```

### Build Commands

#### Android Release Build
```bash
flutter build apk --release
```

#### iOS Release Build
```bash
flutter build ios --release
```

#### Web Build
```bash
flutter build web
```

---

## Error Handling

### Common Error Scenarios

#### Network Errors
```dart
try {
  ApiResponse response = await apiService.post(endpoint);
} catch (e) {
  if (e is SocketException) {
    // Handle network connectivity issues
    showError(AppConstants.networkError);
  } else if (e is TimeoutException) {
    // Handle request timeouts
    showError(AppConstants.timeoutError);
  }
}
```

#### Validation Errors
```dart
// Form validation example
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }
  if (value.length < AppConstants.minPasswordLength) {
    return 'Password too short';
  }
  return null;
}
```

#### File Upload Errors
```dart
Future<void> uploadFile(File file) async {
  // Check file size
  if (file.lengthSync() > AppConstants.maxFileSize) {
    throw Exception(AppConstants.fileTooLarge);
  }
  
  // Check file type
  String extension = file.path.split('.').last.toLowerCase();
  if (!AppConstants.allowedImageTypes.contains('image/$extension')) {
    throw Exception(AppConstants.invalidFileType);
  }
}
```

---

## Testing

### Unit Testing Example
```dart
// test/models/student_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tuition/models/student.dart';

void main() {
  group('Student Model Tests', () {
    test('should create student from JSON', () {
      final json = {
        'id': 1,
        'name': 'John Doe',
        'class': '10',
        // ... other fields
      };
      
      final student = Student.fromJson(json);
      
      expect(student.id, 1);
      expect(student.name, 'John Doe');
      expect(student.studentClass, '10');
    });
    
    test('should convert student to JSON', () {
      final student = Student(
        id: 1,
        name: 'John Doe',
        studentClass: '10',
        // ... other required fields
      );
      
      final json = student.toJson();
      
      expect(json['id'], 1);
      expect(json['name'], 'John Doe');
      expect(json['class'], '10');
    });
  });
}
```

### Widget Testing Example
```dart
// test/widgets/custom_bottom_navigation_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuition/widgets/custom_bottom_navigation.dart';

void main() {
  testWidgets('CustomBottomNavigation displays items correctly', (WidgetTester tester) async {
    int selectedIndex = 0;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: CustomBottomNavigation(
            currentIndex: selectedIndex,
            onTap: (index) => selectedIndex = index,
            items: NavigationItems.adminItems,
          ),
        ),
      ),
    );
    
    expect(find.text('Students'), findsOneWidget);
    expect(find.text('Teachers'), findsOneWidget);
    expect(find.text('Attendance'), findsOneWidget);
  });
}
```

---

## Contributing

### Code Style Guidelines
- Follow Dart/Flutter style guide
- Use meaningful variable and function names
- Add documentation comments for public APIs
- Implement proper error handling
- Write unit tests for new features

### Pull Request Process
1. Fork the repository
2. Create feature branch
3. Implement changes with tests
4. Update documentation
5. Submit pull request

---

## License

This project is licensed under the MIT License. See LICENSE file for details.

---

## Support

For technical support or questions:
- Create an issue in the repository
- Review existing documentation
- Check Flutter/Dart official documentation

---

*Last updated: December 2024*