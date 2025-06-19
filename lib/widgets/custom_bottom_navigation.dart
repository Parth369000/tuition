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
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.primaryGradient,
            ),
            border: Border(
              top: BorderSide(
                color: AppColors.glassBorder,
                width: 1,
              ),
            ),
          ),
          child: BottomNavigationBar(
            items: items
                .map((item) => BottomNavigationBarItem(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.glassBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.glassBorder,
                            width: 1,
                          ),
                        ),
                        child: Icon(item.icon),
                      ),
                      label: item.label,
                    ))
                .toList(),
            currentIndex: currentIndex,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white.withOpacity(0.5),
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            onTap: onTap,
          ),
        ),
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
