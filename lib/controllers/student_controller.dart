import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';
import '../screens/admin/admin_home_screen.dart';
import '../services/student_service.dart';
import '../models/student.dart';

class StudentController extends ChangeNotifier {
  final StudentService _studentService = StudentService();
  final GlobalKey<ScaffoldMessengerState> scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // State
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  File? _studentImage;
  File? get studentImage => _studentImage;
  int _currentStep = 0;
  int get currentStep => _currentStep;
  String? _error;
  bool get isError => _error != null;
  String? get error => _error;

  // Student list state
  List<Student> _students = [];
  List<Student> get students => _students;
  Map<String, List<Student>> _groupedStudents = {};
  Map<String, List<Student>> get groupedStudents => _groupedStudents;

  // Form controllers
  final studentClassController = TextEditingController();
  final batchController = TextEditingController();
  final feePaidController = TextEditingController();
  final feeTotalController = TextEditingController();
  final birthdateController = TextEditingController();
  final addressController = TextEditingController();
  final boardController = TextEditingController();
  final schoolController = TextEditingController();
  final fnameController = TextEditingController();
  final mnameController = TextEditingController();
  final lnameController = TextEditingController();
  final mediumController = TextEditingController();
  final contactController = TextEditingController();
  final parentContactController = TextEditingController();

  // Selected subjects - initialized as empty list
  final List<int> selectedSubjects = [];

  StudentController() {
    // Initialize any other required setup
  }

  // Image handling
  void setImage(File? image) {
    _studentImage = image;
    notifyListeners();
  }

  // Step navigation
  void nextStep() {
    if (_currentStep < 2) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  // Form submission
  Future<void> submitForm() async {
    print('Selected subjects: ${selectedSubjects.toList()}');
    if (selectedSubjects.isEmpty) {
      showSnackBar('Please select at least one subject', isError: true);
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      var headers = {'Content-Type': 'application/json'};
      var request = http.Request(
          'POST', Uri.parse('http://27.116.52.24:8076/addStudent'));
      request.body = json.encode({
        "studentClass": studentClassController.text,
        "batch": "Star",
        "feePaid": int.parse(feePaidController.text),
        "feeTotal": int.parse(feeTotalController.text),
        "bdate": birthdateController.text.split('/').reversed.join('-'),
        "address": addressController.text,
        "board": boardController.text,
        "school": schoolController.text,
        "fname": fnameController.text,
        "mname": mnameController.text,
        "lname": lnameController.text,
        "medium": mediumController.text,
        "contact": contactController.text.isEmpty ? "" : contactController.text,
        "parentContact": parentContactController.text,
        "subjectIds": selectedSubjects.toList(),
      });
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final responseData = json.decode(responseBody);
        // Success logic here (e.g., reset form, show snackbar, navigate)
        resetForm();
        if (scaffoldKey.currentContext != null) {
          ScaffoldMessenger.of(scaffoldKey.currentContext!).showSnackBar(
            SnackBar(
              content: Text(responseData['data']['message'] ?? 'Student added successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          Navigator.pushAndRemoveUntil(
            scaffoldKey.currentContext!,
            MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
            (route) => false,
          );
        }
      } else {
        // Handle error
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding student: $e');
      _error = e.toString();
      if (scaffoldKey.currentContext != null) {
        ScaffoldMessenger.of(scaffoldKey.currentContext!).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Form clearing
  void resetForm() {
    studentClassController.clear();
    feePaidController.clear();
    feeTotalController.clear();
    birthdateController.clear();
    addressController.clear();
    boardController.clear();
    schoolController.clear();
    fnameController.clear();
    mnameController.clear();
    lnameController.clear();
    mediumController.clear();
    contactController.clear();
    parentContactController.clear();
    selectedSubjects.clear();
    _studentImage = null;
    _currentStep = 0;
    notifyListeners();
  }

  // Student fetching
  Future<void> fetchStudents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _students = await _studentService.getAllStudents();
      _groupStudents();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Student grouping
  void _groupStudents() {
    _groupedStudents.clear();
    Map<String, Map<String, List<Student>>> tempGroups = {};

    for (var student in _students) {
      if (!tempGroups.containsKey(student.studentClass)) {
        tempGroups[student.studentClass] = {};
      }

      if (!tempGroups[student.studentClass]!.containsKey(student.batch)) {
        tempGroups[student.studentClass]![student.batch] = [];
      }

      tempGroups[student.studentClass]![student.batch]!.add(student);
    }

    for (var classEntry in tempGroups.entries) {
      String classKey = classEntry.key;
      Map<String, List<Student>> batches = classEntry.value;

      for (var batchEntry in batches.entries) {
        String batchKey = batchEntry.key;
        List<Student> batchStudents = batchEntry.value;
        _groupedStudents['${classKey}${batchKey}'] = batchStudents;
      }
    }

    _groupedStudents = Map.fromEntries(_groupedStudents.entries.toList()
      ..sort((a, b) {
        String aClass = a.key.replaceAll(RegExp(r'[^0-9]'), '');
        String bClass = b.key.replaceAll(RegExp(r'[^0-9]'), '');
        String aBatch = a.key.replaceAll(RegExp(r'[0-9]'), '');
        String bBatch = b.key.replaceAll(RegExp(r'[0-9]'), '');

        int classCompare = int.parse(bClass).compareTo(int.parse(aClass));
        if (classCompare != 0) return classCompare;
        return aBatch.compareTo(bBatch);
      }));
  }

  // UI Helpers
  void showSnackBar(String message, {bool isError = false}) {
    scaffoldKey.currentState?.showSnackBar(
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
  void dispose() {
    studentClassController.dispose();
    feePaidController.dispose();
    feeTotalController.dispose();
    birthdateController.dispose();
    addressController.dispose();
    boardController.dispose();
    schoolController.dispose();
    fnameController.dispose();
    mnameController.dispose();
    lnameController.dispose();
    mediumController.dispose();
    contactController.dispose();
    parentContactController.dispose();
    super.dispose();
  }
}
