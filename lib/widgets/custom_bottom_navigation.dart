import 'package:flutter/material.dart';
import 'dart:ui';
import '../core/themes/app_colors.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavigationItem> items;

  const CustomBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A4759), // dark blue-gray
            Color(0xFF1E3440), // darker blue-gray
            Color(0xFF152A35), // deepest blue-gray
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, -2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: BottomNavigationBar(
        items: List.generate(items.length, (index) {
          final item = items[index];
          final bool isActive = index == currentIndex;
          return BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.secondary.withOpacity(0.18)
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                color: isActive ? AppColors.primary : Colors.white70,
              ),
            ),
            label: item.label,
          );
        }),
        currentIndex: currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: Colors.transparent,
        elevation: 4,
        type: BottomNavigationBarType.fixed,
        onTap: onTap,
      ),
    );
  }
}

class BottomNavigationItem {
  final IconData icon;
  final String label;

  const BottomNavigationItem({
    required this.icon,
    required this.label,
  });
}

// Predefined navigation items for different sections
class NavigationItems {
  static List<BottomNavigationItem> get adminItems => [
        BottomNavigationItem(
          icon: Icons.people_outline,
          label: 'Students',
        ),
        BottomNavigationItem(
          icon: Icons.school_outlined,
          label: 'Teachers',
        ),
        BottomNavigationItem(
          icon: Icons.calendar_today_outlined,
          label: 'Attendance',
        ),
        BottomNavigationItem(
          icon: Icons.pie_chart_outline,
          label: 'Report',
        ),
      ];

  static List<BottomNavigationItem> get teacherItems => [
        BottomNavigationItem(
          icon: Icons.class_outlined,
          label: 'Classes',
        ),
        BottomNavigationItem(
          icon: Icons.people_outline,
          label: 'Students',
        ),
        BottomNavigationItem(
          icon: Icons.calendar_today_outlined,
          label: 'Attendance',
        ),
      ];

  static List<BottomNavigationItem> get studentItems => [
        BottomNavigationItem(
          icon: Icons.class_outlined,
          label: 'Classes',
        ),
        BottomNavigationItem(
          icon: Icons.assignment_outlined,
          label: 'Assignments',
        ),
        BottomNavigationItem(
          icon: Icons.calendar_today_outlined,
          label: 'Attendance',
        ),
      ];
}
