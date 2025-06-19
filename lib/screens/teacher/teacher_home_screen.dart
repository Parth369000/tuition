// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../login_screen.dart';
// import '../../models/student.dart';
// import 'widgets/student_card.dart';
// import 'widgets/student_details_sheet.dart';
// import 'widgets/student_list_header.dart';
// import 'widgets/attendance_section.dart';
// import 'widgets/attendance_history_section.dart';
// import 'add_student.dart';
//
// class TeacherHomeScreen extends StatefulWidget {
//   const TeacherHomeScreen({Key? key}) : super(key: key);
//
//   @override
//   State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
// }
//
// class _TeacherHomeScreenState extends State<TeacherHomeScreen>
//     with SingleTickerProviderStateMixin {
//   List<Student> _students = [];
//   List<Student> _filteredStudents = [];
//   bool _isLoading = false;
//   String? _error;
//   final TextEditingController _searchController = TextEditingController();
//   String _selectedFilter = 'All';
//   late TabController _tabController;
//   Timer? _debounce;
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//     _loadStudents();
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     _debounce?.cancel();
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   void _filterStudents(String query) {
//     if (_debounce?.isActive ?? false) _debounce!.cancel();
//     _debounce = Timer(const Duration(milliseconds: 500), () {
//       setState(() {
//         if (query.isEmpty) {
//           _filteredStudents = _students;
//         } else {
//           _filteredStudents = _students.where((student) {
//             final searchLower = query.toLowerCase();
//             switch (_selectedFilter) {
//               case 'Name':
//                 return '${student.fname} ${student.lname}'
//                     .toLowerCase()
//                     .contains(searchLower);
//               case 'ID':
//                 return student.userid.toLowerCase().contains(searchLower);
//               case 'Class':
//                 return student.studentClass.toLowerCase().contains(searchLower);
//               case 'Batch':
//                 return student.batch.toLowerCase().contains(searchLower);
//               default:
//                 return '${student.fname} ${student.lname}'
//                         .toLowerCase()
//                         .contains(searchLower) ||
//                     student.userid.toLowerCase().contains(searchLower) ||
//                     student.studentClass.toLowerCase().contains(searchLower) ||
//                     student.batch.toLowerCase().contains(searchLower);
//             }
//           }).toList();
//         }
//       });
//     });
//   }
//
//   void _clearSearch() {
//     _searchController.clear();
//     setState(() {
//       _filteredStudents = _students;
//     });
//   }
//
//   void _onFilterChanged(String filter) {
//     setState(() {
//       _selectedFilter = filter;
//       if (_searchController.text.isNotEmpty) {
//         _filterStudents(_searchController.text);
//       }
//     });
//   }
//
//   Future<void> _loadStudents() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });
//
//     try {
//       final response = await http.post(
//         Uri.parse('http://27.116.52.24:8076/getAllStudents'),
//       );
//
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> data = json.decode(response.body);
//         final List<dynamic> studentsList = data['data'] ?? [];
//         setState(() {
//           _students =
//               studentsList.map((json) => Student.fromJson(json)).toList();
//           _filteredStudents = _students;
//           _isLoading = false;
//         });
//       } else {
//         setState(() {
//           _error = 'Failed to load students: ${response.reasonPhrase}';
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _error = 'Error loading students: $e';
//         _isLoading = false;
//       });
//     }
//   }
//
//   void _showStudentDetails(Student student) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => StudentDetailsSheet(
//         student: student,
//         onEdit: () {
//           // TODO: Implement edit
//         },
//         onDelete: () {
//           // TODO: Implement delete
//         },
//       ),
//     );
//   }
//
//   void _showAddStudentForm() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => const StudentFormWidget(),
//       ),
//     ).then((_) => _loadStudents()); // Refresh the list when returning
//   }
//
//   void _logout() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Logout'),
//         content: const Text('Are you sure you want to logout?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pushAndRemoveUntil(
//                 MaterialPageRoute(
//                   builder: (_) => const LoginScreen(),
//                 ),
//                 (route) => false,
//               );
//             },
//             child: const Text(
//               'Logout',
//               style: TextStyle(color: Colors.red),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Teacher Dashboard'),
//         backgroundColor: const Color(0xFF328ECC),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: _logout,
//             tooltip: 'Logout',
//           ),
//         ],
//         bottom: TabBar(
//           controller: _tabController,
//           labelColor: Colors.white,
//           unselectedLabelColor: Colors.white70,
//           indicatorColor: Colors.white,
//           tabs: const [
//             Tab(text: 'Students'),
//             Tab(text: 'Take Attendance'),
//             Tab(text: 'Attendance History'),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           // Students Tab
//           Scaffold(
//             body: Column(
//               children: [
//                 StudentListHeader(
//                   searchController: _searchController,
//                   onSearchChanged: _filterStudents,
//                   onClearSearch: _clearSearch,
//                   selectedFilter: _selectedFilter,
//                   onFilterChanged: _onFilterChanged,
//                 ),
//                 if (_isLoading)
//                   const Expanded(
//                     child: Center(child: CircularProgressIndicator()),
//                   )
//                 else if (_error != null)
//                   Expanded(
//                     child: Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             _error!,
//                             style: const TextStyle(color: Colors.red),
//                             textAlign: TextAlign.center,
//                           ),
//                           const SizedBox(height: 16),
//                           ElevatedButton(
//                             onPressed: _loadStudents,
//                             child: const Text('Retry'),
//                           ),
//                         ],
//                       ),
//                     ),
//                   )
//                 else if (_students.isEmpty)
//                   Expanded(
//                     child: Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(20),
//                             decoration: BoxDecoration(
//                               color: Colors.grey[100],
//                               shape: BoxShape.circle,
//                             ),
//                             child: const Icon(
//                               Icons.school_outlined,
//                               size: 40,
//                               color: Color(0xFF328ECC),
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           const Text(
//                             'No Students Found',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFF328ECC),
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           const Text(
//                             'Add new students to get started',
//                             style: TextStyle(
//                               color: Colors.grey,
//                               fontSize: 14,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   )
//                 else
//                   Expanded(
//                     child: ListView.builder(
//                       itemCount: _filteredStudents.length,
//                       padding: const EdgeInsets.all(16),
//                       itemBuilder: (context, index) {
//                         final student = _filteredStudents[index];
//                         return StudentCard(
//                           student: student,
//                           onTap: () => _showStudentDetails(student),
//                           onEdit: () {
//                             // TODO: Implement edit
//                           },
//                           onDelete: () {
//                             // TODO: Implement delete
//                           },
//                         );
//                       },
//                     ),
//                   ),
//               ],
//             ),
//             floatingActionButton: FloatingActionButton(
//               onPressed: _showAddStudentForm,
//               backgroundColor: const Color(0xFF328ECC),
//               child: const Icon(Icons.add),
//             ),
//           ),
//           // Take Attendance Tab
//           const AttendanceSection(),
//           // Attendance History Tab
//           const AttendanceHistorySection(),
//         ],
//       ),
//     );
//   }
// }
