// TeachersTabWidget.dart
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../controllers/teacher_controller.dart';
import '../../../models/teacher.dart';
import '../../../widgets/custom_bottom_navigation.dart';
import '../../../core/themes/app_colors.dart';
import 'teacher_form.dart';

class TeachersTabWidget extends StatefulWidget {
  const TeachersTabWidget({Key? key}) : super(key: key);

  @override
  State<TeachersTabWidget> createState() => _TeachersTabWidgetState();
}

class _TeachersTabWidgetState extends State<TeachersTabWidget> {
  List<dynamic> _teachers = [];
  String? _error;
  int _selectedIndex = 1; // Teachers is at index 1 in adminItems

  Future<void> _loadTeachers() async {
    try {
      final response = await http.post(
          Uri.parse('http://27.116.52.24:8076/getData'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({"table": "Teacher"}));

      if (response.statusCode == 200) {
        // Check if response is JSON
        if (response.headers['content-type']?.contains('application/json') ??
            false) {
          final data = json.decode(response.body);
          setState(() {
            _teachers = (data['data'] ?? []);
            print(_teachers.toList());
            if (_teachers.isEmpty) {
              _error = 'No Teacher Available';
            } else {
              _error = null;
            }
          });
        } else {
          print(
              'Invalid response format: Expected JSON but got ${response.headers['content-type']}');
          setState(() {
            _teachers = [];
          });
        }
      } else {
        print(
            'Failed to load teachers: ${response.statusCode} ${response.reasonPhrase}');
        setState(() {
          _teachers = [];
        });
      }
    } catch (e) {
      print('Error loading teachers: $e');
      setState(() {
        _teachers = [];
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.scaffoldBackground,
      child: RefreshIndicator(
        color: AppColors.primaryLight,
        backgroundColor: AppColors.scaffoldBackground,
        onRefresh: () async {
          await _loadTeachers();
          setState(() {});
        },
        child: FutureBuilder<List<Teacher>>(
          future: TeacherController().getAllTeachers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                color: AppColors.scaffoldBackground,
                // decoration: const BoxDecoration(
                //   gradient: LinearGradient(
                //     begin: Alignment.topLeft,
                //     end: Alignment.bottomRight,
                //     colors: [
                //       Color(0xFF328ECC),
                //       Color(0xFF1A4B7C),
                //     ],
                //   ),
                // ),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                  ),
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            final teachers = snapshot.data ?? [];
            if (teachers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.glassBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.glassBorder,
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.school_outlined,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No teachers found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.people,
                          color: AppColors.primaryDark, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Total Teachers: ',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        teachers.length.toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primary),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add,
                                  color: AppColors.secondary, size: 20),
                              tooltip: 'Add Teacher',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TeacherForm(),
                                  ),
                                ).then((_) => setState(() {}));
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text('Add Teacher',
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: teachers.length,
                    itemBuilder: (context, index) {
                      final teacher = teachers[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              Color(0xFFF8F9FA),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: Theme(
                            data: Theme.of(context)
                                .copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primary,
                                      Color(0xFFE67E22),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  teacher.fname[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              title: Text(
                                teacher.fullName,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                'Contact: ${teacher.contact}',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              iconColor: AppColors.primary,
                              collapsedIconColor:
                                  AppColors.primaryDark.withOpacity(0.7),
                              backgroundColor: Colors.transparent,
                              collapsedBackgroundColor: Colors.transparent,
                              children: [
                                if (teacher.classes == null ||
                                    teacher.classes!.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      'No classes assigned',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Assigned Classes & Subjects:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...teacher.classes!.map((classInfo) =>
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 8.0),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                        colors: [
                                                          AppColors.primary,
                                                          Color(0xFFE67E22),
                                                        ],
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: AppColors
                                                              .primary
                                                              .withOpacity(0.2),
                                                          blurRadius: 4,
                                                          offset: const Offset(
                                                              0, 2),
                                                          spreadRadius: 0,
                                                        ),
                                                      ],
                                                    ),
                                                    child: const Icon(
                                                      Icons.class_,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Class ${classInfo.className} - ${classInfo.subjectName} (${classInfo.medium})',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: AppColors
                                                            .textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ))
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
