class TeacherClass {
  final String className;
  final int subjectId;
  final String subjectName;
  final String medium;

  TeacherClass({
    required this.className,
    required this.subjectId,
    required this.subjectName,
    required this.medium,
  });

  factory TeacherClass.fromJson(Map<String, dynamic> json) {
    return TeacherClass(
      className: json['class']?.toString() ?? '',
      subjectId: json['subjectId'] ?? 0,
      subjectName: json['subjectName']?.toString() ?? '',
      medium: json['medium']?.toString() ?? '',
    );
  }
}
