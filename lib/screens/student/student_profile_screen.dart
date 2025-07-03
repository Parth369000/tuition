import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tuition/core/themes/app_colors.dart';
import 'package:intl/intl.dart';
import '../../widgets/liquid_glass_painter.dart';

class StudentProfileScreen extends StatelessWidget {
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? student;
  final List<dynamic>? enrolledSubjects;

  const StudentProfileScreen({
    super.key,
    this.user,
    this.student,
    this.enrolledSubjects,
  });

  @override
  Widget build(BuildContext context) {
    // Use actual data or fallback to defaults
    final studentData = student ?? {};
    final userData = user ?? {};
    final subjects = enrolledSubjects ?? [];

    // Format the full name
    final fullName =
        '${studentData['fname'] ?? ''} ${studentData['mname'] ?? ''} ${studentData['lname'] ?? ''}'
            .trim();
    final displayName = fullName.isNotEmpty ? fullName : 'Student';

    // Get initials for avatar
    final initials = fullName.isNotEmpty
        ? fullName
            .split(' ')
            .map((name) => name.isNotEmpty ? name[0] : '')
            .join('')
            .toUpperCase()
        : 'S';

    // Format birth date
    String formattedBirthDate = 'Not available';
    if (studentData['bdate'] != null) {
      try {
        final date = DateTime.parse(studentData['bdate']);
        formattedBirthDate = DateFormat('dd MMMM yyyy').format(date);
      } catch (e) {
        formattedBirthDate = studentData['bdate'].toString();
      }
    }

    // Format created/updated date
    String formattedUpdatedDate = 'Not available';
    if (studentData['updatedAt'] != null) {
      try {
        final date = DateTime.parse(studentData['updatedAt']);
        formattedUpdatedDate = DateFormat('dd MMMM yyyy').format(date);
      } catch (e) {
        formattedUpdatedDate = studentData['updatedAt'].toString();
      }
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2A4759),
              Color(0xFF1E3440),
              Color(0xFF152A35),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 24,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppColors.secondary.withOpacity(0.10),
                                    blurRadius: 16,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: studentData['id'] != null
                                  ? ClipOval(
                                      child: Image.network(
                                        'http://27.116.52.24:8076/uploads/students/student_${studentData['id']}',
                                        fit: BoxFit.cover,
                                        width: 80,
                                        height: 80,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Icon(Icons.person,
                                              size: 54,
                                              color: AppColors.secondary);
                                        },
                                      ),
                                    )
                                  : Icon(Icons.person,
                                      size: 54, color: AppColors.secondary),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppColors.secondary.withOpacity(0.18),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                userData['role']?.toString().toUpperCase() ??
                                    'STUDENT',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Personal Information
                      Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.scaffoldBackground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailCard([
                        _buildDetailItem(
                          Icons.numbers,
                          'Student ID',
                          studentData['id']?.toString() ?? 'Not available',
                        ),
                        _buildDetailItem(
                          Icons.person,
                          'User ID',
                          userData['id']?.toString() ?? 'Not available',
                        ),
                        _buildDetailItem(
                          Icons.phone,
                          'Contact Number',
                          studentData['contact']?.toString() ?? 'Not available',
                        ),
                        _buildDetailItem(
                          Icons.phone,
                          'Parent Contact',
                          studentData['parentContact']?.toString() ??
                              'Not available',
                        ),
                        _buildDetailItem(
                          Icons.calendar_today,
                          'Birth Date',
                          formattedBirthDate,
                        ),
                        _buildDetailItem(
                          Icons.location_on,
                          'Address',
                          studentData['address']?.toString() ?? 'Not available',
                        ),
                      ]),
                      const SizedBox(height: 24),
                      // Academic Information
                      Text(
                        'Academic Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.scaffoldBackground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailCard([
                        _buildDetailItem(
                          Icons.school,
                          'Board',
                          studentData['board']?.toString() ?? 'Not available',
                        ),
                        _buildDetailItem(
                          Icons.business,
                          'School',
                          studentData['school']?.toString() ?? 'Not available',
                        ),
                        _buildDetailItem(
                          Icons.language,
                          'Medium',
                          studentData['medium']?.toString() ?? 'Not available',
                        ),
                        _buildDetailItem(
                          Icons.class_,
                          'Class',
                          studentData['class']?.toString() ?? 'Not available',
                        ),
                        _buildDetailItem(
                          Icons.groups,
                          'Batch',
                          studentData['batch']?.toString() ?? 'Not available',
                        ),
                      ]),
                      const SizedBox(height: 24),
                      // Enrolled Subjects
                      if (subjects.isNotEmpty) ...[
                        Text(
                          'Enrolled Subjects',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.scaffoldBackground,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailCard([
                          ...subjects
                              .map((subject) => _buildDetailItem(
                                    Icons.book,
                                    'Subject',
                                    subject['subjectName']?.toString() ??
                                        'Unknown',
                                  ))
                              .toList(),
                        ]),
                        const SizedBox(height: 24),
                      ],
                      // Fee Information
                      Text(
                        'Fee Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.scaffoldBackground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailCard([
                        _buildDetailItem(
                          Icons.payments,
                          'Total Fee',
                          studentData['feeTotal'] != null
                              ? '₹${NumberFormat('#,##0').format(int.tryParse(studentData['feeTotal'].toString()) ?? 0)}'
                              : 'Not available',
                        ),
                      ]),
                      const SizedBox(height: 24),
                      // Account Information
                      Text(
                        'Account Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.scaffoldBackground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailCard([
                        _buildDetailItem(
                          Icons.person,
                          'Role',
                          userData['role']?.toString().toUpperCase() ??
                              'STUDENT',
                        ),
                        _buildDetailItem(
                          Icons.update,
                          'Last Updated',
                          formattedUpdatedDate,
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.secondary.withOpacity(0.13), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.06),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}
