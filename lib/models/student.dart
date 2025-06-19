class Student {
  final int id;
  final String name;
  final String userid;
  final String password;
  final String studentClass;
  final String batch;
  final String fname;
  final String mname;
  final String lname;
  final String contact;
  final String parentContact;
  final String school;
  final String board;
  final String medium;
  final String address;
  final String bdate;
  final String feePaid;
  final String feeTotal;
  final String? image;

  Student({
    required this.id,
    required this.name,
    required this.userid,
    required this.password,
    required this.studentClass,
    required this.batch,
    required this.fname,
    required this.mname,
    required this.lname,
    required this.contact,
    required this.parentContact,
    required this.school,
    required this.board,
    required this.medium,
    required this.address,
    required this.bdate,
    required this.feePaid,
    required this.feeTotal,
    this.image,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      userid: json['userid'] ?? '',
      password: json['password'] ?? '',
      studentClass: json['class']?.toString() ?? '',
      batch: json['batch'] ?? '',
      fname: json['fname']?.toString() ?? '',
      mname: json['mname']?.toString() ?? '',
      lname: json['lname']?.toString() ?? '',
      contact: json['contact']?.toString() ?? '',
      parentContact: json['parentContact']?.toString() ?? '',
      school: json['school']?.toString() ?? '',
      board: json['board']?.toString() ?? '',
      medium: json['medium']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      bdate: json['bdate']?.toString() ?? '',
      feePaid: json['feePaid']?.toString() ?? '',
      feeTotal: json['feeTotal']?.toString() ?? '',
      image: json['image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'userid': userid,
      'password': password,
      'class': studentClass,
      'batch': batch,
      'fname': fname,
      'mname': mname,
      'lname': lname,
      'contact': contact,
      'parentContact': parentContact,
      'school': school,
      'board': board,
      'medium': medium,
      'address': address,
      'bdate': bdate,
      'feePaid': feePaid,
      'feeTotal': feeTotal,
      'image': image,
    };
  }
}
