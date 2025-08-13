import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tuition/screens/admin/admin_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tuition/core/themes/app_colors.dart';

class StudentDetailsSheet extends StatelessWidget {
  final dynamic student;

  const StudentDetailsSheet({
    Key? key,
    required this.student,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print(student);
    print(student['imageUrl']);
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Container(
        color: AppColors.scaffoldBackground,
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2A4759), // Your dark blue-gray
                      Color(0xFF1E3440), // Darker blue-gray
                      Color(0xFF152A35), // Deepest blue-gray
                    ],
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Student Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: () => _confirmAndDelete(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Color(0xFFF8F9FA),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Header with Enhanced Design
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                Color(0xFFF8F9FA),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.15),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primary,
                                      Color(0xFFE67E22),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: student['imageUrl'] != null &&
                                          student['imageUrl']
                                              .toString()
                                              .isNotEmpty
                                      ? Image.network(
                                          student['imageUrl'],
                                          width: 64,
                                          height: 64,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  _buildFallbackAvatar(student),
                                        )
                                      : _buildFallbackAvatar(student),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${student['fname']} ${student['mname'] ?? ''} ${student['lname']}',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            AppColors.primary,
                                            Color(0xFFE67E22),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withOpacity(0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        'ID: ${student['id']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Personal Information
                        _buildInfoSection(
                          'Personal Information',
                          Icons.person_outline,
                          [
                            _buildInfoRow('Birth Date',
                                student['bdate'] ?? 'Not provided'),
                            _buildInfoRow('Address',
                                student['address'] ?? 'Not provided'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Education Details
                        _buildInfoSection(
                          'Education Details',
                          Icons.school_outlined,
                          [
                            _buildInfoRow('Class', 'Class ${student['class']}'),
                            _buildInfoRow(
                                'Board', student['board'] ?? 'Not provided'),
                            _buildInfoRow(
                                'School', student['school'] ?? 'Not provided'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Contact Information
                        _buildInfoSection(
                          'Contact Information',
                          Icons.phone_outlined,
                          [
                            _buildInfoRow('Student Contact',
                                student['contact'] ?? 'Not provided'),
                            _buildInfoRow('Parent Contact',
                                student['parentContact'] ?? 'Not provided'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Fee Information with Enhanced Design
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                Color(0xFFF8F9FA),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.primary,
                                          Color(0xFFE67E22),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.payments_outlined,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Fee Information',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildFeeRow(
                                'Fee Paid',
                                '₹${student['feePaid'] ?? '0'}',
                                Icons.check_circle_outline,
                                Colors.green,
                              ),
                              const SizedBox(height: 12),
                              _buildFeeRow(
                                'Total Fee',
                                '₹${student['feeTotal'] ?? '0'}',
                                Icons.account_balance_wallet_outlined,
                                AppColors.primary,
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete student?'),
          content: const Text('This will permanently delete this student.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    String? errorMessage;
    try {
      // Try to include token if available
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final dynamic rawId = student['id'];
      final int? id =
          rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

      // 1) Load StudentSubject rows and print matches for this studentId
      try {
        final getDataResp = await http
            .post(
              Uri.parse('http://27.116.52.24:8076/getData'),
              headers: headers,
              body: jsonEncode({'table': 'StudentSubject'}),
            )
            .timeout(const Duration(seconds: 25));

        if (getDataResp.statusCode == 200) {
          try {
            final gd = jsonDecode(getDataResp.body);
            if (gd is Map && gd['errorStatus'] == false) {
              final List<dynamic> all = (gd['data'] as List?) ?? <dynamic>[];
              final int? targetId =
                  id ?? int.tryParse(student['id']?.toString() ?? '');
              final matches = all.where((e) {
                final sidRaw = (e as Map)['studentId'];
                final sid = sidRaw is int
                    ? sidRaw
                    : int.tryParse(sidRaw?.toString() ?? '');
                return targetId != null && sid == targetId;
              }).toList();
              print(
                  'StudentSubject matches for studentId ${targetId ?? student['id']}: ');
              print(matches);

              // 2) Delete each StudentSubject row for this student
              for (final item in matches) {
                try {
                  final map = Map<String, dynamic>.from(item as Map);
                  final dynamic rowIdRaw = map['id'];
                  final int? rowId = rowIdRaw is int
                      ? rowIdRaw
                      : int.tryParse(rowIdRaw?.toString() ?? '');
                  if (rowId == null) continue;

                  final delBody = jsonEncode({
                    'table': 'StudentSubject',
                    'id': rowId,
                  });

                  final delResp = await http
                      .post(
                        Uri.parse('http://27.116.52.24:8076/deleteData'),
                        headers: headers,
                        body: delBody,
                      )
                      .timeout(const Duration(seconds: 20));

                  if (delResp.statusCode == 200) {
                    try {
                      final delData = jsonDecode(delResp.body);
                      if (delData is Map && delData['errorStatus'] == true) {
                        print(
                            'Failed to delete StudentSubject id=$rowId: ${delResp.body}');
                      } else {
                        print('Deleted StudentSubject id=$rowId');
                      }
                    } catch (_) {
                      final lower = delResp.body.toLowerCase();
                      if (!lower.contains('success')) {
                        print(
                            'Unexpected delete StudentSubject response for id=$rowId: ${delResp.body}');
                      } else {
                        print('Deleted StudentSubject id=$rowId');
                      }
                    }
                  } else {
                    print(
                        'HTTP ${delResp.statusCode} deleting StudentSubject id=$rowId: ${delResp.reasonPhrase}');
                  }
                } catch (e) {
                  print('Error deleting StudentSubject row: $e');
                }
              }
            } else {
              print(
                  'getData StudentSubject error or unexpected format: ${getDataResp.body}');
            }
          } catch (e) {
            print(
                'Error parsing StudentSubject getData response: $e | ${getDataResp.body}');
          }
        } else {
          print(
              'Failed to load StudentSubject (code ${getDataResp.statusCode}): ${getDataResp.reasonPhrase}');
        }
      } catch (e) {
        print('Network error while loading StudentSubject: $e');
      }

      // 3) Delete the Student row itself
      final body = jsonEncode({
        'table': 'Student',
        'id': id ?? student['id'],
      });
      final response = await http
          .post(
            Uri.parse('http://27.116.52.24:8076/deleteData'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 20));

      Navigator.of(context).pop(); // close loader

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          final bool failed = (data is Map &&
              ((data['errorStatus'] == true) || (data['success'] == false)));
          if (!failed) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
              (route) => false,
            );
            return;
          }
          print('Delete failed by server. ${data.toString()}');
          errorMessage = (data is Map && data['message'] != null)
              ? data['message'].toString()
              : 'Delete failed by server.';
        } catch (_) {
          // If body is not JSON, assume success only if server explicitly returns keyword
          final lower = response.body.toLowerCase();
          if (lower.contains('success')) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
              (route) => false,
            );
            return;
          }
          errorMessage = 'Unexpected response: ${response.body}';
        }
      } else {
        errorMessage =
            'Failed to delete (code ${response.statusCode}). ${response.reasonPhrase ?? ''}';
      }
    } catch (e) {
      Navigator.of(context).pop(); // close loader
      errorMessage = 'Error: $e';
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF8F9FA),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      Color(0xFFE67E22),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Color(0xFFF8F9FA),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1.2,
                ),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF8F9FA),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildFallbackAvatar(dynamic student) {
  return Container(
    width: 64,
    height: 64,
    alignment: Alignment.center,
    color: Colors.transparent,
    child: Text(
      student['fname']?[0]?.toString().toUpperCase() ?? '?',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
