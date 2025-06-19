class TeacherSubject {
  final int id;
  final int teacherId;
  final int subjectId;
  final String subjectName;
  final String className;

  TeacherSubject({
    required this.id,
    required this.teacherId,
    required this.subjectId,
    required this.subjectName,
    required this.className,
  });

  factory TeacherSubject.fromJson(Map<String, dynamic> json) {
    return TeacherSubject(
      id: json['id'],
      teacherId: json['teacherId'],
      subjectId: json['subjectId'],
      subjectName: json['subjectName'] ?? '',
      className: json['className'] ?? '',
    );
  }
} 