import 'package:flutter/material.dart';
import 'package:tuition/core/themes/app_colors.dart';

class StudentCard extends StatelessWidget {
  final dynamic student;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const StudentCard({
    Key? key,
    required this.student,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  student['fname']?[0]?.toString().toUpperCase() ?? '?',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${student['fname']} ${student['lname']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ID: ${student['id']}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.class_,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Class ${student['class']}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.groups,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Batch ${student['batch']}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // PopupMenuButton<String>(
              //   icon: Icon(
              //     Icons.more_vert,
              //     color: AppColors.textSecondary,
              //   ),
              //   onSelected: (value) {
              //     switch (value) {
              //       case 'edit':
              //         onEdit();
              //         break;
              //       case 'delete':
              //         onDelete();
              //         break;
              //     }
              //   },
              //   itemBuilder: (context) => [
              //     const PopupMenuItem(
              //       value: 'edit',
              //       child: Row(
              //         children: [
              //           Icon(Icons.edit),
              //           SizedBox(width: 8),
              //           Text('Edit'),
              //         ],
              //       ),
              //     ),
              //     const PopupMenuItem(
              //       value: 'delete',
              //       child: Row(
              //         children: [
              //           Icon(Icons.delete, color: Colors.red),
              //           SizedBox(width: 8),
              //           Text('Delete', style: TextStyle(color: Colors.red)),
              //         ],
              //       ),
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
