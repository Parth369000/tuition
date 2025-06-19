import 'teacher_class.dart';

class Teacher {
  final int id;
  final String fname;
  final String? mname;
  final String lname;
  final String contact;
  final int? userid;
  final DateTime createdAt;
  final DateTime updatedAt;
  List<TeacherClass>? classes;

  Teacher({
    required this.id,
    required this.fname,
    this.mname,
    required this.lname,
    required this.contact,
    this.userid,
    required this.createdAt,
    required this.updatedAt,
    this.classes,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'],
      fname: json['fname'],
      mname: json['mname'],
      lname: json['lname'],
      contact: json['contact'],
      userid: json['userid'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  String get fullName => '$fname ${mname ?? ''} $lname'.trim();
} 