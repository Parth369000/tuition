import 'package:flutter/material.dart';
import '../../../models/teacher.dart';
import '../../../models/teacher_class.dart';
import '../../../models/subject.dart';
import 'student_list_dialog.dart';

class AttendanceSection {
  // Static method to show only student list dialog
  static Future<void> showStudentListDialog(
    BuildContext context, {
    required Teacher teacher,
    required TeacherClass tClass,
    required Subject subject,
    required List<dynamic> students,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: StudentListDialog(
              teacher: teacher,
              tClass: tClass,
              subject: subject,
              students: students,
            ),
          ),
        );
      },
    );
  }
}
