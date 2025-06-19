class Attendance {
  final int id;
  final String date;
  final String status;
  final Student student;

  Attendance({
    required this.id,
    required this.date,
    required this.status,
    required this.student,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      date: json['date'],
      status: json['status'],
      student: Student.fromJson(json['Student']),
    );
  }
}

class Student {
  final int id;
  final String fname;
  final String lname;

  Student({
    required this.id,
    required this.fname,
    required this.lname,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      fname: json['fname'] ?? '',
      lname: json['lname'] ?? '',
    );
  }

  String get fullName => '$fname $lname';
}
