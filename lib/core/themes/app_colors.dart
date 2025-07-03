import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (Using user's color palette)
  static const Color primary = Color(0xFFF79B72); // Orange/Coral
  static const Color primaryDark = Color(0xFF2A4759); // Dark Blue-Gray
  static const Color primaryLight = Color(0xFFFFB088); // Lighter orange

  // Secondary Colors
  static const Color secondary = Color(0xFF2A4759); // Dark Blue-Gray
  static const Color secondaryDark = Color(0xFF1E3440); // Darker Blue-Gray
  static const Color secondaryLight = Color(0xFF3A5A6B); // Lighter Blue-Gray

  // Background Colors
  static const Color scaffoldBackground = Color(0xFFEEEEEE); // Very Light Gray
  static const Color surface = Color(0xFFEEEEEE); // Very Light Gray
  static const Color cardBackground = Color(0xFFDDDDDD); // Light Gray
  static const Color background = Color(0xFFEEEEEE); // Very Light Gray

  // Navigation Colors
  static const Color navBackground = Color(0xFFDDDDDD); // Light Gray
  static const Color navSelected = Color(0xFFF79B72); // Orange/Coral
  static const Color navUnselected = Color(0xFF2A4759); // Dark Blue-Gray

  // Text Colors
  static const Color textPrimary = Color(0xFF2A4759); // Dark Blue-Gray
  static const Color textSecondary = Color(0xFF5A6B7C); // Medium Gray

  // Icon Colors
  static const Color iconPrimary = Color(0xFFF79B72); // Orange/Coral
  static const Color iconSecondary = Color(0xFF2A4759); // Dark Blue-Gray

  // Glass Effect Colors
  static const Color glassBackground = Color(0x1AF79B72); // Semi-transparent orange
  static const Color glassBorder = Color(0x33F79B72); // Semi-transparent orange border

  // Shadow Colors
  static const Color cardShadow = Color(0x1A2A4759); // Semi-transparent dark shadow

  // Status Colors
  static const Color error = Color(0xFFE57373); // Light red
  static const Color success = Color(0xFF81C784); // Light green
  static const Color warning = Color(0xFFFFB74D); // Light orange
  static const Color info = Color(0xFF64B5F6); // Light blue

  // Attendance Colors
  static const Color present = Color(0xFF81C784); // Light green
  static const Color absent = Color(0xFFE57373); // Light red

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFFF79B72), // Orange/Coral
    Color(0xFF2A4759), // Dark Blue-Gray
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFF2A4759), // Dark Blue-Gray
    Color(0xFF1E3440), // Darker Blue-Gray
  ];

  // Additional color combinations
  static const List<Color> warmGradient = [
    Color(0xFFF79B72), // Orange/Coral
    Color(0xFFFFB088), // Lighter orange
  ];

  static const List<Color> coolGradient = [
    Color(0xFF2A4759), // Dark Blue-Gray
    Color(0xFF3A5A6B), // Lighter Blue-Gray
  ];

  // Glass effect gradients
  static const List<Color> glassGradient = [
    Color(0x15F79B72), // Very transparent orange
    Color(0x05F79B72), // Almost transparent orange
  ];

  // Card and surface colors
  static const Color cardSurface = Color(0xFFDDDDDD); // Light Gray
  static const Color elevatedSurface = Color(0xFFF5F5F5); // Slightly lighter than DDDDDD
}
