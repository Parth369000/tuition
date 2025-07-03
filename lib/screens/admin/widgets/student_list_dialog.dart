import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/teacher.dart';
import '../../../models/teacher_class.dart';
import '../../../models/subject.dart';

class StudentListDialog extends StatefulWidget {
  final Teacher teacher;
  final TeacherClass tClass;
  final Subject subject;
  final List<dynamic> students;

  const StudentListDialog({
    Key? key,
    required this.teacher,
    required this.tClass,
    required this.subject,
    required this.students,
  }) : super(key: key);

  @override
  _StudentListDialogState createState() => _StudentListDialogState();
}

class _StudentListDialogState extends State<StudentListDialog> {
  Map<int, bool> attendance = {};
  bool isSubmitting = false;
  bool isCheckingAttendance = false;
  bool attendanceAlreadyTaken = false;
  DateTime selectedDate = DateTime.now();
  String? error;

  @override
  void initState() {
    super.initState();
    // Initialize attendance map with all students as present
    attendance = {for (var student in widget.students) student['id']: true};
    // Check if attendance has already been taken
    _checkAttendanceStatus();
  }

  Future<void> _checkAttendanceStatus() async {
    setState(() {
      isCheckingAttendance = true;
    });

    try {
      var headers = {'Content-Type': 'application/json'};

      var request = http.Request(
          'POST', Uri.parse('http://27.116.52.24:8076/getAttendance'));
      request.body = json.encode({
        "teacherId": widget.teacher.id,
        "class": widget.tClass.className,
        "subjectId": widget.subject.id,
        "medium": widget.tClass.medium,
        "date": selectedDate.toIso8601String().split('T')[0],
      });
      request.headers.addAll(headers);

      print(
          'Checking attendance status with request: ${json.encode(request.body)}');

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);

        print('GetAttendance API response: $data');

        // Check if attendance data exists for today
        bool attendanceTaken = false;

        if (data is Map<String, dynamic>) {
          if (data.containsKey('errorStatus')) {
            // If errorStatus is false, it means attendance data was found
            attendanceTaken = data['errorStatus'] == false;
          } else if (data.containsKey('data')) {
            // If data field exists and is not empty, attendance was taken
            final responseData = data['data'];
            if (responseData != null &&
                responseData is List &&
                responseData.isNotEmpty) {
              attendanceTaken = true;
            } else if (responseData != null &&
                responseData is Map &&
                responseData.isNotEmpty) {
              attendanceTaken = true;
            }
          } else if (data.containsKey('message')) {
            // Check if the message indicates attendance exists
            final message = data['message'].toString().toLowerCase();
            attendanceTaken = !message.contains('not found') &&
                !message.contains('no data') &&
                !message.contains('empty');
          }
        }

        setState(() {
          attendanceAlreadyTaken = attendanceTaken;
        });

        print(
            'Attendance status determined: ${attendanceTaken ? "Already taken" : "Not taken yet"}');
      } else {
        print('Failed to check attendance status: ${response.reasonPhrase}');
        setState(() {
          attendanceAlreadyTaken = false; // Assume not taken if check fails
        });
      }
    } catch (e) {
      print('Error checking attendance status: $e');
      setState(() {
        attendanceAlreadyTaken = false; // Assume not taken if check fails
      });
    } finally {
      setState(() {
        isCheckingAttendance = false;
      });
    }
  }

  Future<void> _submitAttendance() async {
    // Check if attendance has already been taken for today
    if (attendanceAlreadyTaken) {
      _showSnackBar(
          'Attendance has already been taken for this class, subject, and date!',
          isError: true);
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    // Debug print final attendance state before submission
    print('Final attendance state before submission:');
    print('Total students: ${widget.students.length}');
    print('Attendance map: $attendance');
    print('Present count: ${attendance.values.where((v) => v).length}');
    print('Absent count: ${attendance.values.where((v) => !v).length}');

    try {
      int successCount = 0;
      int errorCount = 0;
      List<String> errors = [];

      for (final entry in attendance.entries) {
        final studentId = entry.key;
        final isPresent = entry.value;

        // Debug print to verify data
        print(
            'Submitting attendance for student $studentId: ${isPresent ? "present" : "absent"}');

        final request = http.Request(
          'POST',
          Uri.parse('http://27.116.52.24:8076/markAttendance'),
        );

        request.headers.addAll({
          'Content-Type': 'application/json',
        });

        final requestBody = {
          "teacherId": widget.teacher.id,
          "studentId": studentId,
          "status": isPresent ? "present" : "absent",
          "date": selectedDate.toIso8601String().split('T')[0],
          "subjectId": widget.subject.id,
          "medium": widget.tClass.medium,
        };

        // Debug print request body
        print('Request body: ${json.encode(requestBody)}');

        request.body = json.encode(requestBody);

        try {
          final streamedResponse = await request.send();
          final response = await http.Response.fromStream(streamedResponse);

          print('Response status: ${response.statusCode}');
          print('Response body: ${response.body}');

          if (response.statusCode == 200) {
            final responseData = json.decode(response.body);
            if (responseData['errorStatus'] == true) {
              // Check for specific error message about already marked attendance
              if (responseData['message']
                  .toString()
                  .contains('Attendance for this student is already marked')) {
                print(
                    'Attendance already marked for student $studentId for this date.');
                successCount++; // Consider this a success since attendance was already marked
              } else {
                errorCount++;
                errors.add('Student $studentId: ${responseData['message']}');
                print(
                    'Error for student $studentId: ${responseData['message']}');
              }
            } else {
              successCount++;
              print('Successfully submitted attendance for student $studentId');
            }
          } else {
            errorCount++;
            final errorMsg =
                'Student $studentId: HTTP ${response.statusCode} - ${response.reasonPhrase}';
            errors.add(errorMsg);
            print(errorMsg);
          }
        } catch (e) {
          errorCount++;
          final errorMsg = 'Student $studentId: Network error - $e';
          errors.add(errorMsg);
          print('Error is ' + errorMsg);
        }
      }

      // Show summary message
      if (errorCount == 0) {
        _showSnackBar(
            'Attendance submitted successfully for all $successCount students!');
        // Close the dialog after successful submission
        Navigator.of(context).pop();
      } else if (successCount > 0) {
        _showSnackBar(
            'Attendance submitted for $successCount students. $errorCount errors occurred.',
            isError: true);
        // Show detailed errors in console for debugging
        print('Detailed errors:');
        for (String error in errors) {
          print('- $error');
        }
      } else {
        _showSnackBar(
            'Failed to submit attendance for any students. Please try again.',
            isError: true);
        print('All submissions failed. Errors:');
        for (String error in errors) {
          print('- $error');
        }
      }
    } catch (e) {
      _showSnackBar('Error submitting attendance: $e', isError: true);
      print('General error in _submitAttendance: $e');
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = attendance.values.where((v) => v).length;
    final absentCount = attendance.length - presentCount;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Enhanced Header Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Enhanced Icon Container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.1)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attendance Marking',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${widget.teacher.fullName} • ${widget.tClass.className} (${widget.tClass.medium}) • ${widget.subject.name}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Enhanced Close Button
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  ],
                ),

                // Enhanced Attendance Status Indicator
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: attendanceAlreadyTaken
                          ? [
                              Colors.orange.withOpacity(0.3),
                              Colors.red.withOpacity(0.2)
                            ]
                          : [
                              Colors.green.withOpacity(0.3),
                              Colors.teal.withOpacity(0.2)
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: attendanceAlreadyTaken
                          ? Colors.orange.withOpacity(0.5)
                          : Colors.green.withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (attendanceAlreadyTaken
                                ? Colors.orange
                                : Colors.green)
                            .withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (isCheckingAttendance)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            attendanceAlreadyTaken
                                ? Icons.warning_amber
                                : Icons.check_circle,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          attendanceAlreadyTaken
                              ? 'Attendance already taken for today'
                              : 'Ready to take attendance',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Enhanced Student List Section
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Enhanced Quick Actions
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: attendanceAlreadyTaken
                                    ? null
                                    : () {
                                        setState(() {
                                          for (var id in attendance.keys) {
                                            attendance[id] = true;
                                          }
                                          print(
                                              'All Present pressed. Updated attendance map: $attendance');
                                        });
                                      },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.done_all,
                                          color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'All Present',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF44336), Color(0xFFD32F2F)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: attendanceAlreadyTaken
                                    ? null
                                    : () {
                                        setState(() {
                                          for (var id in attendance.keys) {
                                            attendance[id] = false;
                                          }
                                          print(
                                              'All Absent pressed. Updated attendance map: $attendance');
                                        });
                                      },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.remove_circle_outline,
                                          color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'All Absent',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Enhanced Summary
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE8F5E8), Color(0xFFF1F8E9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.green.withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.check_circle,
                                      color: Colors.white, size: 14),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Present: $presentCount',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFEBEE), Color(0xFFFFF3E0)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.red.withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.cancel,
                                      color: Colors.white, size: 14),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Absent: $absentCount',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Enhanced Students List
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: widget.students.length,
                          itemBuilder: (context, index) {
                            final student = widget.students[index];
                            final studentId = student['id'];
                            final studentName =
                                '${student['fname']} ${student['lname']}';
                            final isPresent = attendance[studentId] ?? false;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isPresent
                                      ? [Colors.white, Color(0xFFF8FFF8)]
                                      : [Colors.white, Color(0xFFFFF8F8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isPresent
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (isPresent ? Colors.green : Colors.grey)
                                            .withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isPresent
                                          ? [Colors.green, Color(0xFF4CAF50)]
                                          : [Colors.grey, Color(0xFF757575)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isPresent
                                                ? Colors.green
                                                : Colors.grey)
                                            .withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.white,
                                    child: Text(
                                      studentName.isNotEmpty
                                          ? studentName[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: isPresent
                                            ? Colors.green
                                            : Colors.grey,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  studentName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'ID: ${student['id']}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isPresent
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isPresent
                                              ? Colors.green.withOpacity(0.3)
                                              : Colors.red.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        isPresent ? 'Present' : 'Absent',
                                        style: TextStyle(
                                          color: isPresent
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isPresent
                                              ? [
                                                  Colors.green,
                                                  Color(0xFF4CAF50)
                                                ]
                                              : [Colors.red, Color(0xFFF44336)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isPresent
                                                    ? Colors.green
                                                    : Colors.red)
                                                .withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Switch(
                                        value: isPresent,
                                        onChanged: attendanceAlreadyTaken
                                            ? null
                                            : (value) {
                                                setState(() {
                                                  attendance[studentId] = value;
                                                  print(
                                                      'Attendance changed for student $studentId: ${value ? "present" : "absent"}');
                                                  print(
                                                      'Current attendance map: $attendance');
                                                });
                                              },
                                        activeColor: Colors.white,
                                        inactiveThumbColor: Colors.white,
                                        inactiveTrackColor: Colors.grey[300],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Enhanced Action Buttons
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF757575), Color(0xFF616161)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.of(context).pop(),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.close,
                                          color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: attendanceAlreadyTaken
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFFBDBDBD),
                                        Color(0xFF9E9E9E)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFF667eea),
                                        Color(0xFF764ba2)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: (attendanceAlreadyTaken
                                          ? Colors.grey
                                          : const Color(0xFF667eea))
                                      .withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: (isSubmitting || attendanceAlreadyTaken)
                                    ? null
                                    : _submitAttendance,
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: isSubmitting
                                      ? const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Submitting...',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              attendanceAlreadyTaken
                                                  ? Icons.check_circle
                                                  : Icons.send,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              attendanceAlreadyTaken
                                                  ? 'Already Taken'
                                                  : 'Submit',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
