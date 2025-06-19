# Tuition Management System

A modern Flutter application for managing tuition classes, students, teachers, and study materials.
Enables role-based access for admins, teachers, and students with features like attendance, material sharing, and analytics.
Designed for scalability, intuitive UI, and efficient class management in educational institutions.

---

## Project Structure

```
lib/
│
├── core/                     # Core configurations and utilities
│   ├── config/               # API and app config (api_config.dart)
│   ├── constants/            # App-wide constants (app_constants.dart)
│   ├── services/             # Core services (api_service.dart)
│   ├── themes/               # App themes and color definitions
│   └── utils/                # Utility functions (app_utils.dart)
│
├── controllers/              # State management controllers
│   ├── student_controller.dart
│   ├── subject_controller.dart
│   └── teacher_controller.dart
│
├── models/                   # Data models
│   ├── attendance.dart
│   ├── student.dart
│   ├── subject.dart
│   ├── teacher.dart
│   ├── teacher_class.dart
│   └── teacher_subject.dart
│
├── screens/                  # UI screens, grouped by role
│   ├── admin/
│   │   ├── admin_home_screen.dart
│   │   ├── class_student_list_screen.dart
│   │   └── widgets/          # Admin-specific widgets
│   ├── student/
│   │   ├── student_home_screen.dart
│   │   ├── student_profile_screen.dart
│   │   ├── pdf_viewer_screen.dart
│   │   └── video_player_screen.dart
│   ├── teacher/
│   │   ├── teacher_home_screen.dart
│   │   ├── teacher_profile_screen.dart
│   │   ├── teacher_dashboard.dart
│   │   ├── class_details_screen.dart
│   │   ├── pdf_viewer_screen.dart
│   │   ├── youtube_player_screen.dart
│   │   ├── utils/            # Teacher-specific utilities
│   │   └── widgets/          # Teacher-specific widgets
│   ├── login_screen.dart
│   └── splash_screen.dart
│
├── services/                 # App services (student_service.dart)
│
├── widgets/                  # Reusable widgets
│   ├── custom_bottom_navigation.dart
│   ├── liquid_glass_painter.dart
│   └── materials/
│       └── materials_section.dart
│
└── main.dart                 # App entry point
```

---

## Features

- **Authentication**
  - Login/Logout
  - Role-based access (Admin, Teacher, Student)
- **Student Management**
  - Registration, attendance, test management, material access
- **Teacher Management**
  - Registration, class assignment, material upload, attendance marking
- **Admin Dashboard**
  - User management, class management, analytics, and reports
- **Material Management**
  - PDF and video support for study materials

---

## Getting Started

### Prerequisites

- Flutter SDK (latest stable)
- Dart SDK (latest stable)
- Android Studio or VS Code
- Git

### Installation

```bash
# Clone the repository
git clone https://github.com/Parth369000/tuition.git

# Navigate to the project directory
cd tuition

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## Dependencies

- **State Management:** Provider
- **HTTP Client:** http
- **Local Storage:** shared_preferences
- **File Handling:** file_picker
- **PDF Viewing:** flutter_pdfview
- **Image Handling:** image_picker
- **Date/Time:** intl
- **UI Components:** flutter_svg, cached_network_image

---

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- Flutter team for the amazing framework
- All contributors who have helped shape this project
